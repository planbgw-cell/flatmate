// On-device E2E (guest): 한국관광공사 축제 — 동네소식 card ([축제] badge,
// 출처, external tong.visitkorea.or.kr thumbnail actually decoded) → detail
// (출처 card, 축제 정보, external gallery image) → 지도에서 보기 → 내주변
// centered on the festival with its 축제 pin selected.
//
//   adb install -r -g build\app\outputs\flutter-apk\app-debug.apk
//   flutter test integration_test/festival_flow_test.dart \
//     -d <device-id> --dart-define=USE_MOCK_API=false
import 'package:dio/dio.dart';
import 'package:flatmate_app/app/app.dart';
import 'package:flatmate_app/app/config/app_config.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/core/di/injection.dart';
import 'package:flatmate_app/features/community/presentation/screens/community_screen.dart';
import 'package:flatmate_app/features/feed/data/mappers/feed_item_mapper.dart';
import 'package:flatmate_app/features/feed/domain/models/feed_item.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_detail_screen.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_screen.dart';
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

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
}

/// True once the network image under [finder] has been decoded.
bool _imageLoaded(Finder finder) => find
    .descendant(of: finder, matching: find.byType(RawImage))
    .evaluate()
    .any((e) => (e.widget as RawImage).image != null);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실기기 E2E: 축제 카드·상세·지도 (외부 이미지 · [축제] · 출처)', (tester) async {
    await configureDependencies();
    expect(sl<AppConfig>().useMockApi, isFalse,
        reason: 'Run with --dart-define=USE_MOCK_API=false');
    await sl<TokenStorage>().clear();

    // A published 한국관광공사 festival at a position no other post shares.
    final dio = Dio(BaseOptions(baseUrl: AppConfig.devServerBaseUrl));
    final response = await dio.get<Map<String, dynamic>>(
      '/feeds',
      queryParameters: {'feed_type': 'LOCAL_NEWS', 'limit': 100},
    );
    final rows = [
      for (final row in response.data!['items'] as List)
        Map<String, dynamic>.from(row as Map),
    ];
    String key(Map<String, dynamic> row) =>
        '${(row['lat'] as num?)?.toStringAsFixed(4)},'
        '${(row['lng'] as num?)?.toStringAsFixed(4)}';
    final counts = <String, int>{};
    for (final row in rows) {
      counts[key(row)] = (counts[key(row)] ?? 0) + 1;
    }
    final festivalRow = rows.firstWhere(
      (row) =>
          row['source'] == 'TOUR_API' &&
          row['lat'] != null &&
          (row['thumbnail_url'] as String?)?.startsWith('https://') == true &&
          counts[key(row)] == 1,
    );
    final FeedItem festival = feedItemFromJson(festivalRow);
    final id = festival.id;
    expect(festival.isFestival, isTrue);
    _step('서버 축제 $id "${festival.displayTitle}" · ${festival.address} · '
        '썸네일 ${festival.thumbnailUrl}');

    await tester.pumpWidget(ProviderScope(child: FlatmateApp()));
    await _pumpUntil(tester, find.text('로그인 없이 둘러보기'));
    await _tap(tester, find.text('로그인 없이 둘러보기'));
    await _pumpUntil(tester, find.byType(FeedScreen));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(FeedScreen)));

    // Dong = the festival's server dong (as if picked in the 동네 selector);
    // [우리 동네] lists its 시·군·구 by `location_id`.
    container.read(currentLocationProvider.notifier).state = LocationItem(
      id: festivalRow['location_id'].toString(),
      cityName: '',
      districtName: '',
      dongName: festival.neighborhood,
      latitude: festival.latitude!,
      longitude: festival.longitude!,
    );

    // 1) 동네소식 card: badge · source · external thumbnail decoded.
    await _tap(tester, find.byKey(const ValueKey('tab-community')));
    await _pumpUntil(tester, find.byType(CommunityScreen));
    final thumb = find.byKey(ValueKey('feed-thumb-$id'));
    await _pumpUntil(tester, find.byKey(const ValueKey('community-list')));
    await tester.scrollUntilVisible(
      thumb,
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('community-list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.byKey(ValueKey('festival-badge-$id')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(ValueKey('feed-source-$id')),
        matching: find.text('출처: 한국관광공사'),
      ),
      findsOneWidget,
    );
    expect(find.text(festival.displayTitle), findsOneWidget);
    await _pumpUntilTrue(tester, () => _imageLoaded(thumb), 'card thumbnail');
    _step('동네소식 카드: [축제] 뱃지 · "출처: 한국관광공사" · 제목 접두어 제거 · '
        '외부 썸네일 디코딩 완료');

    // 2) Detail.
    await _tap(tester, thumb);
    await _pumpUntil(tester, find.byType(FeedDetailScreen));
    expect(find.byKey(const ValueKey('detail-festival-badge')), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-source-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-card-festival')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('detail-title'))).data,
      festival.displayTitle,
    );
    final gallery = find.byKey(const ValueKey('detail-image-0'));
    await _pumpUntilTrue(tester, () => _imageLoaded(gallery), 'detail image');
    _step('상세: [축제] 뱃지 · 출처 카드 · 축제 정보(행사 기간·장소) · 외부 이미지 디코딩 완료');

    // 3) 지도에서 보기 → 내주변 centered on it, 축제 pin selected.
    await _tap(tester, find.byKey(const ValueKey('detail-map-cta')));
    await _pumpUntil(tester, find.byType(MapAroundScreen));
    await _pumpUntilTrue(
      tester,
      () => container.read(mapAroundProvider).value?.selectedId == id,
      'festival selection',
    );
    final around = container.read(mapAroundProvider).value!;
    expect(around.centerLat, festival.latitude);
    expect(around.centerLng, festival.longitude);
    expect(around.items.first.id, id);
    final marker = find.byKey(ValueKey('map-marker-$id'));
    await _pumpUntil(tester, marker);
    expect(
      find.descendant(of: marker, matching: find.byIcon(Icons.celebration)),
      findsOneWidget,
    );
    expect(find.descendant(of: marker, matching: find.text('축제')), findsOneWidget);
    await _pumpUntil(tester, find.byKey(ValueKey('map-festival-badge-$id')));
    final card = find.byKey(ValueKey('map-card-$id'));
    await _pumpUntilTrue(tester, () => _imageLoaded(card), 'map card image');
    _step('[지도에서 보기] → 내주변 중심 (${festival.latitude!.toStringAsFixed(4)}, '
        '${festival.longitude!.toStringAsFixed(4)}) · 축제 핀(celebration 아이콘 · "축제") 선택 · '
        '카드 맨 앞 · 외부 썸네일 디코딩 · 반경 내 글 ${around.items.length}건');

    debugPrint('[E2E] ===== SUMMARY =====\n${_log.join('\n')}');
  });
}
