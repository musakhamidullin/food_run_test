import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:web_socket_channel/web_socket_channel.dart';

class WsClient {
  WebSocketChannel? _ch;
  String? _currentUrl;

  void Function()? onDisconnected;

  final _incoming = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  bool get isConnected => _ch != null;

  Future<void> connect(String url) async {
    if (_ch != null && _currentUrl == url) return;

    if (_ch != null && _currentUrl != url) {
      await disconnect();
    }

    _currentUrl = url;
    _ch = WebSocketChannel.connect(Uri.parse(url));

    _ch!.stream.listen(
      (raw) {
        try {
          final map = jsonDecode(raw as String) as Map<String, dynamic>;
          _incoming.add(map);
        } on Exception catch (e) {
          log('ws_client: parse error: $e');
        }
      },
      onDone: () {
        _ch = null;
        onDisconnected?.call();
      },
      onError: (_) {
        _ch = null;
        onDisconnected?.call();
      },
      cancelOnError: false,
    );
  }

  Future<void> disconnect() async {
    final ch = _ch;
    _ch = null;
    _currentUrl = null;
    await ch?.sink.close();
  }
}
