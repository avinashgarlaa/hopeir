// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../data/models/ride_request_model.dart';
import '../../domain/entities/ride_request.dart';

// ✅ IMPORTANT: passenger ride ws controller
import 'passanger_ride_ws_controller.dart';

final rideRequestWSControllerProvider = StateNotifierProvider.family<
    RideRequestWSController, RideRequestWSState, String>((ref, userId) {
  return RideRequestWSController(ref, userId);
});

class RideRequestWSController extends StateNotifier<RideRequestWSState> {
  final Ref ref;
  final String userId;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  Timer? _reconnectTimer;
  bool _isDisposed = false;
  bool _isConnecting = false;

  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 7;

  // ✅ track which ride sockets we already triggered
  final Set<int> _connectedRideSockets = {};

  RideRequestWSController(this.ref, this.userId)
      : super(RideRequestWSState.initial()) {
    Future.microtask(() => _connectSafely());
  }

  // ======================================================
  // LOG HELPERS (BEST LOGGING)
  // ======================================================
  void _log(String msg) => print("[RideReqWS][$userId] $msg");

  void _logError(String msg, [Object? e, StackTrace? st]) {
    _log("❌ $msg ${e != null ? "-> $e" : ""}");
    if (st != null) {
      _log("STACKTRACE:\n$st");
    }
  }

  // ======================================================
  // CONNECT
  // ======================================================
  Uri _buildWsUri() {
    return Uri(
      scheme: "wss",
      host: "hopeir.onrender.com",
      path: "/ws/ride-requests/",
      queryParameters: {"user_id": userId},
    );
  }

