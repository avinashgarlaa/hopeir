// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/features/notifications/notification_service.dart';
import 'package:hop_eir/features/requests/presentation/controllers/passanger_ride_ws_controller.dart';
import 'package:hop_eir/features/stations/presentation/providers/providers.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../data/models/ride_request_model.dart';
import '../../domain/entities/ride_request.dart';

// ✅ IMPORTANT: passenger ride ws controller

final rideRequestWSControllerProvider = StateNotifierProvider.family<
    RideRequestWSController, RideRequestWSState, String>((ref, userId) {
  return RideRequestWSController(ref, userId);
});

final Set<int> _connectedRideSockets = {};

void markRideSocketConnected(int rideId) {
  _connectedRideSockets.add(rideId);
}

void markRideSocketDisconnected(int rideId) {
  _connectedRideSockets.remove(rideId);
}

bool isRideSocketConnected(int rideId) {
  return _connectedRideSockets.contains(rideId);
}

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

  RideRequestWSController(this.ref, this.userId)
      : super(RideRequestWSState.initial()) {
    Future.microtask(() => _connectSafely());
  }

  // ======================================================
  // LOG HELPERS (BEST LOGGING)
  // ======================================================

  // ======================================================
  // CONNECT
  // ======================================================
  Uri _buildWsUri() {
    return Uri(
      scheme: "ws",
      host: "34.122.56.250",
      port: 8000,
      path: "/ws/ride-requests/",
      queryParameters: {"user_id": userId},
    );
  }

  Future<void> _connectSafely() async {
    if (_isDisposed) return;
    if (_isConnecting) return;

    _isConnecting = true;

    final uri = _buildWsUri();

    state = state.copyWith(
      status: _reconnectAttempts > 0
          ? ConnectionStatus.reconnecting
          : ConnectionStatus.connecting,
    );

    try {
      await _subscription?.cancel();
      _subscription = null;

      try {
        _channel?.sink.close(status.normalClosure);
      } catch (_) {}

      _channel = null;

      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;

      _subscription = _channel!.stream.listen(
        _handleMessageSafely,
        onDone: () {
          debugPrint(
            "🚫 WS CLOSED "
            "closeCode=${_channel?.closeCode} "
            "closeReason=${_channel?.closeReason}",
          );

          _handleDisconnectSafely();
        },
        onError: (error) {
          debugPrint(
            "❌ WS ERROR => $error",
          );

          _handleDisconnectSafely();
        },
        cancelOnError: true,
      );

      state = state.copyWith(
        status: ConnectionStatus.connected,
        error: null,
      );

      debugPrint(
        "✅ WebSocket READY "
        "user=$userId "
        "time=${DateTime.now().toIso8601String()}",
      );

      _reconnectAttempts = 0;
    } catch (e, st) {
      debugPrint("❌ CONNECT FAILED => $e");
      debugPrint(st.toString());

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

    final msgString = message?.toString() ?? '';

    debugPrint("📩 Message received (${msgString.length} chars)");
    debugPrint("📦 RAW => $msgString");

    Map<String, dynamic> decoded;

    try {
      final raw = jsonDecode(msgString);

      if (raw is! Map) {
        debugPrint("⚠️ Ignored non-map message");
        return;
      }

      decoded = Map<String, dynamic>.from(raw);
    } catch (e) {
      debugPrint("⚠️ Invalid JSON message => $e");
      return;
    }

    final type = decoded['type']?.toString();

    if (type == null) {
      debugPrint("⚠️ Missing message type");
      return;
    }

    switch (type) {
      case 'initial_state':
        debugPrint("📥 initial_state");
        _handleInitialStateSafely(decoded['data']);
        break;

      case 'ride_request_updated':
        debugPrint(
          "🔄 ride_request_updated => "
          "${jsonEncode(decoded['data'])}",
        );

        _handleRequestUpdatedSafely(decoded['data']);
        break;

      case 'ride_request_created':
        debugPrint(
          "🆕 ride_request_created => "
          "${jsonEncode(decoded['data'])}",
        );

        _handleRideRequestCreated(decoded['data']);
        break;

      case 'error':
        final errorMessage =
            decoded['message']?.toString() ?? 'Unknown backend error';

        debugPrint(
          "❌ Backend error => $errorMessage",
        );

        LocalNotificationHelper.showNotification(
          'Ride Request Error',
          errorMessage,
        );
        break;

      default:
        debugPrint(
          "⚠️ Unknown WS message type => $type\n"
          "Payload => ${jsonEncode(decoded)}",
        );
    }
  }

  // ======================================================
  // LOCAL INSERT (HTTP → WS BRIDGE)
  // ======================================================
  void addMyRequest(RideRequest request) {
    if (_isDisposed) return;

    final exists = state.incomingRequests.any((r) => r.id == request.id);
    if (exists) {
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
      debugPrint("⚠️ initial_state payload is not a List");
      return;
    }

    try {
      final requests = data
          .map(
            (e) => RideRequestModel.fromJson(
              Map<String, dynamic>.from(e),
            ).toEntity(),
          )
          .toList();

      debugPrint(
        "📥 Initial state received "
        "requests=${requests.length}",
      );

      state = state.copyWith(
        incomingRequests: requests,
        lastUpdated: DateTime.now(),
        hasUnread: requests.isNotEmpty,
      );

      for (final req in requests) {
        debugPrint(
          "📋 Request "
          "id=${req.id} "
          "ride=${req.rideId} "
          "status=${req.status}",
        );

        _connectRideSocketIfAccepted(req);
      }
    } catch (e, st) {
      debugPrint(
        "❌ Failed to parse initial_state: $e",
      );
      debugPrint(st.toString());
    }
  }

  // ======================================================
  // REQUEST UPDATED
  // ======================================================
  Future<void> _handleRequestUpdatedSafely(dynamic data) async {
    if (_isDisposed) return;

    try {
      if (data == null || data is! Map) {
        debugPrint(
          "⚠️ Invalid ride_request_updated payload",
        );
        return;
      }

      final updated = RideRequestModel.fromJson(
        Map<String, dynamic>.from(data),
      ).toEntity();

      final updatedList = [...state.incomingRequests];

      final index = updatedList.indexWhere(
        (r) => r.id.toString() == updated.id.toString(),
      );

      if (index != -1) {
        updatedList[index] = updated;
      } else {
        updatedList.add(updated);
      }

      state = state.copyWith(
        incomingRequests: updatedList,
        lastUpdated: DateTime.now(),
        hasUnread: true,
      );

      debugPrint(
        "🔄 Updated request "
        "id=${updated.id} "
        "ride=${updated.rideId} "
        "status=${updated.status}",
      );

      final newStatus = updated.status.toLowerCase();

      // Current logged in user
      final myUserId = ref.read(authNotifierProvider).user?.userId.toString();

      // ✅ Request Accepted (Passenger only)
      if (newStatus == "accepted") {
        if (myUserId != null && updated.passengerId.toString() == myUserId) {
          ref.read(hasUnreadRequestsProvider.notifier).state = true;
          await LocalNotificationHelper.showNotification(
            "✅ Ride Request Accepted",
            "Driver accepted your ride request.",
          );
        }

        _connectRideSocketIfAccepted(updated);
      }

      // ✅ Request Rejected (Passenger only)
      if (newStatus == "rejected") {
        if (myUserId != null && updated.passengerId.toString() == myUserId) {
          ref.read(hasUnreadRequestsProvider.notifier).state = true;
          await LocalNotificationHelper.showNotification(
            "❌ Ride Request Rejected",
            "Driver rejected your ride request.",
          );
        }
      }
    } catch (e, st) {
      debugPrint(
        "❌ Failed to handle ride_request_updated: $e",
      );
      debugPrint(st.toString());
    }
  }

  // ======================================================
  // ✅ CONNECT RIDE WS ONLY WHEN ACCEPTED + NOT FINAL
  // ======================================================
  void _connectRideSocketIfAccepted(RideRequest req) {
    if (_isDisposed) return;

    try {
      final reqStatus = req.status.toString().toLowerCase();
      if (reqStatus != "accepted") return;

      final int? rideId = int.tryParse(req.rideId.toString());
      if (rideId == null) return;

      if (isRideFinalCached(rideId)) {
        debugPrint(
          "🔒 Ride #$rideId already final (cached). Skip passenger WS trigger.",
        );
        return;
      }

      if (isRideSocketConnected(rideId)) {
        debugPrint(
          "⚠️ PassengerRideWS already running for rideId=$rideId",
        );
        return;
      }

      markRideSocketConnected(rideId);

      // ✅ ACTUALLY START THE PASSENGER WS
      ref.read(
        passengerRideWSProvider(rideId).notifier,
      );

      debugPrint(
        "🚀 Triggered PassengerRideWSController for rideId=$rideId",
      );
    } catch (e, st) {
      debugPrint(
        "❌ Failed to trigger PassengerRideWSController: $e",
      );
      debugPrint(st.toString());
    }
  }

  // ======================================================
  // SEND ACTION
  // ======================================================
  Future<void> respondToRequest({
    required int requestId,
    required bool isAccepted,
  }) async {
    if (_isDisposed) return;

    if (state.status != ConnectionStatus.connected || _channel == null) {
      debugPrint(
        "❌ Cannot respond. WS not connected.",
      );
      return;
    }

    try {
      final payload = {
        "action": isAccepted ? "accept" : "reject",
        "request_id": requestId,
      };

      debugPrint(
        "📤 Sending request response => "
        "${jsonEncode(payload)}",
      );

      _channel!.sink.add(
        jsonEncode(payload),
      );

      debugPrint(
        "✅ Request response sent "
        "requestId=$requestId "
        "action=${isAccepted ? "accept" : "reject"}",
      );
    } catch (e, st) {
      debugPrint(
        "❌ Failed to send request response: $e",
      );
      debugPrint(st.toString());

      LocalNotificationHelper.showNotification(
        "Request Error",
        "Failed to send response to request",
      );
    }
  }

  Future<void> _handleRideRequestCreated(dynamic data) async {
    try {
      if (data == null || data is! Map) {
        debugPrint("⚠️ Invalid ride_request_created payload");
        return;
      }

      final payload = Map<String, dynamic>.from(data);

      final request = RideRequest(
        id: payload['request_id'].toString(),
        rideId: payload['ride_id'],
        passengerId: payload['from_user']?['id']?.toString() ?? '',
        passengerName: payload['from_user']?['name']?.toString() ?? 'Unknown',
        driverId: payload['driver_id']?.toString() ?? '',
        status: payload['request_status']?.toString() ?? 'pending',
        requestedAt: payload['requested_at']?.toString(),
      );

      final exists = state.incomingRequests.any(
        (r) => r.id.toString() == request.id.toString(),
      );

      if (exists) {
        debugPrint(
          "⚠️ Request already exists id=${request.id}",
        );
        return;
      }

      state = state.copyWith(
        incomingRequests: [
          request,
          ...state.incomingRequests,
        ],
        lastUpdated: DateTime.now(),
        hasUnread: true,
      );
      ref.read(hasUnreadRequestsProvider.notifier).state = true;
      await LocalNotificationHelper.showNotification(
        "🚘 New Ride Request",
        "${request.passengerName} requested your ride",
      );
    } catch (e, st) {
      debugPrint(
        "❌ Failed to handle ride_request_created: $e",
      );
      debugPrint(st.toString());
    }
  }

  // ======================================================
  // RECONNECT LOGIC
  // ======================================================
  void _handleDisconnectSafely() {
    if (_isDisposed) {
      return;
    }

    try {
      _subscription?.cancel();
      _subscription = null;
    } catch (_) {}

    _channel = null;

    state = state.copyWith(
      status: ConnectionStatus.reconnecting,
    );
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      state = state.copyWith(
        status: ConnectionStatus.disconnected,
        error: "Max reconnect attempts reached",
      );
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: min(_reconnectAttempts * 2, 12));

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
