import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flatmate_app/core/auth/token_refresher.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/features/chat/data/datasources/chat_websocket_client.dart';
import 'package:flatmate_app/features/chat/domain/repositories/chat_socket.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const _api = 'http://121.133.47.161:8000/api/v1';

class _FakeSink implements WebSocketSink {
  _FakeSink(this._channel);
  final _FakeChannel _channel;

  @override
  void add(dynamic data) => _channel.sent.add(data);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    if (!_channel.incoming.isClosed) await _channel.incoming.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeChannel implements WebSocketChannel {
  _FakeChannel(this.uri);

  final Uri uri;
  final incoming = StreamController<dynamic>();
  final sent = <dynamic>[];
  int? _closeCode;

  void server(Map<String, dynamic> event) => incoming.add(jsonEncode(event));

  Future<void> serverClose(int code) {
    _closeCode = code;
    return incoming.close();
  }

  @override
  Stream<dynamic> get stream => incoming.stream;

  @override
  late final WebSocketSink sink = _FakeSink(this);

  @override
  int? get closeCode => _closeCode;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RefreshAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return ResponseBody.fromString(
      jsonEncode({
        'access_token': 'jwt-new',
        'refresh_token': 'refresh-xyz',
        'expires_in': 3600,
        'refresh_expires_in': 1209600,
        'user': {'id': 7},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<void> _flush() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late TokenStorage tokens;
  late _RefreshAdapter refreshAdapter;
  late List<_FakeChannel> channels;
  late ChatWebSocketClient client;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    tokens = TokenStorage();
    await tokens.save(
      accessToken: 'jwt-abc',
      refreshToken: 'refresh-xyz',
      userId: '7',
      expiresIn: const Duration(hours: 1),
      refreshExpiresIn: const Duration(days: 14),
    );
    refreshAdapter = _RefreshAdapter();
    final refresher = TokenRefresher(tokens: tokens, baseUrl: _api)
      ..dio.httpClientAdapter = refreshAdapter;
    channels = [];
    client = ChatWebSocketClient(
      roomId: '5',
      apiBaseUrl: _api,
      tokens: tokens,
      refresher: refresher,
      connector: (uri) {
        final channel = _FakeChannel(uri);
        channels.add(channel);
        return channel;
      },
    );
  });

  tearDown(() => client.dispose());

  test('socket URL follows /chats/ws/{room_id}?token=', () {
    expect(
      ChatWebSocketClient.socketUri(_api, '5', 'jwt').toString(),
      'ws://121.133.47.161:8000/api/v1/chats/ws/5?token=jwt',
    );
  });

  test('connected → message/read events; sends JSON frames', () async {
    final events = <ChatSocketEvent>[];
    client.events.listen(events.add);
    await client.connect();
    expect(client.status.value, ChatSocketStatus.connecting);
    expect(client.sendMessage('too early'), isFalse);

    final channel = channels.single;
    expect(channel.uri.queryParameters['token'], 'jwt-abc');
    channel.server({'type': 'connected', 'room_id': 5, 'user_id': 7});
    await _flush();
    expect(client.status.value, ChatSocketStatus.connected);

    expect(client.sendMessage('안녕하세요'), isTrue);
    expect(client.sendRead(), isTrue);
    expect(channel.sent.map((e) => jsonDecode(e as String)), [
      {'type': 'message', 'content': '안녕하세요'},
      {'type': 'read'},
    ]);

    channel
      ..server({
        'type': 'message',
        'message': {
          'id': 1,
          'room_id': 5,
          'sender_id': 7,
          'content': '안녕하세요',
          'created_at': '2026-10-18T03:00:00Z',
          'read_at': null,
          'is_read': false,
        },
      })
      ..server({
        'type': 'read',
        'room_id': 5,
        'reader_id': 1,
        'updated': 1,
        'read_at': '2026-10-18T03:00:05Z',
      });
    await _flush();

    final message = (events[0] as ChatSocketMessage).message;
    expect(message.isMine, isTrue);
    expect(message.message, '안녕하세요');
    final read = events[1] as ChatSocketRead;
    expect(read.readerId, '1');
    expect(read.updated, 1);
  });

  test('close 4401 refreshes the JWT and reconnects with the new token',
      () async {
    await client.connect();
    channels.single.server({'type': 'connected', 'room_id': 5, 'user_id': 7});
    await _flush();

    await channels.single.serverClose(ChatWebSocketClient.invalidTokenCloseCode);
    await Future<void>.delayed(const Duration(milliseconds: 700));

    expect(refreshAdapter.calls, 1);
    expect(channels, hasLength(2));
    expect(channels.last.uri.queryParameters['token'], 'jwt-new');
  });

  test('disconnect stops reconnecting', () async {
    await client.connect();
    await client.disconnect();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    expect(channels, hasLength(1));
    expect(client.status.value, ChatSocketStatus.disconnected);
  });
}
