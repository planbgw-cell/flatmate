// On-device E2E against the FastAPI dev server.
//
//   flutter test integration_test/real_server_flow_test.dart \
//     -d <device-id> --dart-define=USE_MOCK_API=false
//
// Requires the QA seller account and its seeded posts (정자동 / 청룡동).
import 'package:dio/dio.dart';
import 'package:flatmate_app/app/app.dart';
import 'package:flatmate_app/app/config/app_config.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/core/di/injection.dart';
import 'package:flatmate_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:flatmate_app/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:flatmate_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_screen.dart';
import 'package:flatmate_app/features/location/presentation/widgets/location_select_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _sellerEmail = 'qa.seller@example.com';
const _password = 'Flatmate123!';
const _sellerJeongjaPost = '정자동 테스트 원룸';
const _sellerSnuPost = '서울대입구역 도보 5분 원룸';

final _log = <String>[];

void _step(String message) {
  _log.add(message);
  debugPrint('[E2E] $message');
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) {
      // Let route transitions finish; taps are ignored mid-animation.
      await _pumpFor(tester, const Duration(milliseconds: 800));
      return;
    }
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _clearSnackBars(WidgetTester tester) async {
  final scaffolds = find.byType(Scaffold);
  if (scaffolds.evaluate().isEmpty) return;
  ScaffoldMessenger.of(tester.element(scaffolds.last)).clearSnackBars();
  await _pumpFor(tester, const Duration(milliseconds: 400));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _clearSnackBars(tester);
  // Soft keyboard shrinks lazy lists; close it and scroll the target in.
  FocusManager.instance.primaryFocus?.unfocus();
  await _pumpFor(tester, const Duration(milliseconds: 400));
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).hitTestable().first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(FeedScreen)));

Future<void> _selectDong(
  WidgetTester tester, {
  required String query,
  required String fullName,
}) async {
  await _tap(tester, find.byKey(const ValueKey('feed-location-button')));
  await _pumpUntil(tester, find.text('내 동네 설정'));
  final field = find.descendant(
    of: find.byType(LocationSelectModal),
    matching: find.byType(TextField),
  );
  await tester.enterText(field, query);
  await _pumpUntil(tester, find.text(fullName));
  await _tap(tester, find.text(fullName));
  await _tap(tester, find.byIcon(Icons.close));
  await _pumpFor(tester, const Duration(milliseconds: 600));
}

Future<void> _createPost(
  WidgetTester tester, {
  required String menu,
  required List<String> fields,
}) async {
  await _tap(tester, find.text('글쓰기'));
  await _pumpUntil(tester, find.text('무엇을 올릴까요?'));
  await _tap(tester, find.text(menu));
  await _pumpUntil(tester, find.text('완료'));
  final inputs = find.byType(TextField);
  for (var i = 0; i < fields.length; i++) {
    await tester.enterText(inputs.at(i), fields[i]);
    await tester.pump();
  }
  await _tap(tester, find.text('완료'));
  await _pumpUntil(tester, find.text('게시글이 등록되었습니다.'));
  await _pumpUntil(tester, find.textContaining(fields.first));
}

Dio _rawDio() => Dio(BaseOptions(baseUrl: AppConfig.devServerBaseUrl));

