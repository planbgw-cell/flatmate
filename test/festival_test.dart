import 'package:flatmate_app/app/routes/route_names.dart';
import 'package:flatmate_app/core/network/media_url.dart';
import 'package:flatmate_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flatmate_app/features/feed/data/mappers/feed_item_mapper.dart';
import 'package:flatmate_app/features/feed/data/repositories/mock_feed_repository.dart';
import 'package:flatmate_app/features/feed/domain/models/feed_extra_meta.dart';
import 'package:flatmate_app/features/feed/domain/models/feed_item.dart';
import 'package:flatmate_app/features/feed/domain/models/region.dart';
import 'package:flatmate_app/features/feed/domain/repositories/feed_repository.dart';
import 'package:flatmate_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_detail_screen.dart';
import 'package:flatmate_app/features/feed/presentation/widgets/feed_card_item.dart';
import 'package:flatmate_app/features/location/domain/models/location_item.dart';
import 'package:flatmate_app/features/map_around/domain/map_feed_group.dart';
import 'package:flatmate_app/features/map_around/presentation/providers/map_around_provider.dart';
import 'package:flatmate_app/features/map_around/presentation/screens/map_around_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// `FeedOut` as returned for 한국관광공사 festivals (TOUR_API).
Map<String, dynamic> _festivalOut({
  int id = 165,
  String start = '2026-11-15',
  String end = '2026-11-15',
  String? thumbnail = 'https://tong.visitkorea.or.kr/cms/resource/02/4115202_image2_1.jpg',
}) =>
    {
      'id': id,
      'feed_type': 'LOCAL_NEWS',
      'status': 'PUBLISHED',
      'trade_status': 'SELLING',
      'title': '[축제] 2026 대전 온시민에너지걷기한마당',
      'content': '대전엑스포시민광장에서 열리는 걷기 축제.\n\n출처: 한국관광공사',
      'source': 'TOUR_API',
      'is_public_data': true,
      'source_name': '한국관광공사',
      'author_id': null,
      'author_nickname': null,
      'address': '대전광역시 서구 둔산대로 169 (만년동)',
      'lat': 36.3664690154,
      'lng': 127.388017285,
      'extra_meta': {
        'category': 'FESTIVAL',
        'event_start_date': start,
        'event_end_date': end,
      },
      'price_text': null,
      'image_urls': [?thumbnail],
      'thumbnail_url': thumbnail,
      'like_count': 0,
      'is_liked': false,
      'published_at': '2026-11-10T11:33:31Z',
    };

FeedItem _festival({String id = '165'}) => feedItemFromJson(
      _festivalOut(id: int.parse(id), end: '2026-11-20', thumbnail: null),
    );

class _Feeds extends MockFeedRepository {
  _Feeds(this.items);

  final List<FeedItem> items;
  final searches = <LocationItem?>[];

  @override
  Future<List<FeedItem>> fetchFeeds({
    required int page,
    int pageSize = 10,
    String category = 'all',
    LocationItem? location,
    double radiusKm = 3,
    FeedSort sort = FeedSort.latest,
  }) async {
    searches.add(location);
    return items;
  }
}

List<Override> _overrides(_Feeds feeds) => [
      feedRepositoryProvider.overrideWithValue(feeds),
      currentUserIdProvider.overrideWithValue(null),
      mapTilesEnabledProvider.overrideWithValue(false),
    ];

