// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hop_eir/features/requests/data/models/ride_request_model.dart';
// import 'package:hop_eir/features/requests/domain/entities/ride_request.dart';
// import 'package:hop_eir/features/requests/domain/entities/request_controller_args.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/status.dart' as status;

// final passengerRequestWSControllerProvider = StateNotifierProvider.family<
//   PassengerRequestWSController,
//   PassengerRequestWSState,
//   RequestControllerArgs
// >((ref, args) => PassengerRequestWSController(args));

// class PassengerRequestWSController
//     extends StateNotifier<PassengerRequestWSState> {
//   final RequestControllerArgs args;
//   late WebSocketChannel _channel;
//   Timer? _reconnectTimer;

//   PassengerRequestWSController(this.args)
//     : super(PassengerRequestWSState.initial()) {
//     _initWebSocket();
//   }

//   void _initWebSocket() {
//     final uri = Uri.parse(
//       'wss://hopeir.onrender.com/ws/ride-requests/?user_id=${args.userId}',
//     );

//     try {
//       _channel = WebSocketChannel.connect(uri);
//       _channel.stream.listen(
//         _handleMessage,
//         onDone: _scheduleReconnect,
//         onError: (err) {
//           print("❌ WS Error: $err");
//           _scheduleReconnect();
//         },
//         cancelOnError: true,
//       );
//     } catch (e) {
//       print("❌ Failed to connect WS: $e");
//       _scheduleReconnect();
//     }
//   }

//   void _handleMessage(dynamic message) {
//     try {
//       final decoded = jsonDecode(message);
//       final type = decoded['type'];

//       if (type == 'initial_state') {
//         print("ℹ️ Skipping initial_state (list of requests)");
//         return;
//       }

//       final data = decoded['data'];
//       if (data is! Map<String, dynamic>) {
//         print("❌ 'data' is invalid or null → $data");
//         return;
//       }

//       final request = RequestModel.fromJson(data).toEntity();

//       if (type == 'ride_request_created') {
//         state = state.copyWith(newRequest: request);
//       } else if (type == 'ride_request_updated') {
//         state = state.copyWith(updatedRequest: request);
//       }
//     } catch (e) {
//       print("❌ Passenger WS parse error: $e");
//     }
//   }

//   void _scheduleReconnect() {
//     _reconnectTimer?.cancel();
//     _reconnectTimer = Timer(const Duration(seconds: 5), _initWebSocket);
//   }

//   @override
//   void dispose() {
//     _reconnectTimer?.cancel();
//     _channel.sink.close(status.normalClosure);
//     super.dispose();
//   }
// }

// class PassengerRequestWSState {
//   final RideRequest? newRequest;
//   final RideRequest? updatedRequest;

//   const PassengerRequestWSState({this.newRequest, this.updatedRequest});

//   factory PassengerRequestWSState.initial() => const PassengerRequestWSState();

//   PassengerRequestWSState copyWith({
//     RideRequest? newRequest,
//     RideRequest? updatedRequest,
//   }) {
//     return PassengerRequestWSState(
//       newRequest: newRequest ?? this.newRequest,
//       updatedRequest: updatedRequest ?? this.updatedRequest,
//     );
//   }
// }
