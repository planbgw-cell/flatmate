// On-device E2E: signup onboarding 동네 step → 대표 동네 binding on login →
// app-bar change synced via PATCH /auth/location → kept after app restart.
//
//   adb shell pm grant com.flatmate.flatmate_app android.permission.ACCESS_FINE_LOCATION
//   flutter test integration_test/onboarding_primary_location_test.dart \
//     -d <device-id> --dart-define=USE_MOCK_API=false
import 'package:dio/dio.dart';
import 'package:flatmate_app/app/app.dart';
import 'package:flatmate_app/app/config/app_config.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/core/di/injection.dart';
import 'package:flatmate_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_screen.dart';
import 'package:flatmate_app/features/location/domain/models/location_item.dart';
import 'package:flatmate_app/features/location/presentation/providers/location_provider.dart';
import 'package:flatmate_app/features/location/presentation/widgets/location_select_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
  Duration timeout = const Duration(seconds: 25),
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
    final onstage = find
        .byType(Text)
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .whereType<String>()
        .join(' | ');
    final config = GoRouter.of(tester.element(find.byType(Scaffold).first))
        .routerDelegate
        .currentConfiguration;
    debugPrint('[E2E] missing $finder; route=${config.uri} '
        'matches=${config.matches.map((m) => m.matchedLocation).toList()}; '
        'onstage texts: $onstage');
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

Finder _appBarDong(String dong) => find.descendant(
      of: find.byKey(const ValueKey('feed-location-button')),
      matching: find.text(dong),
    );

/// Feed loaded for [location] (FeedListNotifier watches the current dong).
Future<void> _expectFeedFor(
  WidgetTester tester,
  ProviderContainer container,
  LocationItem location,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (container.read(currentLocationProvider).id == location.id &&
        container.read(feedListProvider).hasValue) {
      return;
    }
  }
  throw TestFailure('Feed never loaded for ${location.fullName}');
}

