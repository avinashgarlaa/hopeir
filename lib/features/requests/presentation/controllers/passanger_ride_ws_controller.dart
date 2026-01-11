// ignore_for_file: non_constant_identifier_names, avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart'; // ✅ IMPORTANT

import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/features/notifications/notification_service.dart';

final passengerRideWSProvider =
    StateNotifierProvider.family<PassengerRideWSController, String, int>(
  (ref, rideId) => PassengerRideWSController(ref, rideId),
);

final Set<String> _notifiedRides = {};
final Set<int> _404Rides = {};
final Set<int> _finalRides = {};
bool isRideFinalCached(int rideId) => _finalRides.contains(rideId);

class PassengerRideWSController extends StateNotifier<String> {
  final Ref ref;
  final int rideId;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  bool _isFinal = false;
  bool _isConnecting = false;
  bool _isDisposed = false;

  Timer? _reconnectTimer;
  int _retry = 0;
  static const int _maxRetry = 5;

  PassengerRideWSController(this.ref, this.rideId) : super('pending') {
    Future.microtask(() => _initializeSafely());
  }

  void _log(String msg) => print("[PassengerWS][ride=$rideId] $msg");

  Future<void> _initializeSafely() async {
    try {
      if (_isDisposed) return;

      if (_404Rides.contains(rideId)) {
        state = 'not_found';
        return;
      }

      if (isRideFinalCached(rideId)) {
        _isFinal = true;
        state = "completed";
        _log("🔒 Already final (cached). WS not required");
        return;
      }

      final status = await _fetchInitialStatus();

      if (_isFinalStatus(status)) {
        _isFinal = true;
        _finalRides.add(rideId);
        _log("🔒 Ride is final ($status). WS not required");
        return;
      }

      await _connectSafely();
    } catch (e, st) {
      _log("❌ init error: $e");
      _log("$st");
      _scheduleReconnect();
    }
  }

  Future<String> _fetchInitialStatus() async {
    try {
      final response = await http.get(
        Uri.parse('https://hopeir.onrender.com/rides/get/?ride_id=$rideId'),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List && decoded.isNotEmpty) {
          final data = decoded[0];
          final status = data['status']?.toString().toLowerCase();

          if (status != null) {
            state = status;

            if (_isFinalStatus(status)) {
              _isFinal = true;
              _finalRides.add(rideId);
            }

            return status;
          }
        }
      } else if (response.statusCode == 404) {
        _404Rides.add(rideId);
        state = 'not_found';
        _log("🚫 Ride not found (404)");
        return 'not_found';
      }

      _log("❌ Failed to fetch status: ${response.statusCode}");
    } catch (e) {
      _log("❌ Exception fetching status: $e");
    }

    state = 'pending';
    return 'pending';
  }

  Uri _buildWsUri() {
    final user = ref.read(authNotifierProvider).user;
    final userId = user?.userId.toString();

    return Uri(
      scheme: "wss",
      host: "hopeir.onrender.com",
      path: "/ws/ride/$rideId/",
      queryParameters: userId == null ? null : {"user_id": userId},
    );
  }

  Future<void> _connectSafely() async {
    if (_isDisposed) return;
    if (_isFinal) return;
    if (_isConnecting) return;
    if (_retry >= _maxRetry) return;

    _isConnecting = true;

    try {
      final wsUri = _buildWsUri();
      _log("🔌 Connecting → $wsUri");

      await _subscription?.cancel();
      _subscription = null;

      try {
        _channel?.sink.close();
      } catch (_) {}
      _channel = null;

      // ✅ IMPORTANT: Force IO channel for mobile
      _channel = IOWebSocketChannel.connect(
        wsUri.toString(),
        pingInterval: const Duration(seconds: 10),
      );

      _subscription = _channel!.stream.listen(
        (message) {
          try {
            final decoded = jsonDecode(message);

            if (decoded is! Map) return;

            final newStatus = decoded['status']?.toString().toLowerCase();
            if (newStatus == null) return;

            if (newStatus != state) {
              state = newStatus;
              _maybeNotify(newStatus);

              if (_isFinalStatus(newStatus)) {
                _isFinal = true;
                _finalRides.add(rideId);
                _log("🔒 Ride final via WS ($newStatus). Closing.");
                _disconnect();
              }
            }
          } catch (e) {
            _log("⚠️ decode error: $e");
          }
        },
        onDone: () {
          _log("🚫 WS closed");
          if (!_isDisposed && !_isFinal) _scheduleReconnect();
        },
        onError: (err) {
          _log("❌ WS error: $err");
          if (!_isDisposed && !_isFinal) _scheduleReconnect();
        },
        cancelOnError: true,
      );

      _retry = 0;
      _log("✅ Connected");
    } catch (e, st) {
      _log("❌ connect exception: $e");
      _log("$st");
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    if (_isFinal) return;
    if (_retry >= _maxRetry) return;

    _retry++;
    final delay = Duration(seconds: 2 * _retry);

    _log("🔁 reconnect in ${delay.inSeconds}s (attempt=$_retry)");

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_isDisposed) _connectSafely();
    });
  }

  void _maybeNotify(String status) {
    final key = '$rideId:$status';

    if (_notifiedRides.contains(key)) return;
    if (_404Rides.contains(rideId)) return;
    if (status == 'not_found') return;

    _log("🔔 Notification → ${status.toUpperCase()}");

    LocalNotificationHelper.showNotification(
      '🚘 Ride Status Updated',
      'Your ride is now ${status.toUpperCase()}',
    );

    _notifiedRides.add(key);
  }

  bool _isFinalStatus(String status) =>
      status == 'completed' || status == 'cancelled';

  void _disconnect() {
    try {
      _subscription?.cancel();
      _subscription = null;

      _channel?.sink.close();
      _channel = null;
    } catch (_) {}
  }

  @override
  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _disconnect();
    super.dispose();
  }
}
