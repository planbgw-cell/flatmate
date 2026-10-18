// On-device E2E: WebSocket chat, read receipts, refresh-token rotation.
//
//   flutter test integration_test/realtime_chat_flow_test.dart \
//     -d <device-id> --dart-define=USE_MOCK_API=false
//
// The second participant (QA seller) runs inside the test over its own
// WebSocket, so the phone UI is account A and the socket is account B.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flatmate_app/app/app.dart';
import 'package:flatmate_app/app/config/app_config.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/core/di/injection.dart';
import 'package:flatmate_app/features/chat/data/datasources/chat_websocket_client.dart';
import 'package:flatmate_app/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:flatmate_app/features/location/presentation/widgets/location_select_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const _sellerEmail = 'qa.seller@example.com';
const _sellerNickname = 'QAseller';
const _password = 'Flatmate123!';
const _sellerPost = '정자동 테스트 원룸';

final _log = <String>[];

void _step(String message) {
  _log.add(message);
  debugPrint('[E2E] $message');
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<Duration> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  bool settle = true,
}) async {
  final start = DateTime.now();
  final deadline = start.add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      final took = DateTime.now().difference(start);
      // Let route transitions finish; taps are ignored mid-animation.
      if (settle) await _pumpFor(tester, const Duration(milliseconds: 800));
      return took;
    }
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  final scaffolds = find.byType(Scaffold);
  if (scaffolds.evaluate().isNotEmpty) {
    ScaffoldMessenger.of(tester.element(scaffolds.last)).clearSnackBars();
    await _pumpFor(tester, const Duration(milliseconds: 300));
  }
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
}

/// Second participant: REST + its own WebSocket, no UI.
class _Peer {
  _Peer(this.dio, this.token);

  final Dio dio;
  final String token;
  final events = <Map<String, dynamic>>[];
  WebSocketChannel? _channel;

  Options get _auth => Options(headers: {'Authorization': 'Bearer $token'});

  Future<void> connect(String roomId) async {
    final channel = WebSocketChannel.connect(
      ChatWebSocketClient.socketUri(AppConfig.devServerBaseUrl, roomId, token),
    );
    _channel = channel;
    channel.stream.listen(
      (raw) => events.add(jsonDecode(raw as String) as Map<String, dynamic>),
    );
    await _waitFor((e) => e['type'] == 'connected');
  }

  void send(Map<String, dynamic> frame) =>
      _channel!.sink.add(jsonEncode(frame));

  Future<Map<String, dynamic>> _waitFor(
    bool Function(Map<String, dynamic> e) test, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final hit = events.where(test).firstOrNull;
      if (hit != null) return hit;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    throw TestFailure('Peer never received matching event: $events');
  }

  Future<Map<String, dynamic>> waitFor(
    bool Function(Map<String, dynamic> e) test,
  ) =>
      _waitFor(test);

  Future<void> sendRest(String roomId, String content) => dio.post<dynamic>(
        '/chats/rooms/$roomId/messages',
        data: {'content': content},
        options: _auth,
      );

  Future<void> close() async => _channel?.sink.close();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실서버 E2E: WebSocket 실시간 채팅·읽음·토큰 자동갱신·채팅 목록',
      (tester) async {
    await configureDependencies();
    expect(sl<AppConfig>().useMockApi, isFalse,
        reason: 'Run with --dart-define=USE_MOCK_API=false');
    final tokens = sl<TokenStorage>();
    await tokens.clear();

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final email = 'qa.rt$stamp@example.com';
    final nickname = 'QA실시간${stamp % 10000}';

    await tester.pumpWidget(ProviderScope(child: FlatmateApp()));

    // Account A: sign up on the phone (auto login → access + refresh token).
    await _pumpUntil(tester, find.text('회원가입'));
    await _tap(tester, find.text('회원가입'));
    await _pumpUntil(tester, find.text('가입하고 시작하기'));
    final form = find.byType(TextFormField);
    await tester.enterText(form.at(0), email);
    await tester.enterText(form.at(1), _password);
    await tester.enterText(form.at(2), _password);
    await tester.enterText(form.at(3), nickname);
    await _tap(tester, find.text('가입하고 시작하기'));
    await _pumpUntil(tester, find.text('글쓰기'));
    expect(tokens.accessToken, startsWith('eyJ'));
    expect(tokens.refreshToken, startsWith('eyJ'));
    final persisted = TokenStorage();
    await persisted.load();
    expect(persisted.refreshToken, tokens.refreshToken);
    final myId = tokens.userId!;
    _step('A($nickname, id=$myId) 가입·로그인 → access/refresh 토큰 보안저장소 저장');

    // Account B (seller) over REST + WebSocket.
    final dio = Dio(BaseOptions(baseUrl: AppConfig.devServerBaseUrl));
    final login = await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': _sellerEmail, 'password': _password},
    );
    final peer = _Peer(dio, login.data!['access_token'] as String);
    _step('B($_sellerNickname) 로그인');

    // Open the seller's post → chat room (A's socket connects on entry).
    await _tap(tester, find.byKey(const ValueKey('feed-location-button')));
    await _pumpUntil(tester, find.text('내 동네 설정'));
    await tester.enterText(
      find.descendant(
        of: find.byType(LocationSelectModal),
        matching: find.byType(TextField),
      ),
      '정자',
    );
    await _pumpUntil(tester, find.text('성남시 분당구 정자동'));
    await _tap(tester, find.text('성남시 분당구 정자동'));
    await _tap(tester, find.byIcon(Icons.close));
    await _pumpUntil(tester, find.textContaining(_sellerPost));
    await _tap(tester, find.textContaining(_sellerPost));
    await _pumpUntil(tester, find.text('채팅으로 문의하기'));
    await _tap(tester, find.text('채팅으로 문의하기'));
    await _pumpUntil(tester, find.byType(ChatRoomScreen));
    await _pumpUntil(tester, find.text('실시간 연결됨'));
    final roomId =
        tester.widget<ChatRoomScreen>(find.byType(ChatRoomScreen)).roomId;
    expect(find.text(_sellerNickname), findsWidgets);
    await peer.connect(roomId);
    _step('채팅방 room=$roomId · A/B 모두 WebSocket connected');

