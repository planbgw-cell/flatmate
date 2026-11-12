// On-device E2E (guest): LH 마이홈 공공 주거 공고 — 홈 [부동산/주거] card
// ([공공 혜택] + 유형, 임대 조건, 출처, 유형 placeholder) → detail (출처 카드,
// 공고 정보, no 채팅/차단) → [공고 사이트 이동] (apply_url) → [지도에서 보기].
//
//   adb install -r -g build\app\outputs\flutter-apk\app-debug.apk
//   flutter test integration_test/public_housing_flow_test.dart \
//     -d <device-id> --dart-define=USE_MOCK_API=false
import 'package:dio/dio.dart';
import 'package:flatmate_app/app/app.dart';
import 'package:flatmate_app/app/config/app_config.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/core/di/injection.dart';
import 'package:flatmate_app/core/utils/external_url.dart';
import 'package:flatmate_app/features/feed/data/mappers/feed_item_mapper.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_detail_screen.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_screen.dart';
import 'package:flatmate_app/features/feed/presentation/widgets/feed_visual.dart';
import 'package:flatmate_app/features/location/domain/models/location_item.dart';
import 'package:flatmate_app/features/location/presentation/providers/location_provider.dart';
import 'package:flatmate_app/features/map_around/presentation/providers/map_around_provider.dart';
import 'package:flatmate_app/features/map_around/presentation/screens/map_around_screen.dart';
import 'package:flutter/material.dart';
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
  String what,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실기기 E2E: LH 공공 주거 카드·상세·공고 사이트·지도', (tester) async {
    await configureDependencies();
    expect(sl<AppConfig>().useMockApi, isFalse,
        reason: 'Run with --dart-define=USE_MOCK_API=false');
    await sl<TokenStorage>().clear();

    // A located LH notice with an apply URL and a server dong.
    final dio = Dio(BaseOptions(baseUrl: AppConfig.devServerBaseUrl));
    final response = await dio.get<Map<String, dynamic>>(
      '/feeds',
      queryParameters: {'feed_type': 'REAL_ESTATE', 'limit': 100},
    );
    final row = (response.data!['items'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .firstWhere(
          (e) =>
              e['is_public_data'] == true &&
              e['lat'] != null &&
              e['location_id'] != null &&
              ((e['extra_meta'] as Map?)?['apply_url'] as String?)
                      ?.startsWith('https://') ==
                  true,
        );
    final notice = feedItemFromJson(row);
    final id = notice.id;
    final applyUrl = notice.publicNotice!.applyUrl!;
    expect(notice.isPublicHousing, isTrue);
    expect(notice.thumbnailUrl, isEmpty);
    _step('서버 공고 $id [${notice.housingType!.label}] "${notice.displayTitle}" · '
        '${notice.address} · 이미지 없음');

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
    container.read(currentLocationProvider.notifier).state = LocationItem(
      id: row['location_id'].toString(),
      cityName: '',
      districtName: '',
      dongName: notice.neighborhood,
      latitude: notice.latitude!,
      longitude: notice.longitude!,
    );

    // 1) 홈 [부동산/주거] card.
    await _tap(tester, find.text('부동산/주거').first);
    final badge = find.byKey(ValueKey('public-badge-$id'));
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (badge.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
      await _pumpFor(tester, const Duration(milliseconds: 500));
      final list = find.descendant(
        of: find.byType(FeedScreen),
        matching: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        ),
      );
      if (badge.evaluate().isEmpty && list.evaluate().isNotEmpty) {
        await tester.drag(list.first, const Offset(0, -400));
      }
    }
    expect(badge, findsOneWidget);
    await tester.ensureVisible(find.byKey(ValueKey('feed-thumb-$id')));
    await _pumpFor(tester, const Duration(milliseconds: 500));
    expect(
      find.descendant(
        of: find.byKey(ValueKey('housing-type-$id')),
        matching: find.text(notice.housingType!.label),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(ValueKey('feed-rent-$id'))).data,
      notice.publicNotice!.rentSummary,
    );
    expect(
      find.descendant(
        of: find.byKey(ValueKey('feed-source-$id')),
        matching: find.text('출처: ${notice.sourceName}'),
      ),
      findsOneWidget,
    );
    final placeholder = find.byKey(ValueKey('feed-placeholder-$id'));
    expect(placeholder, findsOneWidget);
    expect(
      find.descendant(of: placeholder, matching: find.byIcon(feedVisual(notice).icon)),
      findsOneWidget,
    );
    _step('홈 [부동산/주거] 카드: [공공 혜택][${notice.housingType!.label}] · '
        '"${notice.publicNotice!.rentSummary}" · "출처: ${notice.sourceName}" · '
        '유형 플레이스홀더');

    // 2) Detail.
    await _tap(tester, find.byKey(ValueKey('feed-thumb-$id')));
    await _pumpUntil(tester, find.byType(FeedDetailScreen));
    expect(find.text('${notice.sourceName} · 공공데이터'), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-housing-badges')), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-card-housing')), findsOneWidget);
    for (final label in ['모집 기간', '당첨자 발표', '문의', '신청']) {
      expect(find.byKey(ValueKey('housing-row-$label')), findsOneWidget,
          reason: label);
    }
    expect(find.text('채팅하기'), findsNothing);
    await _tap(tester, find.byKey(const ValueKey('detail-more')));
    await _pumpUntil(tester, find.byKey(const ValueKey('menu-report')));
    expect(find.byKey(const ValueKey('menu-block')), findsNothing);
    await tester.tapAt(const Offset(20, 200));
    await _pumpFor(tester, const Duration(seconds: 1));
    _step('상세: "${notice.sourceName} · 공공데이터" 출처 카드 · 공고 정보(모집 기간·'
        '당첨자 발표·문의·신청) · [채팅하기] 없음 · ⋮ 메뉴 차단 없음');

    // 3) 공고 사이트 이동.
    await _tap(tester, find.byKey(const ValueKey('detail-apply-cta')));
    await _pumpUntilTrue(tester, () => launched.isNotEmpty, 'apply launch');
    expect(launched.single.toString(), applyUrl);
    _step('[공고 사이트 이동] → $applyUrl');

    // 4) 지도에서 보기.
    await _tap(tester, find.byKey(const ValueKey('detail-map-cta')));
    await _pumpUntil(tester, find.byType(MapAroundScreen));
    await _pumpUntilTrue(
      tester,
      () => container.read(mapAroundProvider).value?.selectedId == id,
      'map selection',
    );
    final around = container.read(mapAroundProvider).value!;
    expect(around.centerLat, notice.latitude);
    expect(around.items.first.id, id);
    final group = around.groups.firstWhere((g) => g.contains(id));
    final marker = find.byKey(ValueKey('map-marker-${group.id}'));
    await _pumpUntil(tester, marker);
    if (group.items.length == 1) {
      expect(
        find.descendant(of: marker, matching: find.text(notice.housingType!.label)),
        findsOneWidget,
      );
    }
    await _pumpUntil(tester, find.byKey(ValueKey('map-housing-badge-$id')));
    _step('[지도에서 보기] → 내주변 (${notice.latitude!.toStringAsFixed(4)}, '
        '${notice.longitude!.toStringAsFixed(4)}) · 공고 선택·카드 맨 앞 · '
        '마커 ${group.items.length}건');

    debugPrint('[E2E] ===== SUMMARY =====\n${_log.join('\n')}');
  });
}