  Future<void> _connectSafely() async {
    if (_isDisposed) return;
    if (_isConnecting) return;

    _isConnecting = true;

    final uri = _buildWsUri();
    _log("🔌 Connecting → $uri");

    state = state.copyWith(
      status: _reconnectAttempts > 0
          ? ConnectionStatus.reconnecting
          : ConnectionStatus.connecting,
    );

    try {
      // cleanup old
      await _subscription?.cancel();
      _subscription = null;

      try {
        _channel?.sink.close(status.normalClosure);
      } catch (_) {}
      _channel = null;

      // connect
      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        _handleMessageSafely,
        onDone: _handleDisconnectSafely,
        onError: (error) {
          _logError("WS stream error", error is Object ? error : null);
          _handleDisconnectSafely();
        },
        cancelOnError: true,
      );

      state = state.copyWith(status: ConnectionStatus.connected, error: null);

      _reconnectAttempts = 0;
      _log("✅ Connected");
    } catch (e, st) {
      _logError("Connection failed", e, st);
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  // ======================================================
  // MESSAGE HANDLER
  // ======================================================
  void _handleMessageSafely(dynamic message) {
    if (_isDisposed) return;

    final msgString = message?.toString() ?? "";

    // don't spam massive payload
    _log("📩 Message received (${msgString.length} chars)");

    Map<String, dynamic>? decoded;

    try {
      final raw = jsonDecode(msgString);

      if (raw is! Map) {
        _log("⚠️ Ignored: json is not an object/map");
        return;
      }

      decoded = raw.cast<String, dynamic>();
    } catch (e) {
      // backend may send non-json frames sometimes
      _log("⚠️ Ignored: non-json message");
      return;
    }

    final type = decoded['type']?.toString();
    final data = decoded['data'];

    if (type == null) {
      _log("⚠️ Missing 'type' in message");
      return;
    }

    switch (type) {
      case 'initial_state':
        _handleInitialStateSafely(data);
        break;

      case 'ride_request_updated':
        _handleRequestUpdatedSafely(data);
        break;

      default:
        _log("⚠️ Unknown type → $type");
    }
  }

  // ======================================================
  // LOCAL INSERT (HTTP → WS BRIDGE)
  // ======================================================
  void addMyRequest(RideRequest request) {
    if (_isDisposed) return;

    _log("➕ LOCAL addMyRequest requestId=${request.id}");

    final exists = state.incomingRequests.any((r) => r.id == request.id);
    if (exists) {
      _log("⚠️ Request already exists, skipping");
      return;
    }

    state = state.copyWith(
      incomingRequests: [...state.incomingRequests, request],
      lastUpdated: DateTime.now(),
      hasUnread: true,
    );

    _connectRideSocketIfAccepted(request);
  }

  // ======================================================
  // INITIAL STATE
  // ======================================================
  void _handleInitialStateSafely(dynamic data) {
    if (_isDisposed) return;

    if (data is! List) {
      _log("⚠️ initial_state data is not List");
      return;
    }

    try {
      final requests =
          data.map((e) => RideRequestModel.fromJson(e).toEntity()).toList();

      state = state.copyWith(
        incomingRequests: requests,
        lastUpdated: DateTime.now(),
        hasUnread: requests.isNotEmpty,
      );

      _log("📥 Initial requests → ${requests.length}");

      // ✅ trigger passenger WS only for accepted + not-final rides
      for (final req in requests) {
        _connectRideSocketIfAccepted(req);
      }
    } catch (e, st) {
      _logError("initial_state parse error", e, st);
    }
  }

  // ======================================================
  // REQUEST UPDATED
  // ======================================================
  void _handleRequestUpdatedSafely(dynamic data) {
    if (_isDisposed) return;

    try {
      final updated = RideRequestModel.fromJson(data).toEntity();

      // update or insert
      final updatedList = [...state.incomingRequests];
      final index = updatedList.indexWhere((r) => r.id == updated.id);

      if (index == -1) {
        updatedList.add(updated);
      } else {
        updatedList[index] = updated;
      }

      state = state.copyWith(
        incomingRequests: updatedList,
        lastUpdated: DateTime.now(),
        hasUnread: true,
      );

      _log(
        "🔄 Request updated → requestId=${updated.id} rideId=${updated.rideId} status=${updated.status}",
      );

      // ✅ if now accepted, connect passenger ride ws
      _connectRideSocketIfAccepted(updated);
    } catch (e, st) {
      _logError("ride_request_updated parse error", e, st);
    }
  }

  // ======================================================
  // ✅ CONNECT RIDE WS ONLY WHEN ACCEPTED + NOT FINAL
  // ======================================================
  void _connectRideSocketIfAccepted(RideRequest req) {
    if (_isDisposed) return;

    try {
      final reqStatus = (req.status).toString().toLowerCase();
      if (reqStatus != "accepted") return;

      final int? rideId = int.tryParse(req.rideId.toString());
      if (rideId == null) {
        _log("⚠️ rideId parse failed for requestId=${req.id}");
        return;
      }

      // ✅ IMPORTANT FILTER: don't connect if ride already completed/cancelled
      // this uses cache from passenger controller file
      if (isRideFinalCached(rideId)) {
        _log(
            "🔒 Ride #$rideId already final (cached). Skip passenger WS trigger.");
        return;
      }

      // prevent repeated triggers
      if (_connectedRideSockets.contains(rideId)) return;
      _connectedRideSockets.add(rideId);

      // ✅ Trigger passenger ride controller
      ref.read(passengerRideWSProvider(rideId).notifier);

      _log("🚀 Triggered PassengerRideWSController for rideId=$rideId");
    } catch (e, st) {
      _logError("_connectRideSocketIfAccepted error", e, st);
    }
  }

  // ======================================================
  // SEND ACTION
  // ======================================================
  Future<void> respondToRequest({
    required String requestId,
    required bool isAccepted,
  }) async {
    if (_isDisposed) return;

    if (state.status != ConnectionStatus.connected || _channel == null) {
      _log("⚠️ respondToRequest called but WS not connected");
      return;
    }

    try {
      final payload = {
        "action": isAccepted ? "accept" : "reject",
        "request_id": requestId,
      };

      _channel!.sink.add(jsonEncode(payload));

      _log("📤 Sent action=${payload["action"]} requestId=$requestId");
    } catch (e, st) {
      _logError("send error", e, st);
    }
  }

  // ======================================================
  // RECONNECT LOGIC
  // ======================================================
  void _handleDisconnectSafely() {
    if (_isDisposed) return;

    _log("🚫 Disconnected");

    try {
      _subscription?.cancel();
      _subscription = null;
    } catch (_) {}

    _channel = null;

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      state = state.copyWith(
        status: ConnectionStatus.disconnected,
        error: "Max reconnect attempts reached",
      );
      _log("🛑 Max reconnect attempts reached");
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: min(_reconnectAttempts * 2, 12));

    _log("🔁 Reconnect in ${delay.inSeconds}s (attempt=$_reconnectAttempts)");

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_isDisposed) _connectSafely();
    });
  }

  // ======================================================
  // DISPOSE
  // ======================================================
  @override
  void dispose() {
    _isDisposed = true;

    try {
      _subscription?.cancel();
    } catch (_) {}

    _reconnectTimer?.cancel();

    try {
      _channel?.sink.close(status.normalClosure);
    } catch (_) {}

    super.dispose();
  }
}

// ======================================================
// STATE
// ======================================================
enum ConnectionStatus {
  initial,
  connecting,
  connected,
  disconnected,
  reconnecting,
}

class RideRequestWSState {
  final ConnectionStatus status;
  final List<RideRequest> incomingRequests;
  final String? error;
  final DateTime? lastUpdated;
  final bool hasUnread;

  RideRequestWSState({
    required this.status,
    required this.incomingRequests,
    this.error,
    this.lastUpdated,
    this.hasUnread = false,
  });

  factory RideRequestWSState.initial() => RideRequestWSState(
        status: ConnectionStatus.initial,
        incomingRequests: [],
      );

  RideRequestWSState copyWith({
    ConnectionStatus? status,
    List<RideRequest>? incomingRequests,
    String? error,
    DateTime? lastUpdated,
    bool? hasUnread,
  }) {
    return RideRequestWSState(
      status: status ?? this.status,
      incomingRequests: incomingRequests ?? this.incomingRequests,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasUnread: hasUnread ?? this.hasUnread,
    );
  }

  bool get isConnected => status == ConnectionStatus.connected;
}