    // A → B in realtime.
    final outgoing = '[RT $stamp] 안녕하세요, 아직 거래 가능한가요?';
    await tester.enterText(
      find.descendant(
        of: find.byType(ChatRoomScreen),
        matching: find.byType(TextField),
      ),
      outgoing,
    );
    await tester.pump();
    final sentAt = DateTime.now();
    await _tap(tester, find.byIcon(Icons.send_rounded));
    final atPeer = await peer.waitFor(
      (e) => e['type'] == 'message' && e['message']['content'] == outgoing,
    );
    final aToB = DateTime.now().difference(sentAt);
    expect(atPeer['message']['sender_id'].toString(), myId);
    await _pumpUntil(tester, find.text(outgoing), settle: false);
    _step('A→B 소켓 전송 · B 수신 ${aToB.inMilliseconds}ms · A 화면 echo 반영');

    // B reads → "읽음" appears on A's bubble.
    expect(find.text('읽음'), findsNothing);
    peer.send({'type': 'read'});
    final readTook = await _pumpUntil(tester, find.text('읽음'), settle: false);
    _step('B 읽음 이벤트 → A 말풍선 "읽음" 표시 ${readTook.inMilliseconds}ms');

    // B → A in realtime; A auto-acknowledges with a read event.
    final incoming = '[RT $stamp] 네! 오늘 저녁에 보실 수 있어요.';
    final peerReadsBefore = peer.events
        .where((e) => e['type'] == 'read' && '${e['reader_id']}' == myId)
        .length;
    peer.send({'type': 'message', 'content': incoming});
    final bToA = await _pumpUntil(tester, find.text(incoming), settle: false);
    await peer.waitFor(
      (e) =>
          e['type'] == 'read' &&
          '${e['reader_id']}' == myId &&
          peer.events
                  .where((x) => x['type'] == 'read' && '${x['reader_id']}' == myId)
                  .length >
              peerReadsBefore,
    );
    _step('B→A 소켓 전송 · A 화면 ${bToA.inMilliseconds}ms 반영 (폴링 없음) · A 자동 읽음 → B 수신');

    // Leave the room → socket disconnects (provider autoDispose).
    await _tap(tester, find.byIcon(Icons.arrow_back));
    await _pumpUntil(tester, find.text('채팅으로 문의하기'));
    await _tap(tester, find.byIcon(Icons.arrow_back_rounded));
    await _pumpUntil(tester, find.text('글쓰기'));

    // Access token "expires": REST 401 → /auth/refresh → retry.
    final beforeRest = tokens.accessToken;
    tokens.debugCorruptAccessToken();
    await _tap(tester, find.text('채팅').first);
    await _pumpUntil(tester, find.text(_sellerNickname));
    expect(tokens.accessToken, isNot(beforeRest));
    expect(tokens.accessToken, startsWith('eyJ'));
    expect(tokens.hasSession, isTrue);
    _step('Access 토큰 만료 흉내 → GET /chats/rooms 401 → refresh → 재시도 성공(목록 표시)');

    // Chat list: peer nickname · unread badge · last message, no extra calls.
    final unread1 = '[RT $stamp] 혹시 주차도 되나요?';
    final unread2 = '[RT $stamp] 답장 기다릴게요 🙏';
    await peer.sendRest(roomId, unread1);
    await peer.sendRest(roomId, unread2);
    await tester.fling(
      find.byType(ListView).last,
      const Offset(0, 400),
      1200,
    );
    await _pumpUntil(tester, find.text(unread2));
    final tile = find.ancestor(
      of: find.text(unread2),
      matching: find.byType(InkWell),
    );
    expect(
      find.descendant(of: tile.first, matching: find.text(_sellerNickname)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tile.first, matching: find.text('2')),
      findsOneWidget,
    );
    _step('채팅 목록: 상대 닉네임 "$_sellerNickname" · 안 읽음 뱃지 2 · 마지막 메시지 표시');

    // WebSocket with an "expired" token: close 4401 → refresh → reconnect.
    final beforeWs = tokens.accessToken;
    tokens.debugCorruptAccessToken();
    await _tap(tester, find.text(unread2));
    await _pumpUntil(tester, find.byType(ChatRoomScreen));
    await _pumpUntil(tester, find.text('실시간 연결됨'));
    expect(tokens.accessToken, isNot(beforeWs));
    expect(tokens.accessToken, startsWith('eyJ'));
    await _pumpUntil(tester, find.text(unread2));
    _step('Access 토큰 만료 흉내 → WS close 4401 → refresh → 재연결 성공');

    // Entering the room marked B's messages read → badge clears.
    await _tap(tester, find.byIcon(Icons.arrow_back));
    await tester.fling(
      find.byType(ListView).last,
      const Offset(0, 400),
      1200,
    );
    await _pumpFor(tester, const Duration(seconds: 2));
    final tileAfter = find.ancestor(
      of: find.text(unread2),
      matching: find.byType(InkWell),
    );
    expect(
      find.descendant(of: tileAfter.first, matching: find.text('2')),
      findsNothing,
    );
    _step('채팅방 재입장 → 읽음 처리 → 목록 뱃지 해제');

    await peer.close();
    debugPrint('[E2E] ===== SUMMARY =====\n${_log.join('\n')}');
  });
}
