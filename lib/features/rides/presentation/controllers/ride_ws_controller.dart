// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:hop_eir/features/notifications/notification_service.dart';

final rideWSControllerProvider =
    StateNotifierProvider.family<RideWSController, RideWSState, int>(
      (ref, rideId) => RideWSController(ref, rideId),
    );

class RideWSState {
  final String status;
  final String message;

  RideWSState({required this.status, required this.message});

  RideWSState copyWith({String? status, String? message}) {
    return RideWSState(
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}

class RideWSController extends StateNotifier<RideWSState> {
  final Ref ref;
  final int rideId;
  WebSocketChannel? _channel;
  bool _initialMessageSkipped = false;
  String? _lastStatus;

  RideWSController(this.ref, this.rideId)
    : super(RideWSState(status: 'scheduled', message: 'Connecting…')) {
    _connect();
  }

  void _connect() {
    final uri = Uri.parse('wss://hopeir.onrender.com/ws/ride/$rideId/');
    print('🚀 WS connecting to $uri');

    try {
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        _onMessage,
        onError: (err) => _handleError('WebSocket error: $err'),
        onDone: _handleDone,
      );
    } catch (e) {
      _handleError('❌ WebSocket connection failed: $e');
    }
  }

  void _handleError(String message) {
    print(message);
    state = state.copyWith(message: message);
  }

  void _handleDone() {
    print('ℹ️ WS closed for ride $rideId');
    state = state.copyWith(message: 'Disconnected');

    // Optional reconnect logic for non-terminal status
    if (!['completed', 'cancelled'].contains(_lastStatus)) {
      Future.delayed(const Duration(seconds: 2), _connect);
    }
  }

  void _onMessage(dynamic raw) {
    print('📩 Raw WebSocket message: $raw');

    try {
      final data = jsonDecode(raw as String);
      final incomingStatus =
          (data['status'] as String?)?.toLowerCase() ?? state.status;
      final incomingMsg = data['message'] as String? ?? '';

      if (!_initialMessageSkipped) {
        _initialMessageSkipped = true;
        _lastStatus = incomingStatus;
        print('🛑 Skipping first status update: $incomingStatus');
        state = RideWSState(status: incomingStatus, message: incomingMsg);
        return;
      }

      if (_lastStatus == incomingStatus) {
        print('🔄 No status change. Skipping notification.');
        return;
      }

      _lastStatus = incomingStatus;

      if (!['completed', 'cancelled'].contains(incomingStatus)) {
        LocalNotificationHelper.showNotification(
          '🚘 Ride Status Updated',
          'Your ride is now ${incomingStatus.toUpperCase()}',
        );
      } else {
        print('⚠️ Ride in terminal state: $incomingStatus');
      }

      state = RideWSState(status: incomingStatus, message: incomingMsg);
    } catch (e) {
      _handleError('❌ Decode error: $e');
    }
  }

  Future<void> sendAction(String action) async {
    if (_channel == null) {
      print('⚠️ WebSocket not connected yet.');
      return;
    }

    try {
      final msg = jsonEncode({'action': action});
      _channel!.sink.add(msg);
      print('✅ Sent action "$action" for ride #$rideId');
    } catch (e) {
      print('❌ Failed to send action: $e');
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    print('🛑 WS disposed for ride $rideId');
    super.dispose();
  }
}
