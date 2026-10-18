import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/auth/token_refresher.dart';
import '../../../../core/auth/token_storage.dart';
import '../../domain/repositories/chat_socket.dart';
import '../mappers/chat_mapper.dart';

typedef WebSocketConnector = WebSocketChannel Function(Uri uri);

/// `ws://…/api/v1/chats/ws/{room_id}?token={access_token}` client.
///
/// Server → client: `connected` · `message` · `read` · `error`.
/// Client → server: `{"type":"message","content"}` · `{"type":"read"}`.
/// Reconnects with backoff while open; close code 4401 refreshes the JWT first.
class ChatWebSocketClient implements ChatSocket {
  ChatWebSocketClient({
    required this.roomId,
    required this._apiBaseUrl,
    required this._tokens,
    required this._refresher,
    WebSocketConnector? connector,
  }) : _connector = connector ?? WebSocketChannel.connect;

  static const invalidTokenCloseCode = 4401;
  static const _maxBackoff = Duration(seconds: 10);

  final String roomId;
  final String _apiBaseUrl;
  final TokenStorage _tokens;
  final TokenRefresher _refresher;
  final WebSocketConnector _connector;

  final _events = StreamController<ChatSocketEvent>.broadcast();
  final _status = ValueNotifier(ChatSocketStatus.disconnected);

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  String? _tokenInUse;
  Timer? _retryTimer;
  int _attempt = 0;
  bool _closedByUser = false;

  @override
  ValueListenable<ChatSocketStatus> get status => _status;

  @override
  Stream<ChatSocketEvent> get events => _events.stream;

  static Uri socketUri(String apiBaseUrl, String roomId, String token) {
    final base = Uri.parse(apiBaseUrl);
    return base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '${base.path}/chats/ws/$roomId',
      queryParameters: {'token': token},
    );
  }

  @override
  Future<void> connect() async {
    _closedByUser = false;
    await _open();
  }

  Future<void> _open() async {
    if (_closedByUser || _channel != null) return;
    _status.value = ChatSocketStatus.connecting;
    if (!_tokens.isAccessTokenFresh) await _refresher.refresh();
    final token = _tokens.accessToken;
    if (token == null || _closedByUser) {
      _status.value = ChatSocketStatus.disconnected;
      return;
    }
    _tokenInUse = token;
    final channel = _connector(socketUri(_apiBaseUrl, roomId, token));
    _channel = channel;
    _subscription = channel.stream.listen(
      _onData,
      onError: (Object _) {},
      onDone: () => _onClosed(channel),
    );
  }

  void _onData(dynamic raw) {
    final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(raw as String);
      if (decoded is! Map) return;
      json = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return;
    }
    switch (json['type']) {
      case 'connected':
        _attempt = 0;
        _status.value = ChatSocketStatus.connected;
      case 'message':
        final message = json['message'];
        if (message is Map) {
          _events.add(
            ChatSocketMessage(
              chatMessageFromJson(
                Map<String, dynamic>.from(message),
                myUserId: _tokens.userId,
              ),
            ),
          );
        }
      case 'read':
        _events.add(
          ChatSocketRead(
            readerId: json['reader_id']?.toString() ?? '',
            readAt:
                DateTime.tryParse(json['read_at']?.toString() ?? '')?.toLocal() ??
                    DateTime.now(),
            updated: (json['updated'] as num?)?.toInt() ?? 0,
          ),
        );
      case 'error':
        _events.add(ChatSocketError(json['detail']?.toString() ?? ''));
    }
  }

  Future<void> _onClosed(WebSocketChannel channel) async {
    if (!identical(channel, _channel)) return;
    _channel = null;
    await _subscription?.cancel();
    _subscription = null;
    _status.value = ChatSocketStatus.disconnected;
    if (_closedByUser) return;

    if (channel.closeCode == invalidTokenCloseCode) {
      final refreshed =
          await _refresher.refresh(staleAccessToken: _tokenInUse);
      if (!refreshed) return;
    }
    final backoff = Duration(
      milliseconds: math.min(
        _maxBackoff.inMilliseconds,
        500 * math.pow(2, _attempt).toInt(),
      ),
    );
    _attempt++;
    _retryTimer = Timer(backoff, _open);
  }

  bool _send(Map<String, dynamic> frame) {
    final channel = _channel;
    if (channel == null || _status.value != ChatSocketStatus.connected) {
      return false;
    }
    channel.sink.add(jsonEncode(frame));
    return true;
  }

  @override
  bool sendMessage(String text) => _send({'type': 'message', 'content': text});

  @override
  bool sendRead() => _send({'type': 'read'});

  @override
  Future<void> disconnect() async {
    _closedByUser = true;
    _retryTimer?.cancel();
    _status.value = ChatSocketStatus.disconnected;
    final channel = _channel;
    final subscription = _subscription;
    _channel = null;
    _subscription = null;
    await subscription?.cancel();
    await channel?.sink.close();
  }

  @override
  void dispose() {
    disconnect();
    _events.close();
    _status.dispose();
  }
}
