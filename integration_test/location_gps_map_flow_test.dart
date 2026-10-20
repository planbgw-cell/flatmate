// On-device E2E: GPS → reverse-geo dong, and map-center dong picking.
//
// Location permission must be granted beforehand (the system dialog cannot be
// tapped from a Flutter test):
//   adb shell pm grant com.flatmate.flatmate_app android.permission.ACCESS_FINE_LOCATION
//   flutter test integration_test/location_gps_map_flow_test.dart \
//     -d <device-id> --dart-define=USE_MOCK_API=false
import 'package:dio/dio.dart';
import 'package:flatmate_app/app/app.dart';
import 'package:flatmate_app/app/config/app_config.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/core/di/injection.dart';
import 'package:flatmate_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_screen.dart';
import 'package:flatmate_app/features/location/data/datasources/location_service.dart';
import 'package:flatmate_app/features/location/presentation/providers/location_provider.dart';
import 'package:flatmate_app/features/location/presentation/screens/location_map_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 25),
  String what = 'condition',
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) {
      // Let route transitions finish; taps are ignored mid-animation.
      await _pumpFor(tester, const Duration(milliseconds: 800));
      return;
    }
  }
  throw TestFailure('Timed out waiting for $what');
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) =>
    _pumpUntil(
      tester,
      () => finder.evaluate().isNotEmpty,
      what: finder.toString(),
    );

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

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(FeedScreen)));

String _cardText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('map-picker-dong'))).data!;

bool _cardResolved() =>
    find.byKey(const ValueKey('map-picker-dong')).evaluate().isNotEmpty &&
    find.text('위치 확인 중…').evaluate().isEmpty;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실기기 E2E: GPS 동 자동 설정 → 지도에서 동 선택', (tester) async {
    await configureDependencies();
    expect(sl<AppConfig>().useMockApi, isFalse,
        reason: 'Run with --dart-define=USE_MOCK_API=false');
    await sl<TokenStorage>().clear();

    await tester.pumpWidget(ProviderScope(child: FlatmateApp()));
    await _pumpUntilFound(tester, find.text('로그인 없이 둘러보기'));
    await _tap(tester, find.text('로그인 없이 둘러보기'));
    await _pumpUntilFound(tester, find.byType(FeedScreen));
    final container = _container(tester);
    final before = container.read(currentLocationProvider);
    _step('시작 동네: ${before.fullName}');

    // 1) [현재 위치로 동 찾기] → GPS → reverse-geo → current dong.
    await _tap(tester, find.byKey(const ValueKey('feed-location-button')));
    await _pumpUntilFound(tester, find.text('현재 위치로 동 찾기'));
    await _tap(tester, find.text('현재 위치로 동 찾기'));
    await _pumpUntil(
      tester,
      () => find.text('내 동네 설정').evaluate().isEmpty,
      what: 'modal closed after GPS lookup',
    );
    final gpsDong = container.read(currentLocationProvider);
    expect(gpsDong.id, isNot(before.id));
    expect(gpsDong.regionCode, isNotNull);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('feed-location-button')),
        matching: find.text(gpsDong.dongName),
      ),
      findsOneWidget,
    );

    // Cross-check: same device fix → server reverse-geo gives the same dong.
    final fix = await LocationService().currentPosition();
    expect(fix.isGranted, isTrue);
    final dio = Dio(BaseOptions(baseUrl: AppConfig.devServerBaseUrl));
    final direct = await dio.get<Map<String, dynamic>>(
      '/locations/reverse-geo',
      queryParameters: {'lat': fix.latitude, 'lng': fix.longitude},
    );
    final serverDong = direct.data!['location'] as Map<String, dynamic>;
    expect(serverDong['full_name'], gpsDong.fullName);
    await _pumpUntil(
      tester,
      () => container.read(feedListProvider).hasValue,
      what: 'feed reload',
    );
    _step('GPS (${fix.latitude!.toStringAsFixed(5)}, '
        '${fix.longitude!.toStringAsFixed(5)}) → ${gpsDong.fullName} '
        '(region ${gpsDong.regionCode}, source=${direct.data!['source']}) · '
        '앱바·피드 반영');

    // 2) [지도에서 위치 선택] → drag → center dong → apply.
    await _tap(tester, find.byKey(const ValueKey('feed-location-button')));
    await _pumpUntilFound(tester, find.text('지도에서 위치 선택'));
    await _tap(tester, find.text('지도에서 위치 선택'));
    await _pumpUntilFound(tester, find.byType(LocationMapPickerScreen));
    await _pumpUntil(tester, _cardResolved, what: 'initial center resolved');
    final initialCard = _cardText(tester);
    expect(initialCard, gpsDong.fullName);
    _step('지도 진입 · 중앙 핀 기준 "$initialCard" 표시');

    var picked = initialCard;
    for (var attempt = 0; attempt < 4 && picked == initialCard; attempt++) {
      await tester.drag(find.byType(FlutterMap), const Offset(0, 420));
      await tester.pump();
      await _pumpUntil(tester, _cardResolved, what: 'center resolved after drag');
      picked = _cardText(tester);
      _step('지도 드래그 ${attempt + 1}회 → "$picked"');
    }
    expect(picked, isNot(initialCard));

    await _tap(tester, find.text('이 위치로 동 설정하기'));
    await _pumpUntilFound(tester, find.byType(FeedScreen));
    await _pumpUntil(
      tester,
      () => find.byType(LocationMapPickerScreen).evaluate().isEmpty,
      what: 'picker popped',
    );
    final mapDong = container.read(currentLocationProvider);
    expect(mapDong.fullName, picked);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('feed-location-button')),
        matching: find.text(mapDong.dongName),
      ),
      findsOneWidget,
    );
    await _pumpUntil(
      tester,
      () => container.read(feedListProvider).hasValue,
      what: 'feed reload',
    );
    _step('[이 위치로 동 설정하기] → ${mapDong.fullName} 저장 · 메인 피드 복귀·리로드');

    debugPrint('[E2E] ===== SUMMARY =====\n${_log.join('\n')}');
  });
}
