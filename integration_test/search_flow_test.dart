// On-device E2E: 돋보기 → "디지털피아노" 검색 (server GET /feeds?q=) → result
// card → re-enter shows 최근 검색 → no-match keyword → X / 전체 삭제.
//
//   adb install -r -g build\app\outputs\flutter-apk\app-debug.apk
//   flutter test integration_test/search_flow_test.dart \
//     -d <device-id> --dart-define=USE_MOCK_API=false
import 'package:dio/dio.dart';
import 'package:flatmate_app/app/app.dart';
import 'package:flatmate_app/app/config/app_config.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/core/di/injection.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_detail_screen.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_screen.dart';
import 'package:flatmate_app/features/location/presentation/providers/location_provider.dart';
import 'package:flatmate_app/features/search/data/search_history_repository.dart';
import 'package:flatmate_app/features/search/presentation/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _password = 'Flatmate123!';
const _keyword = '디지털피아노';

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

Finder _inSearch(Finder finder) =>
    find.descendant(of: find.byType(SearchScreen), matching: finder);

Future<void> _search(WidgetTester tester, String keyword) async {
  final field = find.byKey(const ValueKey('search-field'));
  await tester.enterText(field, keyword);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _openSearch(WidgetTester tester) async {
  await _tap(tester, find.byKey(const ValueKey('feed-search-button')));
  await _pumpUntil(tester, find.byType(SearchScreen));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실기기 E2E: 검색 → 결과 → 최근 검색어 → 개별/전체 삭제', (tester) async {
    await configureDependencies();
    expect(sl<AppConfig>().useMockApi, isFalse,
        reason: 'Run with --dart-define=USE_MOCK_API=false');
    final tokens = sl<TokenStorage>();
    await tokens.clear();
    await sl<SharedPreferences>().remove(SearchHistoryRepository.storageKey);

    final stamp = DateTime.now().millisecondsSinceEpoch;
    await tester.pumpWidget(ProviderScope(child: FlatmateApp()));

    // Sign up (GPS dong).
    await _pumpUntil(tester, find.text('회원가입'));
    await _tap(tester, find.text('회원가입'));
    await _pumpUntil(tester, find.text('다음'));
    final form = find.byType(TextFormField);
    await tester.enterText(form.at(0), 'qa.search$stamp@example.com');
    await tester.enterText(form.at(1), _password);
    await tester.enterText(form.at(2), _password);
    await tester.enterText(form.at(3), 'QA검색${stamp % 10000}');
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

    // A 디지털피아노 post in this dong (server had none).
    final dio = Dio(BaseOptions(baseUrl: AppConfig.devServerBaseUrl));
    final auth =
        Options(headers: {'Authorization': 'Bearer ${tokens.accessToken}'});
    final title = '[SEARCH $stamp] $_keyword 팝니다';
    final created = await dio.post<Map<String, dynamic>>(
      '/feeds',
      options: auth,
      data: {
        'feed_type': 'GENERAL',
        'title': title,
        'content': '88건반, 거의 새것이에요.',
        'lat': here.latitude,
        'lng': here.longitude,
        'address': here.fullName,
        'image_urls': const <String>[],
        'extra_meta': {'price': 150000, 'is_free': false, 'can_negotiate': true},
      },
    );
    final feedId = created.data!['id'].toString();
    _step('가입 · ${here.dongName}에 "$title" 작성 (피드 $feedId)');

    // 1) 돋보기 → dong hint → 디지털피아노 → results match the server.
    await _openSearch(tester);
    expect(find.text('${here.dongName} 근처에서 검색'), findsOneWidget);
    expect(find.text('최근 검색어가 없습니다.'), findsOneWidget);
    await _search(tester, _keyword);
    await _pumpUntil(tester, _inSearch(find.textContaining(title)));
    final server = await dio.get<Map<String, dynamic>>(
      '/feeds',
      queryParameters: {
        'q': _keyword,
        'lat': here.latitude,
        'lng': here.longitude,
        'radius_m': 3000,
        'limit': 20,
      },
      options: auth,
    );
    final serverIds = [
      for (final e in server.data!['items'] as List) (e as Map)['id'].toString(),
    ];
    expect(serverIds, contains(feedId));
    _step('돋보기 → 힌트 "${here.dongName} 근처에서 검색" → "$_keyword" 검색 → '
        '결과 카드 노출 (서버 GET /feeds?q= ${serverIds.length}건)');

    // 2) Result card → detail → back to the results.
    await _tap(tester, _inSearch(find.textContaining(title)));
    await _pumpUntil(tester, find.byType(FeedDetailScreen));
    expect(find.textContaining(title), findsWidgets);
    await _tap(tester, find.byIcon(Icons.arrow_back_rounded));
    await _pumpUntilGone(tester, find.byType(FeedDetailScreen));
    await _pumpUntil(tester, _inSearch(find.textContaining(title)));
    _step('결과 카드 → 상세 → 뒤로 (결과 유지)');

    // 3) Leave and re-enter: 최근 검색 shows 디지털피아노.
    await _tap(tester, find.byType(BackButton));
    await _pumpUntilGone(tester, find.byType(SearchScreen));
    await _openSearch(tester);
    await _pumpUntil(tester, find.byKey(const ValueKey('recent-search-$_keyword')));
    expect(find.text('최근 검색'), findsOneWidget);
    _step('뒤로가기 후 재진입 → 최근 검색 "$_keyword" 노출');

    // 4) No-match keyword.
    final missing = '없는검색어$stamp';
    await _search(tester, missing);
    await _pumpUntil(tester, find.text('검색 결과가 없습니다.'));
    _step('"$missing" → "검색 결과가 없습니다."');

    // 5) X then 전체 삭제.
    await _tap(tester, find.byKey(const ValueKey('search-clear-text')));
    await _pumpUntil(tester, find.byKey(ValueKey('recent-search-$missing')));
    expect(find.byKey(const ValueKey('recent-search-$_keyword')), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('recent-remove-$_keyword')));
    await _pumpUntilGone(
      tester,
      find.byKey(const ValueKey('recent-search-$_keyword')),
    );
    expect(find.byKey(ValueKey('recent-search-$missing')), findsOneWidget);
    _step('[X] "$_keyword" 개별 삭제 → 1개 남음');

    await _tap(tester, find.byKey(const ValueKey('search-clear-all')));
    await _pumpUntil(tester, find.byKey(const ValueKey('confirm-clear-search')));
    await _tap(tester, find.byKey(const ValueKey('confirm-clear-search')));
    await _pumpUntil(tester, find.text('최근 검색어가 없습니다.'));
    expect(
      sl<SharedPreferences>().getStringList(SearchHistoryRepository.storageKey),
      isNull,
    );
    _step('[전체 삭제] → 확인 → "최근 검색어가 없습니다." · 로컬 저장소 비움');

    await dio.delete<dynamic>('/feeds/$feedId', options: auth);
    debugPrint('[E2E] ===== SUMMARY =====\n${_log.join('\n')}');
  });
}
