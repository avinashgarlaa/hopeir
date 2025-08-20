// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../data/models/ride_request_model.dart';
import '../../domain/entities/ride_request.dart';
import '../../../notifications/notification_service.dart';

final rideRequestWSControllerProvider = StateNotifierProvider.family<
  RideRequestWSController,
  RideRequestWSState,
  String
>((ref, userId) => RideRequestWSController(userId));

class RideRequestWSController extends StateNotifier<RideRequestWSState> {
  final String userId;
  late WebSocketChannel _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  bool _initialStateHandled = false;

  RideRequestWSController(this.userId) : super(RideRequestWSState.initial()) {
    _connect();
  }

  void _connect() {
    final uri = Uri.parse(
      'wss://hopeir.onrender.com/ws/ride-requests/?user_id=$userId',
    );

    try {
      state = state.copyWith(
        status:
            _reconnectAttempts > 0
                ? ConnectionStatus.reconnecting
                : ConnectionStatus.connecting,
      );

      _channel = WebSocketChannel.connect(uri);
      _subscription = _channel.stream.listen(
        _handleMessage,
        onDone: _scheduleReconnect,
        onError: (error) {
          _handleError("WebSocket error: $error");
          _scheduleReconnect();
        },
      );

      state = state.copyWith(status: ConnectionStatus.connected, error: null);
      _reconnectAttempts = 0;
    } catch (e) {
      _handleError("Connection failed: $e");
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      print("📩 Raw WebSocket message: $message");
      final json = jsonDecode(message);
      final type = json['type'];
      final data = json['data'];

      if (type == null || data == null) {
        print('⏭ Skipping malformed message');
        return;
      }

      switch (type) {
        case 'connection':
          print('🔗 Connection established');
          break;

        case 'initial_state':
          final initial =
              (data as List)
                  .map((e) => RideRequestModel.fromJson(e).toEntity())
                  .toList();

          print('📥 Initial requests loaded: ${initial.length}');

          // Compare with old state
          final oldIds = state.incomingRequests.map((r) => r.id).toSet();
          final currentIds = initial.map((r) => r.id).toSet();
          final newOnes = initial.where((r) => !oldIds.contains(r.id)).toList();

          print("🟡 Old Request IDs: $oldIds");
          print("🟢 Current Request IDs: $currentIds");

          if (_initialStateHandled) {
            for (final r in newOnes) {
              print(
                "🔔 Showing Notification → 📥 New Ride Request: From: ${r.passengerName}",
              );
              LocalNotificationHelper.showNotification(
                "📥 New Ride Request",
                "From: ${r.passengerName}",
              );
            }
          } else {
            print(
              "🛑 Skipping notifications for first-time initial_state sync",
            );
            _initialStateHandled = true;
          }

          state = state.copyWith(
            incomingRequests: initial,
            lastUpdated: DateTime.now(),
            hasUnread:
                newOnes.isNotEmpty
                    ? true
                    : state.hasUnread, // ✅ set to true if new
          );
          break;

        case 'ride_request_created':
          final newRequest = RideRequestModel.fromJson(data).toEntity();
          state = state.copyWith(
            incomingRequests: [...state.incomingRequests, newRequest],
            lastUpdated: DateTime.now(),
            hasUnread: true, // ✅ set unread
          );
          print(
            "🔔 Showing Notification → 📥 New Ride Request: From: ${newRequest.passengerName}",
          );
          LocalNotificationHelper.showNotification(
            "📥 New Ride Request",
            "From: ${newRequest.passengerName}",
          );
          break;

        case 'ride_request_updated':
          final updated = RideRequestModel.fromJson(data).toEntity();
          final updatedList =
              state.incomingRequests.map((r) {
                return r.id == updated.id ? updated : r;
              }).toList();

          state = state.copyWith(
            incomingRequests: updatedList,
            lastUpdated: DateTime.now(),
          );

          print(
            "🔔 Showing Notification → ✅ Ride Request Updated: ${updated.status.toUpperCase()}",
          );
          LocalNotificationHelper.showNotification(
            "✅ Ride Request Updated",
            "Status: ${updated.status.toUpperCase()}",
          );
          break;

        default:
          print("❓ Unknown WebSocket type: $type");
      }
    } catch (e, stack) {
      _handleError("❌ Message processing failed: $e", stack);
    }
  }

  Future<void> respondToRequest({
    required String requestId,
    required bool isAccepted,
  }) async {
    try {
      if (state.status != ConnectionStatus.connected) {
        throw Exception("No active WebSocket connection.");
      }

      _channel.sink.add(
        jsonEncode({
          'action': isAccepted ? 'accept' : 'reject',
          'request_id': requestId,
        }),
      );

      // Optimistic update
      final updatedList =
          state.incomingRequests.map((r) {
            if (r.id == requestId) {
              final newStatus = isAccepted ? 'accepted' : 'rejected';

              // 🔔 Send local notification here

              LocalNotificationHelper.showNotification(
                isAccepted
                    ? "✅ Ride Request Accepted"
                    : "❌ Ride Request Rejected",
                "Request from ${r.passengerName} has been ${newStatus.toUpperCase()}",
              );

              return r.copyWith(status: newStatus);
            } else {
              return r;
            }
          }).toList();

      state = state.copyWith(
        incomingRequests: updatedList,
        lastUpdated: DateTime.now(),
      );
    } catch (e, stack) {
      _handleError("Failed to send response: $e", stack);
    }
  }

  void _handleError(String message, [StackTrace? stack]) {
    print('$message\n${stack ?? StackTrace.current}');
    state = state.copyWith(
      status: ConnectionStatus.disconnected,
      error: message,
    );
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      state = state.copyWith(error: "Max reconnection attempts reached.");
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final delay = Duration(seconds: min(_reconnectAttempts * 2, 10));

    print("🔁 Reconnecting in ${delay.inSeconds}s...");
    _reconnectTimer = Timer(delay, _connect);
  }

  // Instantly add a new request (e.g., when user creates a ride request).
  void addMyRequest(RideRequest request) {
    final alreadyExists = state.incomingRequests.any((r) => r.id == request.id);
    if (alreadyExists) return;

    state = state.copyWith(
      incomingRequests: [...state.incomingRequests, request],
      lastUpdated: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _reconnectTimer?.cancel();
    _channel.sink.close(status.normalClosure);
    super.dispose();
  }
}

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
  final bool hasUnread; // NEW

  RideRequestWSState({
    required this.status,
    required this.incomingRequests,
    this.error,
    this.lastUpdated,
    this.hasUnread = false, // default
  });

  factory RideRequestWSState.initial() => RideRequestWSState(
    status: ConnectionStatus.initial,
    incomingRequests: [],
    hasUnread: false,
  );

  RideRequestWSState copyWith({
    ConnectionStatus? status,
    List<RideRequest>? incomingRequests,
    String? error,
    DateTime? lastUpdated,
    bool? hasUnread, // NEW
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
  bool get hasError => error != null;
}