Future<Map<String, dynamic>?> _serverPrimary(Dio dio) async {
  final res = await dio.get<Map<String, dynamic>>(
    '/auth/me',
    options: Options(
      headers: {'Authorization': 'Bearer ${sl<TokenStorage>().accessToken}'},
    ),
  );
  return res.data!['primary_location'] as Map<String, dynamic>?;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실기기 E2E: 가입 온보딩 동네 → 로그인 대표 동네 바인딩 → PATCH 동기화 → 재기동 유지',
      (tester) async {
    await configureDependencies();
    expect(sl<AppConfig>().useMockApi, isFalse,
        reason: 'Run with --dart-define=USE_MOCK_API=false');
    await sl<TokenStorage>().clear();
    final dio = Dio(BaseOptions(baseUrl: AppConfig.devServerBaseUrl));

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final email = 'qa.onb$stamp@example.com';

    await tester.pumpWidget(ProviderScope(child: FlatmateApp()));

    // 1) Signup step 1 (account) → step 2 (GPS 동네) → 가입 완료.
    await _pumpUntil(tester, find.text('회원가입'));
    await _tap(tester, find.text('회원가입'));
    await _pumpUntil(tester, find.text('다음'));
    final form = find.byType(TextFormField);
    await tester.enterText(form.at(0), email);
    await tester.enterText(form.at(1), _password);
    await tester.enterText(form.at(2), _password);
    await tester.enterText(form.at(3), 'QA온보딩${stamp % 10000}');
    await _tap(tester, find.text('다음'));
    await _pumpUntil(tester, find.text('우리 동네를 설정해 주세요'));
    await _tap(tester, find.text('현재 위치로 동네 찾기'));
    final selected = find.byKey(const ValueKey('signup-selected-dong'));
    await _pumpUntil(tester, selected);
    final pickedName = tester.widget<Text>(selected).data!;
    _step('가입 Step2 GPS 동네 인식 → "$pickedName"');
    await _tap(tester, find.text('가입 완료'));
    await _pumpUntil(tester, find.byType(FeedScreen));

    var container = _container(tester);
    final primary = container.read(currentLocationProvider);
    expect(primary.fullName, pickedName);
    expect(_appBarDong(primary.dongName), findsOneWidget);
    final serverAfterSignup = await _serverPrimary(dio);
    expect(serverAfterSignup?['id'].toString(), primary.id);
    await _expectFeedFor(tester, container, primary);
    _step('가입 완료 → 서버 primary_location=${serverAfterSignup?['full_name']} '
        '(id ${primary.id}) · 메인 피드 ${primary.dongName} 로드');

    // 2) Logout → feed dong drifts to a local default → re-login rebinds.
    await _tap(tester, find.text('마이플랫'));
    await _pumpUntil(tester, find.text('로그아웃'));
    await _tap(tester, find.text('로그아웃'));
    await _pumpUntil(tester, find.text('로그인 / 회원가입'));
    container.read(myLocationsProvider.notifier).select(kDefaultLocation);
    expect(container.read(currentLocationProvider).id, kDefaultLocation.id);

    await _tap(tester, find.text('로그인 / 회원가입'));
    await _pumpUntil(tester, find.widgetWithText(FilledButton, '로그인'));
    final loginFields = find.byType(TextFormField);
    await tester.enterText(loginFields.at(0), email);
    await tester.enterText(loginFields.at(1), _password);
    final loginAt = DateTime.now();
    await _tap(tester, find.widgetWithText(FilledButton, '로그인'));
    await _pumpUntil(tester, find.text('로그아웃'));
    final boundIn = DateTime.now().difference(loginAt);
    expect(container.read(currentLocationProvider).id, primary.id);
    await _tap(tester, find.text('홈'));
    await _pumpUntil(tester, _appBarDong(primary.dongName));
    await _expectFeedFor(tester, container, primary);
    _step('로그아웃(로컬 동네 신촌동) → 재로그인 ${boundIn.inMilliseconds}ms 내 '
        '대표 동네 ${primary.dongName} 자동 바인딩 · 피드 로드');

    // 3) App bar → 청룡동 → PATCH /auth/location.
    await _tap(tester, find.byKey(const ValueKey('feed-location-button')));
    await _pumpUntil(tester, find.text('내 동네 설정'));
    await tester.enterText(
      find.descendant(
        of: find.byType(LocationSelectModal),
        matching: find.byType(TextField),
      ),
      '청룡',
    );
    final cheongnyongTile = find.descendant(
      of: find.byType(LocationSelectModal),
      matching: find.text('청룡동'),
    );
    await _pumpUntil(tester, cheongnyongTile);
    await _tap(tester, cheongnyongTile.first);
    await _tap(tester, find.byIcon(Icons.close));
    await _pumpUntil(tester, _appBarDong('청룡동'));
    final cheongnyong = container.read(currentLocationProvider);
    Map<String, dynamic>? serverPrimary;
    for (var i = 0; i < 30 && serverPrimary?['dong'] != '청룡동'; i++) {
      await _pumpFor(tester, const Duration(milliseconds: 300));
      serverPrimary = await _serverPrimary(dio);
    }
    expect(serverPrimary?['id'].toString(), cheongnyong.id);
    _step('앱바 청룡동 선택 → PATCH /auth/location → 서버 대표 동네 '
        '"${serverPrimary?['full_name']}"');

    // 4) "Restart": fresh ProviderScope + router, stored JWT only.
    await tester.pumpWidget(
      ProviderScope(key: UniqueKey(), child: FlatmateApp()),
    );
    // Splash first (waits for /auth/me), then the feed on the 대표 동네.
    await _pumpFor(tester, const Duration(milliseconds: 500));
    await _pumpUntil(tester, _appBarDong('청룡동'));
    container = _container(tester);
    expect(container.read(currentLocationProvider).id, cheongnyong.id);
    await _expectFeedFor(tester, container, cheongnyong);
    _step('앱 재기동(새 ProviderScope) → 토큰 복원 /auth/me → 청룡동 유지 · 피드 로드');

    debugPrint('[E2E] ===== SUMMARY =====\n${_log.join('\n')}');
  });
}
