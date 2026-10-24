// On-device E2E: 하단 탭 5개 전환 → 동네소식 FAB 글쓰기 (LOCAL_NEWS) →
// 내주변 지도 (동네 중심 · 서버와 같은 마커) → 마커 탭 → 카드 맨 앞 → 상세 →
// 지도 드래그 → 이 위치에서 재검색 → 내 동네로.
//
//   adb install -r -g build\app\outputs\flutter-apk\app-debug.apk
//   flutter test integration_test/tabs_community_map_flow_test.dart \
//     -d <device-id> --dart-define=USE_MOCK_API=false
import 'package:dio/dio.dart';
import 'package:flatmate_app/app/app.dart';
import 'package:flatmate_app/app/config/app_config.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/core/di/injection.dart';
import 'package:flatmate_app/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:flatmate_app/features/community/presentation/providers/community_feed_provider.dart';
import 'package:flatmate_app/features/community/presentation/screens/community_screen.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_detail_screen.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_screen.dart';
import 'package:flatmate_app/features/location/presentation/providers/location_provider.dart';
import 'package:flatmate_app/features/map_around/presentation/providers/map_around_provider.dart';
import 'package:flatmate_app/features/map_around/presentation/screens/map_around_screen.dart';
import 'package:flatmate_app/features/mypage/presentation/pages/my_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _password = 'Flatmate123!';

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

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      // Let route transitions finish; taps are ignored mid-animation.
      await _pumpFor(tester, const Duration(milliseconds: 800));
      return;
    }
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> _pumpUntilTrue(
  WidgetTester tester,
  bool Function() condition,
  String what,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) return;
  }
  throw TestFailure('Timed out waiting for $what');
}

Future<void> _pumpUntilGone(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isEmpty) return;
  }
  throw TestFailure('Still showing $finder');
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  final scaffolds = find.byType(Scaffold);
  if (scaffolds.evaluate().isNotEmpty) {
    ScaffoldMessenger.of(tester.element(scaffolds.last)).clearSnackBars();
    await _pumpFor(tester, const Duration(milliseconds: 300));
  }
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

