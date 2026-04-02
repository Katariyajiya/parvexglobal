import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import '../models/tick_data.dart';

typedef TickBatchCallback = void Function(List<TickData> ticks);

class StompService {
  StompService({
    required String wsUrl,
    required String userId,
    required this.onTickBatch,
    required this.onConnectionChanged,
  })  : _wsUrl = wsUrl,
        _userId = userId;

  final String _wsUrl;
  final String _userId;
  final TickBatchCallback onTickBatch;
  final ValueChanged<bool> onConnectionChanged;

  StompClient? _client;

  void connect() {
    _client = StompClient(
      config: StompConfig.SockJS(
        url: _wsUrl,
        onConnect: _onConnect,
        onDisconnect: _onDisconnect,
        onStompError: (f) => debugPrint('STOMP error: ${f.body}'),
        onWebSocketError: (e) => debugPrint('WS error: $e'),
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _client!.activate();
  }

  void disconnect() {
    _client?.deactivate();
  }

  void _onConnect(StompFrame frame) {
    debugPrint('WebSocket connected');
    onConnectionChanged(true);

    _client!.subscribe(
      destination: '/topic/watchlist/$_userId',
      callback: (frame) {
        if (frame.body == null) return;

        final List<dynamic> batch = jsonDecode(frame.body!);
        final ticks = batch
            .map((item) => TickData.fromJson(item as Map<String, dynamic>))
            .toList();

        onTickBatch(ticks);
      },
    );
  }

  void _onDisconnect(StompFrame _) {
    debugPrint('WebSocket disconnected');
    onConnectionChanged(false);
  }
}