void main() {
  group('resolveMediaUrl', () {
    const base = 'http://121.133.47.161:8000/api/v1';

    test('relative server paths get the API origin', () {
      expect(
        resolveMediaUrl('/static/images/a.png', apiBaseUrl: base),
        'http://121.133.47.161:8000/static/images/a.png',
      );
      expect(
        resolveMediaUrl('static/images/a.png', apiBaseUrl: base),
        'http://121.133.47.161:8000/static/images/a.png',
      );
    });

    test('external https is kept; external http is upgraded', () {
      const tour =
          'https://tong.visitkorea.or.kr/cms/resource/02/4115202_image2_1.jpg';
      expect(resolveMediaUrl(tour, apiBaseUrl: base), tour);
      expect(
        resolveMediaUrl(
          'http://tong.visitkorea.or.kr/cms/resource/02/4115202_image2_1.jpg',
          apiBaseUrl: base,
        ),
        tour,
      );
      expect(
        resolveMediaUrl('//tong.visitkorea.or.kr/a.jpg', apiBaseUrl: base),
        'https://tong.visitkorea.or.kr/a.jpg',
      );
    });

    test('the cleartext dev API server stays http', () {
      const own = 'http://121.133.47.161:8000/static/images/a.png';
      expect(resolveMediaUrl(own, apiBaseUrl: base), own);
      expect(resolveMediaUrl('  ', apiBaseUrl: base), '');
      expect(resolveMediaUrl(null, apiBaseUrl: base), '');
    });
  });

  test('TOUR_API FeedOut → festival FeedItem', () {
    final item = feedItemFromJson(_festivalOut());
    expect(item.category, FeedCategory.community);
    expect(item.isFestival, isTrue);
    expect(item.isPublicData, isTrue);
    expect(item.sourceName, '한국관광공사');
    expect(item.authorId, isNull);
    expect(item.authorName, '한국관광공사');
    expect(item.address, '대전광역시 서구 둔산대로 169 (만년동)');
    expect(item.neighborhood, '만년동');
    expect(item.title, startsWith('[축제] '));
    expect(item.displayTitle, '2026 대전 온시민에너지걷기한마당');
    expect(
      item.thumbnailUrl,
      'https://tong.visitkorea.or.kr/cms/resource/02/4115202_image2_1.jpg',
    );
    expect(item.latitude, closeTo(36.36647, 1e-5));

    final meta = FeedExtraMeta(item.category, item.extraMeta);
    expect(meta.eventPeriodLabel, '2026.11.15');
    expect(
      FeedExtraMeta(item.category, {
        'category': 'FESTIVAL',
        'event_start_date': '2026-11-15',
        'event_end_date': '2026-11-20',
      }).eventPeriodLabel,
      '2026.11.15 ~ 2026.11.20',
    );
    expect(
      meta.festivalRows(address: item.address).map((r) => r.label),
      ['행사 기간', '장소'],
    );
    expect(markerLabel(item), '축제');

    final app = feedItemFromJson({
      'id': 1,
      'feed_type': 'GENERAL',
      'title': '[축제] 아님',
      'is_public_data': false,
    });
    expect(app.isFestival, isFalse);
    expect(app.displayTitle, '[축제] 아님');
  });

  test('권역 · 지역 라벨 follow the server zone grouping', () {
    expect(sidoShortName('경기도'), '경기');
    expect(sidoShortName('서울특별시'), '서울');
    expect(sidoShortName('전남광주통합특별시'), '전남광주');
    expect(sidoShortName('성남시'), isNull);
    final zones = {
      '서울': '수도권',
      '인천광역시': '수도권',
      '경기도': '수도권',
      '강원특별자치도': '강원권',
      '세종특별자치시': '충청권',
      '충청북도': '충청권',
      '전북특별자치도': '호남권',
      '전남광주통합특별시': '호남권',
      '대구광역시': '대경권',
      '경상북도': '대경권',
      '울산광역시': '동남권',
      '경상남도': '동남권',
      '제주특별자치도': '제주권',
    };
    zones.forEach((sido, zone) => expect(zoneOf(sido), zone, reason: sido));
    expect(zoneOf(null), isNull);
    expect(zoneDescription('수도권'), '수도권(서울·인천·경기)');
    expect(zoneDescription('호남권'), '호남권(전북·전남광주)');

    final labels = {
      '경기도 가평군 가평읍 달전리 1-1': '경기 가평군',
      '서울특별시 종로구 동숭길 122 (동숭동)': '서울 종로구',
      '서울 중구 태평로1가 1 청계광장': '서울 중구',
      '세종특별자치시 중앙공원로 60 (세종동)': '세종',
      '경상북도 포항시 북구 선착로 78 (동빈1가)': '경북 포항시',
      '전남광주통합특별시 순천시 별미길 18 (남내동)': '전남광주 순천시',
      '성남시 분당구 정자동': '',
    };
    labels.forEach(
      (address, label) => expect(regionLabel(address), label, reason: address),
    );
    expect(zoneOfAddress('경기도 가평군 가평읍'), '수도권');
  });

  test('neighborhoodFromAddress picks the dong-level token', () {
    final cases = {
      '대전광역시 서구 둔산대로 169 (만년동)': '만년동',
      '서울특별시 중구 회현동1가 100-115': '회현동1가',
      '서울 중구 태평로1가 1 청계광장': '태평로1가',
      '서울특별시 중구 태평로1가 1 청계천(청계광장 ~ 삼일교)': '태평로1가',
      '전북특별자치도 진안군 진안읍 진무로 1166 진안로컬푸드진안점': '진안읍',
      '경기도 포천시 신북면 아트밸리로 234 포천 아트밸리': '신북면',
      '경상남도 김해시 장유로 551 (신문동) 롯데가든파크': '신문동',
      '전남광주통합특별시 서구 상무누리로 30': '서구',
      '성남시 분당구 정자동': '정자동',
      '': '',
    };
    cases.forEach((address, expected) {
      expect(neighborhoodFromAddress(address), expected, reason: address);
    });
  });

  testWidgets('festival card: badge · title without prefix · period · source',
      (tester) async {
    final item = _festival();
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(_Feeds(const [])),
        child: MaterialApp(
          home: Scaffold(body: FeedCardItem(item: item, onTap: () {})),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('festival-badge-165')), findsOneWidget);
    expect(find.text('2026 대전 온시민에너지걷기한마당'), findsOneWidget);
    expect(find.textContaining('[축제]'), findsNothing);
    expect(find.text('2026.11.15 ~ 2026.11.20'), findsOneWidget);
    expect(find.text('출처: 한국관광공사'), findsOneWidget);
    final meta = tester.widget<Text>(find.byKey(const ValueKey('feed-meta-165')));
    expect(meta.data, isNot(contains('한국관광공사')));
  });

  testWidgets('festival detail: source card · info · 지도에서 보기 → 내주변',
      (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final item = _festival();
    final router = GoRouter(
      initialLocation: '/detail',
      routes: [
        GoRoute(
          path: '/detail',
          builder: (_, _) => FeedDetailScreen(item: item),
        ),
        GoRoute(
          path: RouteNames.around,
          builder: (_, _) => const Scaffold(body: Text('around-tab')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(_Feeds(const [])),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('detail-source-card')), findsOneWidget);
    expect(find.text('공공데이터 · 출처: 한국관광공사'), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-festival-badge')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('detail-title'))).data,
      '2026 대전 온시민에너지걷기한마당',
    );
    expect(find.byKey(const ValueKey('detail-card-festival')), findsOneWidget);
    expect(find.text('대전광역시 서구 둔산대로 169 (만년동)'), findsOneWidget);
    expect(find.text('채팅하기'), findsNothing);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(FeedDetailScreen)),
    );
    await tester.tap(find.byKey(const ValueKey('detail-map-cta')));
    await tester.pumpAndSettle();
    expect(find.text('around-tab'), findsOneWidget);
    expect(container.read(mapFocusProvider)?.id, '165');
  });

  testWidgets('map: focus centers on the festival, festival pin selected',
      (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final festival = _festival();
    final other = FeedItem(
      id: '7',
      title: '근처 글',
      neighborhood: '만년동',
      postedAt: DateTime(2026, 11, 10),
      priceOrCondition: '9,000원',
      thumbnailUrl: '',
      likeCount: 0,
      chatCount: 0,
      category: FeedCategory.market,
      badges: const [],
      isBumped: false,
      latitude: 36.368,
      longitude: 127.390,
    );
    final feeds = _Feeds([other, festival]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._overrides(feeds),
          mapFocusProvider.overrideWith((ref) => festival),
        ],
        child: const MaterialApp(home: MapAroundScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MapAroundScreen)),
    );
    final state = container.read(mapAroundProvider).value!;
    expect(state.centerLat, festival.latitude);
    expect(state.centerLng, festival.longitude);
    expect(feeds.searches.last?.latitude, festival.latitude);
    expect(state.selectedId, '165');
    expect(state.items.first.id, '165');
    expect(container.read(mapFocusProvider), isNull, reason: 'consumed');

    final marker = find.byKey(const ValueKey('map-marker-165'));
    expect(marker, findsOneWidget);
    expect(
      find.descendant(of: marker, matching: find.byIcon(Icons.celebration)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: marker, matching: find.text('축제')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('map-festival-badge-165')), findsOneWidget);
    expect(find.text('출처: 한국관광공사'), findsNothing);
    expect(find.textContaining('출처: 한국관광공사'), findsOneWidget);
  });
}
