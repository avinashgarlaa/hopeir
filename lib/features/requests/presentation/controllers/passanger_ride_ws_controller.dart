// ignore_for_file: non_constant_identifier_names, avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hop_eir/features/requests/presentation/controllers/ride_request_ws_controller.dart';
import 'package:hop_eir/features/rides/presentation/providers/ride_repository_provider.dart';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/features/notifications/notification_service.dart';

// ✅ important for live location receive
import 'package:hop_eir/features/rides/presentation/controllers/ride_ws_controller.dart';

final passengerRideWSProvider =
    StateNotifierProvider.family<PassengerRideWSController, String, int>(
  (ref, rideId) => PassengerRideWSController(ref, rideId),
);

// ✅ Global caches for ride status
final Set<String> _notifiedRides = {};
final Set<int> _finalRides = {};

// ✅ Public helper function to check if a ride is already final (cached)
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

  Future<void> _initializeSafely() async {
    if (_isDisposed) return;

    if (isRideFinalCached(rideId)) {
      _isFinal = true;
      state = 'completed';

      debugPrint(
        "🔒 Ride #$rideId already final from cache",
      );

      return;
    }

    await _loadInitialStatus();

    if (_isFinal) {
      debugPrint(
        "🔒 Ride #$rideId already final after API load",
      );
      return;
    }

    if (!_isWsAllowedStatus(state)) {
      debugPrint(
        "⏹️ Ride #$rideId status=$state. "
        "Skipping RideWS and PassengerWS connection.",
      );
      return;
    }

    debugPrint(
      "🚀 Ride #$rideId active (status=$state). "
      "Starting websocket connections.",
    );

    _connectRideSocketForLiveTracking();

    await _connectSafely();
  }

  Uri _buildWsUri() {
    final user = ref.read(authNotifierProvider).user;
    final userId = user?.userId.toString();

    return Uri(
      scheme: "ws",
      host: "34.122.56.250",
      port: 8000,
      path: "/ws/ride/$rideId/",
      queryParameters: userId == null ? null : {"user_id": userId},
    );
  }

  // ✅ passenger must connect RideWSController to receive driver_location
  void _connectRideSocketForLiveTracking() {
    try {
      debugPrint(
        "📍 Connecting RideWS for live tracking ride#$rideId",
      );

      ref
          .read(
            rideWSControllerProvider(rideId).notifier,
          )
          .connect();

      debugPrint(
        "✅ RideWS connect triggered ride#$rideId",
      );
    } catch (e, st) {
      debugPrint(
        "❌ Failed to connect RideWS ride#$rideId => $e",
      );
      debugPrint(st.toString());
    }
  }

  Future<void> _loadInitialStatus() async {
    try {
      final repo = ref.read(rideRepositoryProvider);

      final ride = await repo.getRideById(
        rideId: rideId,
      );

      final status = ride.status.toLowerCase();

      debugPrint(
        "🚘 Initial ride status "
        "ride#$rideId => $status",
      );

      state = status;

      if (_isFinalStatus(status)) {
        _isFinal = true;

        _finalRides.add(rideId);

        debugPrint(
          "🔒 Ride #$rideId already final "
          "(status=$status)",
        );
      }
    } catch (e, st) {
      debugPrint(
        "❌ Failed to load ride#$rideId status => $e",
      );
      debugPrint(st.toString());
    }
  }

  Future<void> _connectSafely() async {
    if (_isDisposed) return;
    if (_isFinal) return;
    if (_isConnecting) return;
    if (_retry >= _maxRetry) return;

    _isConnecting = true;

    try {
      final wsUri = _buildWsUri();

      debugPrint(
        "🔌 Connecting PassengerWS ride#$rideId => $wsUri",
      );

      await _subscription?.cancel();
      _subscription = null;

      try {
        await _channel?.sink.close();
      } catch (_) {}

      _channel = null;

      _channel = IOWebSocketChannel.connect(
        wsUri.toString(),
        pingInterval: const Duration(seconds: 10),
      );

      _subscription = _channel!.stream.listen(
        (message) {
          try {
            final decoded = jsonDecode(message);

            if (decoded is! Map) return;

            String? newStatus;

            if (decoded['type'] == 'ride_status_update') {
              newStatus = decoded['status']?.toString().toLowerCase();
            } else {
              newStatus = decoded['status']?.toString().toLowerCase();
            }

            if (newStatus == null) return;

            if (newStatus != state) {
              final oldStatus = state;

              debugPrint(
                "🚘 STATUS CHANGED "
                "ride#$rideId "
                "$oldStatus -> $newStatus",
              );

              state = newStatus;

              if (newStatus == 'accepted' ||
                  newStatus == 'started' ||
                  newStatus == 'completed' ||
                  newStatus == 'cancelled') {
                _maybeNotify(newStatus);
              }

              // ✅ reconnect tracking when ride becomes active
              if (_isWsAllowedStatus(newStatus)) {
                _connectRideSocketForLiveTracking();
              }

              // ✅ ride finished
              if (_isFinalStatus(newStatus)) {
                _isFinal = true;
                _finalRides.add(rideId);

                debugPrint(
                  "🔒 Ride #$rideId finalized ($newStatus)",
                );

                markRideSocketDisconnected(rideId);

                _disconnect();
              }
            }
          } catch (e, st) {
            debugPrint(
              "❌ PassengerWS parse error ride#$rideId => $e",
            );
            debugPrint(st.toString());
          }
        },
        onDone: () {
          debugPrint(
            "🚫 PassengerWS closed ride#$rideId",
          );

          if (!_isDisposed && !_isFinal) {
            _scheduleReconnect();
          }
        },
        onError: (err) {
          final errStr = err.toString();

          debugPrint(
            "❌ PassengerWS error ride#$rideId => $err",
          );

          if (_isForbiddenWsError(errStr)) {
            debugPrint(
              "⛔ Forbidden PassengerWS ride#$rideId",
            );

            _disconnect();
            return;
          }

          if (!_isDisposed && !_isFinal) {
            _scheduleReconnect();
          }
        },
        cancelOnError: true,
      );

      _retry = 0;

      debugPrint(
        "✅ PassengerWS connected ride#$rideId",
      );
    } catch (e, st) {
      debugPrint(
        "❌ PassengerWS connect failed ride#$rideId => $e",
      );
      debugPrint(st.toString());

      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  bool _isForbiddenWsError(String err) {
    final lower = err.toLowerCase();
    return lower.contains('status code: 403') ||
        lower.contains('http status code: 403') ||
        lower.contains('forbidden') ||
        (lower.contains('was not upgraded to websocket') &&
            lower.contains('403'));
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    if (_isFinal) return;

    if (!_isWsAllowedStatus(state)) {
      return;
    }

    if (_retry >= _maxRetry) return;

    _retry++;
    final delay = Duration(seconds: 2 * _retry);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_isDisposed) _connectSafely();
    });
  }

  void _maybeNotify(String status) {
    final key = '$rideId:$status';

    if (_notifiedRides.contains(key)) return;
    if (status == 'not_found') return;

    debugPrint(
      "🔔 Showing Notification → 🚘 Ride Status Updated: "
      "Your ride is now ${status.toUpperCase()}",
    );

    LocalNotificationHelper.showNotification(
      '🚘 Ride Status Updated',
      'Your ride is now ${status.toUpperCase()}',
    );

    _notifiedRides.add(key);
  }

  bool _isFinalStatus(String status) =>
      status == 'completed' || status == 'cancelled';

  bool _isWsAllowedStatus(String status) {
    final s = status.toLowerCase();
    return s == 'accepted' ||
        s == 'started' ||
        s == 'ongoing' ||
        s == 'in_progress' ||
        s == 'arriving';
  }

  void _disconnect() {
    try {
      debugPrint(
        "🔌 Disconnecting PassengerWS ride#$rideId",
      );

      _subscription?.cancel();
      _subscription = null;

      _reconnectTimer?.cancel();
      _reconnectTimer = null;

      _channel?.sink.close();
      _channel = null;

      debugPrint(
        "✅ PassengerWS disconnected ride#$rideId",
      );
    } catch (e, st) {
      debugPrint(
        "❌ Disconnect error ride#$rideId => $e",
      );
      debugPrint(st.toString());
    }
  }

  // ✅ Public method to check if ride is final (can be called from other controllers)
  bool isFinal() => _isFinal;

  @override
  void dispose() {
    _isDisposed = true;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _disconnect();

    super.dispose();
  }
}