Future<void> _tab(WidgetTester tester, String key) =>
    _tap(tester, find.byKey(ValueKey(key)));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실기기 E2E: 하단 탭 5개 · 동네소식 글쓰기 · 내주변 지도', (tester) async {
    await configureDependencies();
    expect(sl<AppConfig>().useMockApi, isFalse,
        reason: 'Run with --dart-define=USE_MOCK_API=false');
    final tokens = sl<TokenStorage>();
    await tokens.clear();

    final stamp = DateTime.now().millisecondsSinceEpoch;
    await tester.pumpWidget(ProviderScope(child: FlatmateApp()));

    // Sign up (GPS dong).
    await _pumpUntil(tester, find.text('회원가입'));
    await _tap(tester, find.text('회원가입'));
    await _pumpUntil(tester, find.text('다음'));
    final form = find.byType(TextFormField);
    await tester.enterText(form.at(0), 'qa.tabs$stamp@example.com');
    await tester.enterText(form.at(1), _password);
    await tester.enterText(form.at(2), _password);
    await tester.enterText(form.at(3), 'QA지도${stamp % 10000}');
    await _tap(tester, find.text('다음'));
    await _pumpUntil(tester, find.text('현재 위치로 동네 찾기'));
    for (var attempt = 0; attempt < 2; attempt++) {
      await _tap(tester, find.text('현재 위치로 동네 찾기'));
      try {
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('signup-selected-dong')),
        );
        break;
      } on TestFailure {
        if (attempt == 1) rethrow;
      }
    }
    await _tap(tester, find.text('가입 완료'));
    await _pumpUntil(tester, find.byType(FeedScreen));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(FeedScreen)));
    final here = container.read(currentLocationProvider);

    // 1) Five tabs.
    for (final label in ['홈', '동네소식', '내주변', '채팅', '마이플랫']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    await _tab(tester, 'tab-community');
    await _pumpUntil(tester, find.byType(CommunityScreen));
    expect(find.byKey(const ValueKey('write-fab')), findsOneWidget);
    await _tab(tester, 'tab-around');
    await _pumpUntil(tester, find.byType(MapAroundScreen));
    expect(find.byKey(const ValueKey('write-fab')), findsNothing);
    await _tab(tester, 'tab-chat');
    await _pumpUntil(tester, find.byType(ChatListScreen));
    await _tab(tester, 'tab-my');
    await _pumpUntil(tester, find.byType(MyPage));
    expect(find.byKey(const ValueKey('menu-notices')), findsOneWidget);
    await _tab(tester, 'tab-home');
    await _pumpUntil(tester, find.byType(FeedScreen));
    _step('하단 탭 5개 전환: 홈 · 동네소식 · 내주변 · 채팅 · 마이플랫 (FAB는 홈·동네소식만)');

    // 2) 동네소식 FAB → 동네소식 쓰기 → list + server LOCAL_NEWS.
    final dio = Dio(BaseOptions(baseUrl: AppConfig.devServerBaseUrl));
    final auth =
        Options(headers: {'Authorization': 'Bearer ${tokens.accessToken}'});
    final newsTitle = '[NEWS $stamp] 야탑역 앞 붕어빵 트럭 왔어요';
    await _tab(tester, 'tab-community');
    await _pumpUntil(tester, find.byType(CommunityScreen));
    await _tap(tester, find.byKey(const ValueKey('write-fab')));
    await _pumpUntil(tester, find.text('동네소식 쓰기'));
    await tester.enterText(find.byKey(const ValueKey('post-title')), newsTitle);
    await tester.enterText(
      find.byKey(const ValueKey('post-body')),
      '저녁 6시부터 9시까지 있어요.',
    );
    await _tap(tester, find.text('완료'));
    await _pumpUntil(tester, find.text('게시글이 등록되었습니다.'));
    await _pumpUntil(
      tester,
      find.descendant(
        of: find.byType(CommunityScreen),
        matching: find.textContaining(newsTitle),
      ),
    );
    final news = container
        .read(communityFeedProvider)
        .value!
        .items
        .firstWhere((e) => e.title == newsTitle);
    final newsOnServer = await dio.get<Map<String, dynamic>>(
      '/feeds/${news.id}',
      options: auth,
    );
    expect(newsOnServer.data!['feed_type'], 'LOCAL_NEWS');
    _step('동네소식 FAB → "동네소식 쓰기" 등록 → 목록 노출 · 서버 feed_type=LOCAL_NEWS (피드 ${news.id})');

    // 3) A post ~1 km north of the dong center (its own marker).
    final postTitle = '[MAP $stamp] 접이식 자전거 팝니다';
    final created = await dio.post<Map<String, dynamic>>(
      '/feeds',
      options: auth,
      data: {
        'feed_type': 'GENERAL',
        'title': postTitle,
        'content': '20인치, 거의 새것.',
        'lat': here.latitude + 0.009,
        'lng': here.longitude,
        'address': here.fullName,
        'image_urls': const <String>[],
        'extra_meta': {'price': 80000, 'is_free': false, 'can_negotiate': false},
      },
    );
    final postId = created.data!['id'].toString();

    // 4) 내주변: dong-centered map, same posts as the server.
    await _tab(tester, 'tab-around');
    await _pumpUntil(tester, find.byType(MapAroundScreen));
    await _tap(tester, find.byKey(const ValueKey('map-recenter')));
    await _pumpUntil(tester, find.byKey(ValueKey('map-marker-$postId')));
    var around = container.read(mapAroundProvider).value!;
    expect(around.centerLat, here.latitude);
    expect(around.centerLng, here.longitude);
    final server = await dio.get<Map<String, dynamic>>(
      '/feeds',
      queryParameters: {
        'lat': here.latitude,
        'lng': here.longitude,
        'radius_m': 3000,
        'limit': 100,
        'sort': 'latest',
      },
      options: auth,
    );
    final serverIds = {
      for (final e in server.data!['items'] as List)
        if ((e as Map)['lat'] != null) e['id'].toString(),
    };
    final appIds = {for (final item in around.items) item.id};
    expect(appIds, serverIds);
    expect(appIds, contains(postId));
    _step('내주변: 중심 ${here.dongName} (${here.latitude.toStringAsFixed(4)}, '
        '${here.longitude.toStringAsFixed(4)}) · 마커 ${around.groups.length}개 · '
        '글 ${appIds.length}건 = 서버 GET /feeds radius_m=3000');

    // 5) Marker → its card first & selected → detail.
    await _tap(
      tester,
      find.descendant(
        of: find.byKey(ValueKey('map-marker-$postId')),
        matching: find.text('80,000원'),
      ),
    );
    await _pumpUntilTrue(
      tester,
      () => container.read(mapAroundProvider).value?.selectedId == postId,
      'marker selection',
    );
    around = container.read(mapAroundProvider).value!;
    expect(around.items.first.id, postId);
    await _pumpUntil(tester, find.byKey(ValueKey('map-card-$postId')));
    await _tap(tester, find.byKey(ValueKey('map-card-$postId')));
    await _pumpUntil(tester, find.byType(FeedDetailScreen));
    expect(find.textContaining(postTitle), findsWidgets);
    await _tap(tester, find.byIcon(Icons.arrow_back_rounded));
    await _pumpUntilGone(tester, find.byType(FeedDetailScreen));
    _step('마커 탭 → "$postTitle" 카드 맨 앞·선택 → 카드 탭 → 상세 → 뒤로');

    // 6) Drag → 이 위치에서 재검색 → 내 동네로.
    await tester.drag(
      find.byKey(const ValueKey('map-around')),
      const Offset(-300, 250),
    );
    await _pumpFor(tester, const Duration(seconds: 2));
    await _pumpUntil(tester, find.byKey(const ValueKey('map-research')));
    await _tap(tester, find.byKey(const ValueKey('map-research')));
    await _pumpUntilTrue(
      tester,
      () => container.read(mapAroundProvider).value?.centerLat != here.latitude,
      're-search center',
    );
    final moved = container.read(mapAroundProvider).value!;
    _step('지도 드래그 → [이 위치에서 재검색] → 중심 '
        '(${moved.centerLat.toStringAsFixed(4)}, ${moved.centerLng.toStringAsFixed(4)}) '
        '재조회 · 글 ${moved.items.length}건');

    await _tap(tester, find.byKey(const ValueKey('map-recenter')));
    await _pumpUntilTrue(
      tester,
      () => container.read(mapAroundProvider).value?.centerLat == here.latitude,
      'recenter',
    );
    await _pumpUntil(tester, find.byKey(ValueKey('map-marker-$postId')));
    _step('[내 동네로] → 동네 중심으로 재조회');

    await dio.delete<dynamic>('/feeds/$postId', options: auth);
    await dio.delete<dynamic>('/feeds/${news.id}', options: auth);
    debugPrint('[E2E] ===== SUMMARY =====\n${_log.join('\n')}');
  });
}
