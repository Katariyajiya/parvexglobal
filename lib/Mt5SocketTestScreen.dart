import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Mt5SocketTestScreen extends StatefulWidget {
  const Mt5SocketTestScreen({super.key});

  @override
  State<Mt5SocketTestScreen> createState() => _Mt5SocketTestScreenState();
}

class _Mt5SocketTestScreenState extends State<Mt5SocketTestScreen> {

  final String socketUrl = "ws://13.127.145.152:8000/ws/ticks";

  WebSocketChannel? channel;

  final TextEditingController symbolController =
      TextEditingController(text: "XAUUSD,EURUSD");

  String status = "Disconnected";
  String latestMessage = "No data yet";

  List<String> logs = [];

  void addLog(String msg) {
    final time = TimeOfDay.now().format(context);
    setState(() {
      logs.insert(0, "[$time] $msg");
    });
  }

  void connectSocket() {
    if (channel != null) {
      addLog("Socket already connected");
      return;
    }

    channel = WebSocketChannel.connect(Uri.parse(socketUrl));

    setState(() {
      status = "Connected";
    });

    addLog("Connected to $socketUrl");

    channel!.stream.listen(
      (message) {
        setState(() {
          latestMessage = message.toString();
        });

        addLog("Received: $message");
      },
      onError: (e) {
        setState(() {
          status = "Error";
        });
        addLog("Socket error");
      },
      onDone: () {
        setState(() {
          status = "Disconnected";
          channel = null;
        });
        addLog("Socket disconnected");
      },
    );
  }

  void subscribeSymbols() {
    if (channel == null) {
      addLog("Connect socket first");
      return;
    }

    final raw = symbolController.text.trim();

    final symbols = raw
        .split(",")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final payload = {
      "action": "subscribe",
      "symbols": symbols
    };

    final jsonMsg = jsonEncode(payload);

    channel!.sink.add(jsonMsg);

    addLog("Sent: $jsonMsg");
  }

  void disconnectSocket() {
    channel?.sink.close();
    channel = null;

    setState(() {
      status = "Disconnected";
    });

    addLog("Socket closed");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MT5 WebSocket Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// SYMBOL INPUT
            TextField(
              controller: symbolController,
              decoration: const InputDecoration(
                labelText: "Symbols",
                hintText: "XAUUSD,EURUSD",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            /// BUTTONS
            Row(
              children: [
                ElevatedButton(
                  onPressed: connectSocket,
                  child: const Text("Connect"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: subscribeSymbols,
                  child: const Text("Subscribe"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: disconnectSocket,
                  child: const Text("Disconnect"),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// STATUS
            Text(
              "Status: $status",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            /// LATEST MESSAGE
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(latestMessage),
            ),

            const SizedBox(height: 10),

            /// LOGS
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    return Text(
                      logs[index],
                      style: const TextStyle(fontFamily: 'monospace'),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}