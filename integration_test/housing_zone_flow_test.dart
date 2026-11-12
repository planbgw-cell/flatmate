// On-device E2E (guest, 기본 동네 신촌동 = 서울): 홈 [부동산/주거]가 동네 권역
// (`location_id + public_scope=zone`)을 조회 — 서버와 같은 순서, 서울·경기·인천
// 공고, 좌표 없는 서울 광역 공고 카드·상세 ([공고 사이트 이동]만), 경기도 단지
// (GG_HOUSING) 상세 ([지도에서 보기]만), [가까운순]은 좌표 없는 공고가 맨 뒤.
//
//   adb install -r -g build\app\outputs\flutter-apk\app-debug.apk
//   flutter test integration_test/housing_zone_flow_test.dart \
//     -d <device-id> --dart-define=USE_MOCK_API=false
import 'package:dio/dio.dart';
import 'package:flatmate_app/app/app.dart';
import 'package:flatmate_app/app/config/app_config.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/core/di/injection.dart';
import 'package:flatmate_app/core/utils/external_url.dart';
import 'package:flatmate_app/features/feed/domain/models/region.dart';
import 'package:flatmate_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_detail_screen.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_screen.dart';
import 'package:flatmate_app/features/location/presentation/providers/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      await _pumpFor(tester, const Duration(milliseconds: 800));
      return;
    }
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> _pumpUntilTrue(
  WidgetTester tester,
  bool Function() condition,
  String what, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) return;
  }
  throw TestFailure('Timed out waiting for $what');
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
}