Future<String> _loginRaw(Dio dio, String email) async {
  final res = await dio.post<Map<String, dynamic>>(
    '/auth/login',
    data: {'email': email, 'password': _password},
  );
  return res.data!['access_token'] as String;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실서버 E2E: 가입→로그인→동네→게시글 3종→채팅', (tester) async {
    await configureDependencies();
    expect(sl<AppConfig>().useMockApi, isFalse,
        reason: 'Run with --dart-define=USE_MOCK_API=false');
    await sl<TokenStorage>().clear();

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final email = 'qa.device$stamp@example.com';
    final nickname = 'QA폰${stamp % 100000}';
    _step('server=${sl<AppConfig>().apiBaseUrl}, account=$email');

    await tester.pumpWidget(ProviderScope(child: FlatmateApp()));

    // 1) Splash → Login → Sign up (auto login).
    await _pumpUntil(tester, find.text('회원가입'));
    _step('splash → 로그인 화면 진입');
    await _tap(tester, find.text('회원가입'));
    await _pumpUntil(tester, find.text('다음'));
    final form = find.byType(TextFormField);
    await tester.enterText(form.at(0), email);
    await tester.enterText(form.at(1), _password);
    await tester.enterText(form.at(2), _password);
    await tester.enterText(form.at(3), nickname);
    await _tap(tester, find.text('다음'));
    await _pumpUntil(tester, find.text('현재 위치로 동네 찾기'));
    await _tap(tester, find.text('현재 위치로 동네 찾기'));
    await _pumpUntil(
      tester,
      find.byKey(const ValueKey('signup-selected-dong')),
    );
    await _tap(tester, find.text('가입 완료'));
    await _pumpUntil(tester, find.text('글쓰기'));

    final tokens = sl<TokenStorage>();
    expect(tokens.accessToken, startsWith('eyJ'));
    final persisted = TokenStorage();
    await persisted.load();
    expect(persisted.accessToken, tokens.accessToken);
    final me = await sl<AuthRepository>().getMe();
    expect(me.email, email);
    _step('회원가입+로그인 OK · JWT 보안저장소 저장 확인 · /auth/me id=${me.id}');

    // 2) 동네: 정자동 → seller post visible.
    await _selectDong(tester, query: '정자', fullName: '성남시 분당구 정자동');
    await _pumpUntil(tester, find.textContaining(_sellerJeongjaPost));
    _step('정자동 선택 → 반경 3km 피드에 "$_sellerJeongjaPost" 노출');

    // 3) 동네: 청룡동(서울대입구역) → only nearby posts.
    await _selectDong(tester, query: '청룡', fullName: '관악구 청룡동');
    await _pumpUntil(tester, find.textContaining(_sellerSnuPost));
    expect(find.textContaining(_sellerJeongjaPost), findsNothing);
    _step('청룡동(서울대입구역) 선택 → "$_sellerSnuPost"만 노출, 정자동 글 제외');

    // Back to 정자동 for posting + chat.
    await _selectDong(tester, query: '정자', fullName: '성남시 분당구 정자동');
    await _pumpUntil(tester, find.textContaining(_sellerJeongjaPost));

    // 4) 게시글 3종 등록 → top of feed + DB row.
    final dio = _rawDio();
    final created = <String>[];
    Future<void> verifyTop(String title, String feedType) async {
      final items = _container(tester).read(feedListProvider).value!.items;
      expect(items.first.title, title);
      final res = await dio.get<Map<String, dynamic>>('/feeds/${items.first.id}');
      expect(res.data!['feed_type'], feedType);
      expect(res.data!['author_id'].toString(), me.id);
      created.add('${items.first.id}:$feedType');
    }

    final housingTitle = '[QA $stamp] 정자동 풀옵션 원룸';
    await _createPost(
      tester,
      menu: '부동산 / 주거 등록',
      fields: [housingTitle, '실서버 통합 테스트 매물입니다.', '500', '60'],
    );
    await verifyTop(housingTitle, 'REAL_ESTATE');

    final jobTitle = '[QA $stamp] 정자역 주말 알바';
    await _createPost(
      tester,
      menu: '알바 공고 등록',
      fields: [jobTitle, '토·일 오전 근무, 실서버 테스트.', '11000'],
    );
    await verifyTop(jobTitle, 'JOB');

    final generalTitle = '[QA $stamp] 미니 선풍기 나눔';
    await _createPost(
      tester,
      menu: '일반글 작성',
      fields: [generalTitle, '실서버 일반글 테스트.', '5000'],
    );
    await verifyTop(generalTitle, 'GENERAL');
    _step('부동산/알바/일반 등록 → DB 삽입 + 피드 최상단 노출 (${created.join(', ')})');

    // 5) 상세 → 채팅으로 문의하기 → 1:1 room → send / receive.
    await _tap(tester, find.text('부동산/주거'));
    await _pumpUntil(tester, find.textContaining(_sellerJeongjaPost));
    await _tap(tester, find.textContaining(_sellerJeongjaPost));
    await _pumpUntil(tester, find.text('채팅으로 문의하기'));
    await _tap(tester, find.text('채팅으로 문의하기'));
    await _pumpUntil(tester, find.byType(ChatRoomScreen));
    await _pumpUntil(
      tester,
      find.descendant(
        of: find.byType(ChatRoomScreen),
        matching: find.textContaining(_sellerJeongjaPost),
      ),
    );

    final outgoing = '[QA $stamp] 안녕하세요, 원룸 아직 있나요?';
    await tester.enterText(
      find.descendant(
        of: find.byType(ChatRoomScreen),
        matching: find.byType(TextField),
      ),
      outgoing,
    );
    await tester.pump();
    await _tap(tester, find.byIcon(Icons.send_rounded));
    await _pumpUntil(tester, find.text(outgoing));

    final sellerToken = await _loginRaw(dio, _sellerEmail);
    final auth = Options(headers: {'Authorization': 'Bearer $sellerToken'});
    final rooms = (await dio.get<List<dynamic>>('/chats/rooms', options: auth))
        .data!
        .cast<Map<String, dynamic>>();
    final room = rooms.firstWhere(
      (r) =>
          r['feed_id'] == 1 &&
          (r['user_a_id'].toString() == me.id ||
              r['user_b_id'].toString() == me.id),
    );
    final roomId = room['id'];
    final thread = (await dio.get<List<dynamic>>(
      '/chats/rooms/$roomId/messages',
      options: auth,
    ))
        .data!;
    expect(thread.any((m) => m['content'] == outgoing), isTrue);
    _step('채팅방 생성(room=$roomId) · 기기→서버 메시지 수신 확인');

    final reply = '[QA $stamp] 네, 아직 있어요! 언제 보실래요?';
    await dio.post<dynamic>(
      '/chats/rooms/$roomId/messages',
      data: {'content': reply},
      options: auth,
    );
    await _pumpUntil(
      tester,
      find.text(reply),
      timeout: const Duration(seconds: 15),
    );
    _step('판매자 답장 → 기기 채팅방 폴링 수신 확인');

    debugPrint('[E2E] ===== SUMMARY =====\n${_log.join('\n')}');
  });
}
