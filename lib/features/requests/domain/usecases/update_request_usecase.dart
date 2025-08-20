import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class UpdateRequestStatusUseCase {
  final WebSocketChannel channel;

  UpdateRequestStatusUseCase(this.channel);

  void call({required int requestId, required String status}) {
    final payload = jsonEncode({
      "type": "update_request_status",
      "request_id": requestId,
      "status": status,
    });

    channel.sink.add(payload);
  }
}