String _textOf(WidgetTester tester, Finder finder) =>
    tester.widget<Text>(finder).data ?? '';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실기기 E2E: 홈 [부동산/주거] 권역 조회 (신촌=서울)', (tester) async {
    await configureDependencies();
    expect(sl<AppConfig>().useMockApi, isFalse,
        reason: 'Run with --dart-define=USE_MOCK_API=false');
    await sl<TokenStorage>().clear();

    final launched = <Uri>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          externalUrlLauncherProvider.overrideWithValue((uri) async {
            launched.add(uri);
            return true;
          }),
        ],
        child: FlatmateApp(),
      ),
    );
    await _pumpUntil(tester, find.text('로그인 없이 둘러보기'));
    await _tap(tester, find.text('로그인 없이 둘러보기'));
    await _pumpUntil(tester, find.byType(FeedScreen));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(FeedScreen)));
    final origin = container.read(currentLocationProvider);
    final dong = (await container.read(serverDongProvider.future))!;
    expect(dong.cityName, '서울특별시');
    final dongId = int.parse(dong.id);
    _step('게스트 동네 ${origin.dongName} → 서버 동네 id $dongId (${dong.cityName} '
        '${dong.districtName} ${dong.dongName})');

    final dio = Dio(BaseOptions(baseUrl: AppConfig.devServerBaseUrl));
    Future<List<Map<String, dynamic>>> serverZone(String sort) async {
      final rows = <Map<String, dynamic>>[];
      for (var page = 1;; page++) {
        final response = await dio.get<Map<String, dynamic>>(
          '/feeds',
          queryParameters: {
            'feed_type': 'REAL_ESTATE',
            'location_id': dongId,
            'public_scope': 'zone',
            'lat': origin.latitude,
            'lng': origin.longitude,
            'sort': sort,
            'page': page,
            'limit': 10,
          },
        );
        final items = (response.data!['items'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        rows.addAll(items);
        if (items.length < 10) return rows;
      }
    }

    List<String> ids(List<Map<String, dynamic>> rows) =>
        rows.map((e) => e['id'].toString()).toList();

    final latest = await serverZone('latest');
    expect(latest.length, greaterThan(10));
    final list = find.descendant(
      of: find.byType(FeedScreen),
      matching: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    );

    List<String> appIds() =>
        container.read(feedListProvider).value?.items.map((e) => e.id).toList() ??
        const [];

    Future<void> loadAll(int expected) async {
      final deadline = DateTime.now().add(const Duration(seconds: 90));
      while (DateTime.now().isBefore(deadline)) {
        final state = container.read(feedListProvider).value;
        if (state != null && !state.hasMore && !state.isLoadingMore) break;
        if (list.evaluate().isNotEmpty) {
          await tester.drag(list.first, const Offset(0, -1200));
        }
        await _pumpFor(tester, const Duration(milliseconds: 400));
      }
      expect(appIds().length, expected);
    }

    Future<void> scrollToCard(String id) async {
      tester.state<ScrollableState>(list.first).position.jumpTo(0);
      await _pumpFor(tester, const Duration(milliseconds: 300));
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('feed-thumb-$id')),
        300,
        scrollable: list.first,
        maxScrolls: 200,
      );
      await _pumpFor(tester, const Duration(milliseconds: 500));
    }

    Future<void> backToFeed() async {
      GoRouter.of(tester.element(find.byType(FeedDetailScreen))).pop();
      await _pumpUntilTrue(
        tester,
        () => find.byType(FeedDetailScreen).evaluate().isEmpty,
        'back to feed',
      );
      await _pumpFor(tester, const Duration(milliseconds: 500));
    }

    // 1) [부동산/주거]: first page = server zone (latest), with the caption.
    await _tap(tester, find.text('부동산/주거').first);
    final firstPage = ids(latest).take(10).toList();
    await _pumpUntilTrue(
      tester,
      () => _listEquals(appIds(), firstPage),
      'zone first page',
    );
    expect(appIds(), firstPage);
    final caption = find.byKey(const ValueKey('feed-zone-caption'));
    expect(_textOf(tester, caption), '수도권(서울·인천·경기) 공공 주거 공고를 함께 보여드려요');
    _step('[부동산/주거] 첫 페이지 10건 = 서버 location_id=$dongId&public_scope=zone '
        '(전체 ${latest.length}건) · 안내 "${_textOf(tester, caption)}"');

    // 2) Whole zone: 서울 · 경기 · 인천.
    await loadAll(latest.length);
    expect(appIds(), ids(latest));
    final items = container.read(feedListProvider).value!.items;
    final bySido = <String, int>{};
    for (final item in items) {
      final sido = sidoShortName(item.address?.split(' ').first) ?? '?';
      bySido[sido] = (bySido[sido] ?? 0) + 1;
    }
    expect(bySido.keys, containsAll(['서울', '경기', '인천']));
    _step('전체 ${items.length}건 로드 (서버와 같은 순서) · 시·도별 $bySido');

    // 3) 서울 광역 (no coordinates): card → detail → 공고 사이트 이동.
    final seoul = items.firstWhere(
      (e) => e.address == '서울특별시' && e.latitude == null,
    );
    final seoulNotice = seoul.publicNotice!;
    await scrollToCard(seoul.id);
    expect(_textOf(tester, find.byKey(ValueKey('feed-region-${seoul.id}'))),
        '서울특별시');
    expect(
      find.descendant(
        of: find.byKey(ValueKey('feed-source-${seoul.id}')),
        matching: find.text('출처: LH 마이홈'),
      ),
      findsOneWidget,
    );
    expect(_textOf(tester, find.byKey(ValueKey('feed-rent-${seoul.id}'))),
        seoulNotice.rentSummary);
    _step('서울 광역 카드 ${seoul.id} "${seoul.displayTitle}": "서울특별시" · '
        '"출처: LH 마이홈" · "${seoulNotice.rentSummary}"');

    await _tap(tester, find.byKey(ValueKey('feed-thumb-${seoul.id}')));
    await _pumpUntil(tester, find.byType(FeedDetailScreen));
    expect(find.byKey(const ValueKey('detail-map-cta')), findsNothing);
    expect(find.text('지도에서 보기'), findsNothing);
    await _tap(tester, find.byKey(const ValueKey('detail-apply-cta')));
    await _pumpUntilTrue(tester, () => launched.isNotEmpty, 'apply launch');
    expect(launched.single.toString(), seoulNotice.applyUrl);
    _step('상세: [지도에서 보기] 없음 · [공고 사이트 이동] → ${launched.single}');
    await backToFeed();

    // 4) 경기도 단지 (GG_HOUSING, no apply_url): detail rows, map CTA only.
    final gg = items.firstWhere((e) => e.sourceName == '경기도');
    final ggNotice = gg.publicNotice!;
    await scrollToCard(gg.id);
    final ggRegion =
        _textOf(tester, find.byKey(ValueKey('feed-region-${gg.id}')));
    expect(ggRegion, regionLabel(gg.address));
    expect(_textOf(tester, find.byKey(ValueKey('feed-rent-${gg.id}'))),
        ggNotice.rentSummary);
    await _tap(tester, find.byKey(ValueKey('feed-thumb-${gg.id}')));
    await _pumpUntil(tester, find.byType(FeedDetailScreen));
    expect(find.text('경기도 · 공공데이터'), findsOneWidget);
    for (final label in ['입주 대상', '공급세대']) {
      expect(find.byKey(ValueKey('housing-row-$label')), findsOneWidget,
          reason: label);
    }
    expect(find.byKey(const ValueKey('detail-apply-cta')), findsNothing);
    expect(find.text('공고 사이트 이동'), findsNothing);
    expect(find.byKey(const ValueKey('detail-map-cta')), findsOneWidget);
    _step('경기도 단지 ${gg.id} "${gg.displayTitle}": 카드 "$ggRegion" · '
        '"${ggNotice.rentSummary}" → 상세 입주 대상 ${ggNotice.target} · '
        '공급세대 ${ggNotice.households} · [공고 사이트 이동] 없음 · [지도에서 보기]');
    await backToFeed();

    // 5) [가까운순]: server sort=distance, coordless notices last.
    final nearest = await serverZone('distance');
    tester.state<ScrollableState>(list.first).position.jumpTo(0);
    await _tap(tester, find.byKey(const ValueKey('feed-sort-distance')));
    final nearestFirst = ids(nearest).take(10).toList();
    await _pumpUntilTrue(
      tester,
      () => _listEquals(appIds(), nearestFirst),
      'distance first page',
    );
    await loadAll(nearest.length);
    expect(appIds(), ids(nearest));
    final sorted = container.read(feedListProvider).value!.items;
    final firstCoordless = sorted.indexWhere((e) => e.latitude == null);
    expect(firstCoordless, greaterThan(0));
    expect(
      sorted.skip(firstCoordless).every((e) => e.latitude == null),
      isTrue,
      reason: 'coordless notices at the end',
    );
    final closest = sorted.first;
    _step('[가까운순] ${sorted.length}건 = 서버 sort=distance · 가장 가까운 '
        '${closest.id} ${noticeRegionLabel(closest.address)} · 좌표 없는 공고 '
        '${sorted.length - firstCoordless}건 맨 뒤');

    debugPrint('[E2E] ===== SUMMARY =====\n${_log.join('\n')}');
  });
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
