// ignore_for_file: non_constant_identifier_names, avoid_print

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:hop_eir/features/notifications/notification_service.dart';

final passengerRideWSProvider =
    StateNotifierProvider.family<PassengerRideWSController, String, String>(
      (ref, rideId) => PassengerRideWSController(ref, rideId),
    );

final Set<String> _notifiedRides = {};
final Set<String> _404Rides = {};

class PassengerRideWSController extends StateNotifier<String> {
  final Ref ref;
  final String rideId;
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isFinal = false;

  PassengerRideWSController(this.ref, this.rideId) : super('pending') {
    Future.microtask(_initialize);
  }

  Future<void> _initialize() async {
    if (_404Rides.contains(rideId)) {
      state = 'not_found';
      return;
    }

    final status = await _fetchInitialStatus();

    if (_isFinalStatus(status)) {
      _isFinal = true;
      return;
    }

    _connect();
  }

  Future<String> _fetchInitialStatus() async {
    try {
      final response = await http.get(
        Uri.parse('https://hopeir.onrender.com/rides/get/?ride_id=$rideId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)[0];
        final status = data['status']?.toString().toLowerCase();

        if (status != null) {
          state = status;

          if (_isFinalStatus(status)) {
            _isFinal = true;
          }

          return status;
        }
      } else if (response.statusCode == 404) {
        _404Rides.add(rideId);
        print("🚫 Ride #$rideId not found (404)");
        state = 'not_found';
        return 'not_found';
      }

      print("❌ Failed to fetch ride status: ${response.statusCode}");
    } catch (e) {
      print("❌ Exception fetching ride status: $e");
    }

    state = 'pending';
    return 'pending';
  }

  void _connect() {
    if (_isConnected || _isFinal || _404Rides.contains(rideId)) return;

    final url = 'wss://hopeir.onrender.com/ws/ride/$rideId/';
    print("🔌 Connecting to WS for ride #$rideId");

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            final newStatus = data['status']?.toString().toLowerCase();

            if (newStatus != null && newStatus != state) {
              state = newStatus;
              _maybeNotify(newStatus);

              if (_isFinalStatus(newStatus)) {
                _isFinal = true;
                _disconnect();
              }
            }
          } catch (e) {
            print("❌ WS decode error for ride #$rideId: $e");
          }
        },
        onDone: () {
          print("🚫 WS closed for ride #$rideId");
          _isConnected = false;
        },
        onError: (error) {
          print("❌ WS error for ride #$rideId: $error");
          _isConnected = false;
        },
      );
    } catch (e) {
      print("❌ Exception during WS connect for ride #$rideId: $e");
    }
  }

  void _maybeNotify(String status) {
    final key = '$rideId:$status';
    if (!_notifiedRides.contains(key) &&
        !_404Rides.contains(rideId) &&
        status != 'not_found') {
      print(
        "🔔 Showing Notification → 🚘 Ride #$rideId is now ${status.toUpperCase()}",
      );

      LocalNotificationHelper.showNotification(
        '🚘 Ride Status Updated',
        'Your ride is now ${status.toUpperCase()}',
      );

      _notifiedRides.add(key);
    }
  }

  bool _isFinalStatus(String status) =>
      status == 'completed' || status == 'cancelled';

  void _disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }
}
