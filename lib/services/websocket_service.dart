import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  late WebSocketChannel _channel;

  Function(dynamic data)? onMessage;

  void connect() {
    _channel = WebSocketChannel.connect(Uri.parse("ws://192.168.1.4:5001/ws"));

    _channel.stream.listen(
          (message) {
        print("📩 $message");

        final decoded = jsonDecode(message);
        onMessage?.call(decoded);
      },
      onError: (error) {
        print("❌ Error: $error");
      },
      onDone: () {
        print("🔌 Disconnected");
      },
    );
  }

  void send(Map<String, dynamic> data) {
    _channel.sink.add(jsonEncode(data));
  }

  void disconnect() {
    _channel.sink.close();
  }
}