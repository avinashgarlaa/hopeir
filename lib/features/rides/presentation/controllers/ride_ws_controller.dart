// // ignore_for_file: avoid_print

// import 'dart:convert';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:hop_eir/features/notifications/notification_service.dart';

// final rideWSControllerProvider =
//     StateNotifierProvider.family<RideWSController, RideWSState, int>(
//       (ref, rideId) => RideWSController(ref, rideId),
//     );

// class RideWSState {
//   final String status;
//   final String message;

//   RideWSState({required this.status, required this.message});

//   RideWSState copyWith({String? status, String? message}) {
//     return RideWSState(
//       status: status ?? this.status,
//       message: message ?? this.message,
//     );
//   }
// }

// class RideWSController extends StateNotifier<RideWSState> {
//   final Ref ref;
//   final int rideId;
//   WebSocketChannel? _channel;
//   bool _initialMessageSkipped = false;
//   String? _lastStatus;

//   RideWSController(this.ref, this.rideId)
//     : super(RideWSState(status: 'scheduled', message: 'Connecting…')) {
//     _connect();
//   }

//   void _connect() {
//     final uri = Uri.parse('wss://hopeir.onrender.com/ws/ride/$rideId/');
//     print('🚀 WS connecting to $uri');

//     try {
//       _channel = WebSocketChannel.connect(uri);
//       _channel!.stream.listen(
//         _onMessage,
//         onError: (err) => _handleError('WebSocket error: $err'),
//         onDone: _handleDone,
//       );
//     } catch (e) {
//       _handleError('❌ WebSocket connection failed: $e');
//     }
//   }

//   void _handleError(String message) {
//     print(message);
//     state = state.copyWith(message: message);
//   }

//   void _handleDone() {
//     print('ℹ️ WS closed for ride $rideId');
//     state = state.copyWith(message: 'Disconnected');

//     // Optional reconnect logic for non-terminal status
//     if (!['completed', 'cancelled'].contains(_lastStatus)) {
//       Future.delayed(const Duration(seconds: 2), _connect);
//     }
//   }

//   void _onMessage(dynamic raw) {
//     print('📩 Raw WebSocket message: $raw');

//     try {
//       final data = jsonDecode(raw as String);
//       final incomingStatus =
//           (data['status'] as String?)?.toLowerCase() ?? state.status;
//       final incomingMsg = data['message'] as String? ?? '';

//       if (!_initialMessageSkipped) {
//         _initialMessageSkipped = true;
//         _lastStatus = incomingStatus;
//         print('🛑 Skipping first status update: $incomingStatus');
//         state = RideWSState(status: incomingStatus, message: incomingMsg);
//         return;
//       }

//       if (_lastStatus == incomingStatus) {
//         print('🔄 No status change. Skipping notification.');
//         return;
//       }

//       _lastStatus = incomingStatus;

//       if (!['completed', 'cancelled'].contains(incomingStatus)) {
//         LocalNotificationHelper.showNotification(
//           '🚘 Ride Status Updated',
//           'Your ride is now ${incomingStatus.toUpperCase()}',
//         );
//       } else {
//         print('⚠️ Ride in terminal state: $incomingStatus');
//       }

//       state = RideWSState(status: incomingStatus, message: incomingMsg);
//     } catch (e) {
//       _handleError('❌ Decode error: $e');
//     }
//   }

//   Future<void> sendAction(String action) async {
//     if (_channel == null) {
//       print('⚠️ WebSocket not connected yet.');
//       return;
//     }

//     try {
//       final msg = jsonEncode({'action': action});
//       _channel!.sink.add(msg);
//       print('✅ Sent action "$action" for ride #$rideId');
//     } catch (e) {
//       print('❌ Failed to send action: $e');
//     }
//   }

//   @override
//   void dispose() {
//     _channel?.sink.close();
//     print('🛑 WS disposed for ride $rideId');
//     super.dispose();
//   }
// }

// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  RideWSState({
    required this.status,
    this.chatMessages = const [],
    this.myUserId,
    this.historyLoaded = false,
  });

  RideWSState copyWith({
    String? status,
    List<ChatMessage>? chatMessages,
    bool? historyLoaded,
  }) {
    return RideWSState(
      status: status ?? this.status,
      chatMessages: chatMessages ?? this.chatMessages,
      myUserId: myUserId,
      historyLoaded: historyLoaded ?? this.historyLoaded,
    );
  }
}

/// ───────────────── CONTROLLER ─────────────────
class RideWSController extends StateNotifier<RideWSState> {
  final Ref ref;
  final int rideId;

  WebSocketChannel? _channel;
  bool _reconnecting = false;

  RideWSController(this.ref, this.rideId)
      : super(
          RideWSState(
            status: 'pending',
            myUserId: ref.read(authNotifierProvider).user?.userId.toString(),
          ),
        ) {
    _connect();
  }

  bool get isConnected => _channel != null;

  /// ─────────────── CONNECT ───────────────
  void _connect() {
    final userId = state.myUserId;
    if (userId == null) return;

    final uri = Uri.parse(
      'wss://hopeir.onrender.com/ws/ride/$rideId/?user_id=$userId',
    );

    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen(
      _onMessage,
      onDone: _reconnect,
      onError: (_) => _reconnect(),
    );
  }

  void _reconnect() {
    if (_reconnecting) return;
    _reconnecting = true;

    _channel = null;

    Future.delayed(const Duration(seconds: 2), () {
      _reconnecting = false;
      _connect();
    });
  }

  /// ─────────────── RECEIVE ───────────────
  void _onMessage(dynamic raw) {
    try {
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
          // handled elsewhere if needed
          break;
      }
    } catch (_) {
      // ignore malformed frames
    }
  }

  /// ─────────────── HANDLERS ───────────────
  void _handleConnection(Map<String, dynamic> data) {
    final status = data['status'];
    if (status != null) {
      state = state.copyWith(status: status);
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

    state = state.copyWith(
      chatMessages: messages,
      historyLoaded: true,
    );
  }

  void _handleRideStatus(Map<String, dynamic> data) {
    final status = data['status'];
    if (status == null) return;

    if (!{'completed', 'cancelled'}.contains(status)) {
      LocalNotificationHelper.showNotification(
        '🚘 Ride Update',
        'Ride is now ${status.toUpperCase()}',
      );
    }

    state = state.copyWith(status: status);
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

  /// ─────────────── SEND CHAT ───────────────
  void sendChatMessage(String text) {
    if (!isConnected) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _channel!.sink.add(
      jsonEncode({
        'action': 'chat',
        'message': trimmed,
      }),
    );
  }

  /// ─────────────── RIDE ACTIONS ───────────────
  void sendAction(String action) {
    if (!isConnected) return;

    final normalized = action.toLowerCase();
    if (!{'start', 'end', 'cancel'}.contains(normalized)) return;

    _channel!.sink.add(
      jsonEncode({'action': normalized}),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}
