import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/features/notifications/notification_service.dart';

final rideWSControllerProvider =
    StateNotifierProvider.family<RideWSController, RideWSState, int>(
  (ref, rideId) => RideWSController(ref, rideId),
);

/// ───────────────── CHAT MODEL ─────────────────
class ChatMessage {
  final String message;
  final String senderId;
  final DateTime timestamp;

  ChatMessage({
    required this.message,
    required this.senderId,
    required this.timestamp,
  });
}

/// ───────────────── STATE ─────────────────
class RideWSState {
  final String status;
  final List<ChatMessage> chatMessages;
  final String? myUserId;
  final bool historyLoaded;

  /// backend sends: "driver" / "passenger"
  final String? role;

  /// LIVE DRIVER LOCATION
  final LatLng? driverLatLng;
  final double driverBearing;

  /// connection info
  final bool connected;
  final String? lastError;

  /// driver tracking (sending GPS)
  final bool driverTrackingEnabled;

  RideWSState({
    required this.status,
    this.chatMessages = const [],
    this.myUserId,
    this.historyLoaded = false,
    this.role,
    this.driverLatLng,
    this.driverBearing = 0,
    this.connected = false,
    this.lastError,
    this.driverTrackingEnabled = false,
  });

  RideWSState copyWith({
    String? status,
    List<ChatMessage>? chatMessages,
    bool? historyLoaded,
    String? role,
    LatLng? driverLatLng,
    double? driverBearing,
    bool clearDriverLocation = false,
    bool? connected,
    String? lastError,
    bool clearError = false,
    bool? driverTrackingEnabled,
  }) {
    return RideWSState(
      status: status ?? this.status,
      chatMessages: chatMessages ?? this.chatMessages,
      myUserId: myUserId,
      historyLoaded: historyLoaded ?? this.historyLoaded,
      role: role ?? this.role,
      driverLatLng:
          clearDriverLocation ? null : (driverLatLng ?? this.driverLatLng),
      driverBearing: driverBearing ?? this.driverBearing,
      connected: connected ?? this.connected,
      lastError: clearError ? null : (lastError ?? this.lastError),
      driverTrackingEnabled:
          driverTrackingEnabled ?? this.driverTrackingEnabled,
    );
  }
}

/// ───────────────── CONTROLLER ─────────────────
class RideWSController extends StateNotifier<RideWSState> {
  final Ref ref;
  final int rideId;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  bool _reconnecting = false;
  bool _manualDisconnect = false;
  Timer? _reconnectTimer;

  /// Driver GPS stream
  StreamSubscription<Position>? _positionSub;
  Position? _lastSentPos;
  DateTime _lastSentAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// ✅ Location stream retry (for iOS sim kCLErrorDomain error 0)
  Timer? _locationRetryTimer;
  bool _startingLocationStream = false;

  RideWSController(this.ref, this.rideId)
      : super(
          RideWSState(
            status: 'pending',
            myUserId: ref.read(authNotifierProvider).user?.userId.toString(),
          ),
        ) {
    Future.microtask(() => connect());
  }

  bool get isConnected =>
      _channel != null && _sub != null && state.connected == true;

  // ───────────────── HELPERS ─────────────────

  bool _isDriver() => state.role == "driver";

  bool _isRideActiveForTracking(String status) {
    final s = status.toLowerCase();
    return s == 'ongoing' || s == 'started' || s == 'in_progress';
  }

  /// SAFE double parse (num or string)
  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  /// ✅ bearing guard (simulator may give NaN / Infinity)
  double _sanitizeBearing(dynamic bearing) {
    final b = _toDouble(bearing);
    if (b.isNaN || b.isInfinite) return 0.0;
    return b;
  }

  // ───────────────── CONNECT / DISCONNECT ─────────────────

  void connect() {
    if (isConnected) return;
    _manualDisconnect = false;
    _connectInternal();
  }

  void disconnect() {
    _manualDisconnect = true;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _sub?.cancel();
    _sub = null;

    try {
      _channel?.sink.close();
    } catch (_) {}

    _channel = null;

    state = state.copyWith(connected: false);
  }

  void _connectInternal() {
    final userId = state.myUserId;
    if (userId == null) return;

    if (_channel != null) return;

    final uri = Uri(
      scheme: 'ws',
      host: '34.122.56.250',
      port: 8000,
      path: '/ws/ride/$rideId/',
      queryParameters: {
        'user_id': userId,
      },
    );

    try {
      debugPrint("🔌 Connecting WS ride#$rideId => $uri");

      _channel = WebSocketChannel.connect(uri);

      _sub = _channel!.stream.listen(
        _onMessage,
        onDone: _handleClosed,
        onError: (err) => _handleError(err),
        cancelOnError: false,
      );

      state = state.copyWith(clearError: true);
    } catch (e) {
      _channel = null;
      _sub = null;
      state = state.copyWith(connected: false, lastError: e.toString());
      _reconnect();
    }
  }

  void _handleClosed() {
    debugPrint("🔌 WS closed ride#$rideId");
    _channel = null;
    _sub = null;

    state = state.copyWith(connected: false);

    if (_manualDisconnect) return;
    _reconnect();
  }

  void _handleError(Object err) {
    final errStr = err.toString();
    debugPrint("❌ WS error ride#$rideId => $errStr");

    _channel = null;
    _sub = null;

    state = state.copyWith(connected: false, lastError: errStr);

    if (_manualDisconnect) return;
    _reconnect();
  }

  void _reconnect() {
    if (_reconnecting || _manualDisconnect) return;
    _reconnecting = true;

    _channel = null;
    _sub?.cancel();
    _sub = null;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      _reconnecting = false;
      if (_manualDisconnect) return;
      _connectInternal();
    });
  }

  // ───────────────── DRIVER LIVE LOCATION (SEND) ─────────────────

  Future<void> startDriverLiveTracking() async {
    debugPrint("🧭 startDriverLiveTracking ride#$rideId");

    if (!_isDriver()) {
      debugPrint(
          "🛑 Passenger blocked from starting driver tracking ride#$rideId");
      return;
    }

    if (state.driverTrackingEnabled) {
      debugPrint("✅ Tracking already ON ride#$rideId");
      return;
    }

    if (!_isRideActiveForTracking(state.status)) {
      debugPrint(
          "🛑 Ride not active for tracking ride#$rideId (status=${state.status})");
      state = state.copyWith(
        lastError:
            "Tracking not started: ride not active (status=${state.status}).",
      );
      return;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      state = state.copyWith(
        lastError: "Location permission denied. Live tracking not started.",
      );
      return;
    }

    if (!isConnected) connect();

    state = state.copyWith(driverTrackingEnabled: true, clearError: true);

    /// ✅ start (or restart) safe tracking stream
    await _startOrRestartLocationStream();
  }

  Future<void> _startOrRestartLocationStream() async {
    if (_startingLocationStream) return;
    _startingLocationStream = true;

    _locationRetryTimer?.cancel();
    _locationRetryTimer = null;

    try {
      /// ✅ BEST for emulator + simulator
      /// distanceFilter 0 => always update
      const settings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      );

      await _positionSub?.cancel();
      _positionSub = null;

      debugPrint("📍 Starting location stream ride#$rideId...");

      _positionSub =
          Geolocator.getPositionStream(locationSettings: settings).listen(
        (pos) {
          final now = DateTime.now();

          /// ✅ send more frequently for smoother marker
          if (now.difference(_lastSentAt).inMilliseconds < 250) return;

          /// ✅ allow very tiny movement (emulator sometimes moves small)
          if (_lastSentPos != null) {
            final moved = Geolocator.distanceBetween(
              _lastSentPos!.latitude,
              _lastSentPos!.longitude,
              pos.latitude,
              pos.longitude,
            );

            if (moved < 0.1) return; // ✅ was 0.5m earlier
          }

          _lastSentAt = now;
          _lastSentPos = pos;

          final bearing = _sanitizeBearing(pos.heading);

          debugPrint(
              "🚗 ride#$rideId sending driver loc: ${pos.latitude}, ${pos.longitude}");

          sendDriverLocation(
            lat: pos.latitude,
            lng: pos.longitude,
            bearing: bearing,
          );
        },

        /// ✅ KEY FIX: handle CoreLocation failures
        onError: (e) {
          debugPrint("📍 Location stream error ride#$rideId => $e");
          _scheduleLocationStreamRetry();
        },

        cancelOnError: false,
      );
    } catch (e) {
      debugPrint("❌ Failed to start location stream ride#$rideId => $e");
      _scheduleLocationStreamRetry();
    } finally {
      _startingLocationStream = false;
    }
  }

  void _scheduleLocationStreamRetry() {
    if (!state.driverTrackingEnabled) return;
    if (_locationRetryTimer != null) return;

    _locationRetryTimer = Timer(const Duration(seconds: 2), () async {
      _locationRetryTimer = null;

      if (!state.driverTrackingEnabled) return;

      debugPrint("🔁 Restarting location stream ride#$rideId ...");
      await _startOrRestartLocationStream();
    });
  }

  Future<void> stopDriverLiveTracking() async {
    _locationRetryTimer?.cancel();
    _locationRetryTimer = null;

    await _positionSub?.cancel();
    _positionSub = null;

    _lastSentPos = null;

    state = state.copyWith(driverTrackingEnabled: false);
    debugPrint("🛑 Tracking stopped ride#$rideId");
  }

  // ───────────────── RECEIVE ─────────────────

  void _onMessage(dynamic raw) {
    try {
      debugPrint("📩 WS RAW ride#$rideId => $raw");
      final data = jsonDecode(raw);

      switch (data['type']) {
        case 'connection':
          _handleConnection(data);
          break;
        case 'chat_history':
          _handleChatHistory(data);
          break;
        case 'chat_message':
          _handleChat(data);
          break;
        case 'ride_status_update':
          _handleRideStatus(data);
          break;
        case 'driver_location':
          _handleDriverLocation(data);
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint("❌ WS parse error ride#$rideId => $e");
    }
  }

  void _handleConnection(Map<String, dynamic> data) async {
    final statusRaw = data['status'];
    if (statusRaw == null) return;

    final status = statusRaw.toString();
    final role = data['role']?.toString();

    debugPrint("✅ connection ride#$rideId: role=$role status=$status");

    state = state.copyWith(
      status: status,
      role: role,
      connected: true,
      clearError: true,
    );

    final lower = status.toLowerCase();
    final shouldTrackNow =
        lower == "ongoing" || lower == "started" || lower == "in_progress";

    if (shouldTrackNow && _isDriver()) {
      /// ✅ always attempt start (safe due to guards)
      await startDriverLiveTracking();
    }
  }

  void _handleChatHistory(Map<String, dynamic> data) {
    if (state.historyLoaded) return;

    final messages = (data['messages'] as List).map((e) {
      return ChatMessage(
        message: e['message'],
        senderId: e['sender_id'].toString(),
        timestamp: DateTime.parse(e['timestamp']),
      );
    }).toList();

    state = state.copyWith(chatMessages: messages, historyLoaded: true);
  }

  void _handleRideStatus(Map<String, dynamic> data) async {
    final statusRaw = data['status'];
    if (statusRaw == null) return;

    final status = statusRaw.toString();
    final lower = status.toLowerCase();

    if (!{'completed', 'cancelled'}.contains(lower)) {
      LocalNotificationHelper.showNotification(
        '🚘 Ride Update',
        'Ride is now ${status.toUpperCase()}',
      );
    }

    final shouldClearDriver = lower == 'completed' || lower == 'cancelled';

    state = state.copyWith(
      status: status,
      clearDriverLocation: shouldClearDriver,
    );

    if (shouldClearDriver) {
      await stopDriverLiveTracking();
      disconnect();
      return;
    }

    final shouldTrackNow =
        lower == 'ongoing' || lower == 'started' || lower == 'in_progress';

    if (shouldTrackNow && _isDriver()) {
      await startDriverLiveTracking();
    } else {
      // not trackable anymore
      if (state.driverTrackingEnabled) await stopDriverLiveTracking();
    }
  }

  void _handleChat(Map<String, dynamic> data) {
    final timestamp = DateTime.parse(data['timestamp']);

    final exists = state.chatMessages.any(
      (m) =>
          m.message == data['message'] &&
          m.senderId == data['sender_id'].toString() &&
          m.timestamp == timestamp,
    );
    if (exists) return;

    state = state.copyWith(
      chatMessages: [
        ...state.chatMessages,
        ChatMessage(
          message: data['message'],
          senderId: data['sender_id'].toString(),
          timestamp: timestamp,
        ),
      ],
    );
  }

  void _handleDriverLocation(Map<String, dynamic> data) {
    final latRaw = data['latitude'];
    final lngRaw = data['longitude'];

    if (latRaw == null || lngRaw == null) return;

    final lat = _toDouble(latRaw);
    final lng = _toDouble(lngRaw);
    final bearing = _sanitizeBearing(data['bearing']);

    debugPrint("📍 DRIVER LOCATION RECEIVED ride#$rideId: $lat, $lng");

    state = state.copyWith(
      driverLatLng: LatLng(lat, lng),
      driverBearing: bearing,
      clearError: true,
    );
  }

  // ───────────────── SEND ─────────────────

  void sendChatMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (!isConnected) connect();
    if (!isConnected) return;

    _channel!.sink.add(jsonEncode({'action': 'chat', 'message': trimmed}));
  }

  void sendAction(String action) {
    final normalized = action.toLowerCase();
    if (!{'start', 'end', 'cancel'}.contains(normalized)) return;

    if (!isConnected) connect();
    if (!isConnected) return;

    _channel!.sink.add(jsonEncode({'action': normalized}));
  }

  void sendDriverLocation({
    required double lat,
    required double lng,
    double bearing = 0,
  }) {
    if (!_isDriver()) return;

    if (!isConnected) connect();
    if (!isConnected) return;

    _channel!.sink.add(
      jsonEncode({
        "action": "location_update",
        "latitude": lat,
        "longitude": lng,
        "bearing": bearing,
      }),
    );
  }

  @override
  void dispose() {
    stopDriverLiveTracking();
    disconnect();
    super.dispose();
  }
}
