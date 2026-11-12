import 'package:cached_network_image/cached_network_image.dart';
import 'package:flatmate_app/app/routes/route_names.dart';
import 'package:flatmate_app/core/utils/external_url.dart';
import 'package:flatmate_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flatmate_app/features/feed/data/mappers/feed_item_mapper.dart';
import 'package:flatmate_app/features/feed/data/repositories/mock_feed_repository.dart';
import 'package:flatmate_app/features/feed/domain/models/feed_item.dart';
import 'package:flatmate_app/features/feed/domain/models/region.dart';
import 'package:flatmate_app/features/feed/domain/repositories/feed_repository.dart';
import 'package:flatmate_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_detail_screen.dart';
import 'package:flatmate_app/features/feed/presentation/widgets/feed_card_item.dart';
import 'package:flatmate_app/features/location/domain/models/location_item.dart';
import 'package:flatmate_app/features/map_around/domain/map_feed_group.dart';
import 'package:flatmate_app/features/map_around/presentation/providers/map_around_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _applyUrl =
    'https://apply.lh.or.kr/lhapply/apply/wt/wrtanc/selectWrtancInfo.do?panId=2015122300020958';

/// LH 마이홈 `FeedOut` (행복주택, located, with 임대 조건).
Map<String, dynamic> _happyHouseOut() => {
      'id': 220,
      'feed_type': 'REAL_ESTATE',
      'source': 'LH_MYHOME',
      'is_public_data': true,
      'source_name': 'LH 마이홈',
      'author_id': null,
      'title': '[공공 혜택] 화성시 동탄지역 행복주택 입주자 모집 공고 (A54블록(38단지))',
      'content': '공급기관: LH\n'
          '공급유형: 행복주택\n'
          '주택유형: 아파트\n'
          '단지: A54블록(38단지)\n'
          '공급호수: 178세대\n'
          '공고일: 2026.10.27\n'
          '모집 기간: 2026.11.10 ~ 2026.11.12\n'
          '당첨자 발표: 2026.12.09\n'
          '문의: LH 콜센터 : 1600-1004 (평일 : 09:00 ~ 18:00)\n'
          '\n'
          '임대 조건: 보증금 2,516만원 · 월 106,930원\n'
          '주소: 경기도 화성시 동탄구 동탄신리천로5가길 35\n'
          '신청: $_applyUrl\n'
          '출처: LH 마이홈',
      'address': '경기도 화성시 동탄구 동탄신리천로5가길 35',
      'lat': 37.1848698494021,
      'lng': 127.143274899117,
      'extra_meta': {
        'deposit': 2516,
        'category': 'PUBLIC_HOUSING',
        'apply_url': _applyUrl,
        'housing_type': 'HAPPY_HOUSE',
        'monthly_rent': 11,
        'event_end_date': '2026-11-12',
        'event_start_date': '2026-11-10',
      },
      'price_text': '월세 2,516/11',
      'image_urls': const <String>[],
      'thumbnail_url': null,
      'published_at': '2026-11-11T11:49:47Z',
    };

/// 경상북도개발공사 매입임대 (no coordinates, no 임대 조건, deposit 0).
Map<String, dynamic> _rentalOut() => {
      'id': 251,
      'feed_type': 'REAL_ESTATE',
      'source': 'LH_MYHOME',
      'is_public_data': true,
      'source_name': 'LH 마이홈',
      'title': '[공공 혜택] 2026년 칠곡군 천원주택 예비입주자 모집 공고',
      'content': '공급기관: 경상북도개발공사\n'
          '공급유형: 매입임대\n'
          '주택유형: 다가구주택\n'
          '공고일: 2026.07.28\n'
          '모집 기간: 2026.07.28 ~ 2026.11.30\n'
          '당첨자 발표: 2026.11.30\n'
          '문의: 054-650-3116, 3155\n'
          '\n'
          '주소: 경상북도 칠곡군\n'
          '신청: https://www.gbdc.co.kr/boardview/boardview.do?seqId=1\n'
          '출처: LH 마이홈',
      'address': '경상북도 칠곡군',
      'lat': null,
      'lng': null,
      'extra_meta': {
        'deposit': 0,
        'category': 'PUBLIC_HOUSING',
        'apply_url': 'https://www.gbdc.co.kr/boardview/boardview.do?seqId=1',
        'housing_type': 'PUBLIC_RENTAL',
        'monthly_rent': 0,
        'event_end_date': '2026-11-30',
        'event_start_date': '2026-07-28',
      },
      'price_text': null,
      'image_urls': const <String>[],
      'thumbnail_url': null,
      'published_at': '2026-11-11T11:51:40Z',
    };

const _seoulApplyUrl =
    'https://apply.lh.or.kr/lhapply/apply/wt/wrtanc/selectWrtancInfo.do?panId=2015122300019550';

/// LH 서울 광역 전세임대 (시·도 전체 대상, no coordinates).
Map<String, dynamic> _seoulWideOut() => {
      'id': 308,
      'feed_type': 'REAL_ESTATE',
      'source': 'LH_MYHOME',
      'is_public_data': true,
      'source_name': 'LH 마이홈',
      'title': '[공공 혜택] 2026년 신혼·신생아 전세임대 I 입주자 수시모집 공고',
      'content': '공급기관: LH\n'
          '공급유형: 전세임대\n'
          '주택유형: 아파트\n'
          '공고일: 2026.03.24\n'
          '모집 기간: 2026.03.24 ~ 2026.12.31\n'
          '당첨자 발표: 2027.02.26\n'
          '문의: LH 콜센터 : 1600-1004 (평일 : 09:00 ~ 18:00)\n'
          '\n'
          '주소: 서울특별시\n'
          '신청: $_seoulApplyUrl\n'
          '출처: LH 마이홈',
      'location_id': null,
      'address': '서울특별시',
      'lat': null,
      'lng': null,
      'extra_meta': {
        'deposit': 0,
        'category': 'PUBLIC_HOUSING',
        'apply_url': _seoulApplyUrl,
        'housing_type': 'PUBLIC_RENTAL',
        'monthly_rent': 0,
        'event_end_date': '2026-12-31',
        'event_start_date': '2026-03-24',
      },
      'price_text': null,
      'image_urls': const <String>[],
      'thumbnail_url': null,
      'published_at': '2026-11-12T04:46:45Z',
    };

/// 경기도 행복주택 단지 정보 (GG_HOUSING: no apply_url, no 모집 기간).
Map<String, dynamic> _ggComplexOut() => {
      'id': 344,
      'feed_type': 'REAL_ESTATE',
      'source': 'GG_HOUSING',
      'is_public_data': true,
      'source_name': '경기도',
      'title': '[공공 혜택] 경기행복주택 양평 공흥',
      'content': '경기도 행복주택 (경기주택도시공사)\n'
          '입주 대상: 청년\n'
          '공급세대: 40세대\n'
          '준공일: 2019.01.28\n'
          '\n'
          '주소: 경기도 양평군 양평읍 남북로 70\n'
          '출처: 경기도',
      'location_id': 144,
      'address': '경기도 양평군 양평읍 남북로 70',
      'lat': 37.4889516711391,
      'lng': 127.502183615536,
      'extra_meta': {
        'deposit': 0,
        'category': 'PUBLIC_HOUSING',
        'apply_url': null,
        'housing_type': 'HAPPY_HOUSE',
        'monthly_rent': 0,
        'event_end_date': null,
        'event_start_date': null,
      },
      'price_text': null,
      'image_urls': const <String>[],
      'thumbnail_url': null,
      'published_at': '2026-11-12T04:49:24Z',
    };

class _Feeds extends MockFeedRepository {
  @override
  Future<List<FeedItem>> fetchFeeds({
    required int page,
    int pageSize = 10,
    String category = 'all',
    LocationItem? location,
    double radiusKm = 3,
    FeedSort sort = FeedSort.latest,
  }) async =>
      const [];
}

void main() {
  group('model', () {
    test('HousingType.fromCode', () {
      expect(HousingType.fromCode('HAPPY_HOUSE'), HousingType.happyHouse);
      expect(HousingType.fromCode('YOUTH_HOUSE').label, '청년주택');
      expect(HousingType.fromCode('PUBLIC_RENTAL').label, '공공임대');
      expect(HousingType.fromCode('???'), HousingType.publicRental);
    });

    test('LH FeedOut → public housing FeedItem + parsed notice', () {
      final item = feedItemFromJson(_happyHouseOut());
      expect(item.category, FeedCategory.housing);
      expect(item.isPublicData, isTrue);
      expect(item.isPublicHousing, isTrue);
      expect(item.isFestival, isFalse);
      expect(item.housingType, HousingType.happyHouse);
      expect(item.sourceName, 'LH 마이홈');
      expect(item.thumbnailUrl, isEmpty);
      expect(item.title, startsWith('[공공 혜택] '));
      expect(item.displayTitle, '화성시 동탄지역 행복주택 입주자 모집 공고 (A54블록(38단지))');

      final notice = item.publicNotice!;
      expect(notice.supplier, 'LH');
      expect(notice.winnerDate, '2026.12.09');
      expect(notice.contact, 'LH 콜센터 : 1600-1004 (평일 : 09:00 ~ 18:00)');
      expect(notice.applyPeriod, '2026.11.10 ~ 2026.11.12');
      expect(notice.applyUrl, _applyUrl);
      expect(notice.units, '178세대');
      expect(
        notice.rows.take(4).map((r) => r.label),
        ['모집 기간', '당첨자 발표', '문의', '신청'],
      );
      expect(markerLabel(item), '행복주택');
    });

    test('rentSummary: 임대 조건 → 보증금/월세 → fallback', () {
      expect(
        feedItemFromJson(_happyHouseOut()).publicNotice!.rentSummary,
        '보증금 2,516만원 · 월 106,930원',
      );
      final noTerms = _happyHouseOut()
        ..['content'] = '공급기관: LH\n당첨자 발표: 2026.12.09';
      expect(
        feedItemFromJson(noTerms).publicNotice!.rentSummary,
        '보증금 2,516만 · 월 11만',
      );
      expect(
        feedItemFromJson(_rentalOut()).publicNotice!.rentSummary,
        '임대 조건은 공고문 참고',
      );
    });

    test('GG_HOUSING: 안내 행 · 입주 대상 · 공급세대 · 준공일, no 출처 row', () {
      final item = feedItemFromJson(_ggComplexOut());
      expect(item.isPublicHousing, isTrue);
      expect(item.sourceName, '경기도');
      final notice = item.publicNotice!;
      expect(notice.target, '청년');
      expect(notice.households, '40세대');
      expect(notice.notes, ['경기도 행복주택 (경기주택도시공사)']);
      expect(notice.applyUrl, isNull);
      expect(notice.applyPeriod, isNull);
      expect(
        notice.rows.map((r) => (r.label, r.value)),
        [
          ('주소', '경기도 양평군 양평읍 남북로 70'),
          ('입주 대상', '청년'),
          ('공급세대', '40세대'),
          ('준공일', '2019.01.28'),
          ('안내', '경기도 행복주택 (경기주택도시공사)'),
        ],
      );
    });

    test('rentSummary 3단계: 입주 대상 · 공급세대 before the fallback', () {
      expect(
        feedItemFromJson(_ggComplexOut()).publicNotice!.rentSummary,
        '청년 · 40세대',
      );
      final onlyUnits = _ggComplexOut()
        ..['content'] = '공급세대: 120세대\n출처: 경기도';
      expect(
        feedItemFromJson(onlyUnits).publicNotice!.rentSummary,
        '120세대',
      );
      final rentWins = _ggComplexOut()
        ..['extra_meta'] = {
          ...(_ggComplexOut()['extra_meta'] as Map<String, dynamic>),
          'deposit': 1500,
        };
      expect(
        feedItemFromJson(rentWins).publicNotice!.rentSummary,
        '보증금 1,500만',
      );
    });

    test('LH rows keep known keys only (no 안내 / 출처)', () {
      final labels =
          feedItemFromJson(_happyHouseOut()).publicNotice!.rows.map((r) => r.label);
      expect(labels, isNot(contains('안내')));
      expect(labels, isNot(contains('출처')));
    });

    test('noticeRegionLabel: 시·군·구 short form, 광역 = 시·도 as written', () {
      expect(noticeRegionLabel('경기도 양평군 양평읍 남북로 70'), '경기 양평군');
      expect(noticeRegionLabel('서울특별시'), '서울특별시');
      expect(noticeRegionLabel('인천광역시'), '인천광역시');
      expect(noticeRegionLabel('서울특별시 종로구 세종대로 1'), '서울 종로구');
      expect(noticeRegionLabel('세종특별자치시 한누리대로 2130'), '세종특별자치시');
      expect(noticeRegionLabel(''), '');
      expect(noticeRegionLabel(null), '');
    });

    test('app posts are not public housing', () {
      final app = feedItemFromJson({
        'id': 3,
        'feed_type': 'REAL_ESTATE',
        'title': '[공공 혜택] 아님',
        'extra_meta': {'room_type': 'ONE_ROOM', 'monthly_rent': 50},
      });
      expect(app.isPublicHousing, isFalse);
      expect(app.publicNotice, isNull);
      expect(app.displayTitle, '[공공 혜택] 아님');
    });
  });

  List<Override> overrides({List<Uri>? launched}) => [
        feedRepositoryProvider.overrideWithValue(_Feeds()),
        currentUserIdProvider.overrideWithValue(null),
        mapTilesEnabledProvider.overrideWithValue(false),
        externalUrlLauncherProvider.overrideWithValue((uri) async {
          launched?.add(uri);
          return true;
        }),
      ];

  testWidgets('card: [공공 혜택] + 유형 · 임대 조건 · 모집 기간 · 출처 · placeholder',
      (tester) async {
    final item = feedItemFromJson(_happyHouseOut());
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          home: Scaffold(body: FeedCardItem(item: item, onTap: () {})),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('public-badge-220')), findsOneWidget);
    expect(find.text('공공 혜택'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('housing-type-220')),
        matching: find.text('행복주택'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('[공공 혜택]'), findsNothing);
    expect(find.text('보증금 2,516만원 · 월 106,930원'), findsOneWidget);
    expect(find.text('모집 2026.11.10 ~ 2026.11.12'), findsOneWidget);
    expect(find.text('출처: LH 마이홈'), findsOneWidget);
    expect(find.byKey(const ValueKey('feed-placeholder-220')), findsOneWidget);
    expect(find.byIcon(Icons.home_work), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  Future<GoRouter> pumpDetail(
    WidgetTester tester,
    FeedItem item, {
    List<Uri>? launched,
  }) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/detail',
      routes: [
        GoRoute(path: '/detail', builder: (_, _) => FeedDetailScreen(item: item)),
        GoRoute(
          path: RouteNames.around,
          builder: (_, _) => const Scaffold(body: Text('around-tab')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(launched: launched),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('detail: source card · 공고 정보 · 공고 사이트 / 지도 · no chat',
      (tester) async {
    final launched = <Uri>[];
    final item = feedItemFromJson(_happyHouseOut());
    await pumpDetail(tester, item, launched: launched);

    expect(find.text('LH 마이홈 · 공공데이터'), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-housing-badges')), findsOneWidget);
    expect(find.byKey(const ValueKey('feed-placeholder-220')), findsOneWidget);
    final card = find.byKey(const ValueKey('detail-card-housing'));
    expect(card, findsOneWidget);
    for (final label in ['모집 기간', '당첨자 발표', '문의', '신청', '공급기관', '임대 조건']) {
      expect(find.byKey(ValueKey('housing-row-$label')), findsOneWidget,
          reason: label);
    }
    expect(find.text('2026.12.09'), findsOneWidget);
    expect(find.text('채팅하기'), findsNothing);
    expect(find.textContaining('채팅 '), findsNothing);
    expect(find.text('공고 사이트 이동'), findsOneWidget);
    expect(find.text('지도에서 보기'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('detail-apply-cta')));
    await tester.pump();
    expect(launched.single.toString(), _applyUrl);

    final link = find.byKey(const ValueKey('housing-apply-link'));
    // Mid-screen: the pinned app bar covers the top edge.
    await Scrollable.ensureVisible(tester.element(link), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(link);
    await tester.pump();
    expect(launched, hasLength(2));

    await tester.tap(find.byKey(const ValueKey('detail-more')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('menu-report')), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-block')), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(FeedDetailScreen)),
    );
    await tester.tap(find.byKey(const ValueKey('detail-map-cta')));
    await tester.pumpAndSettle();
    expect(find.text('around-tab'), findsOneWidget);
    expect(container.read(mapFocusProvider)?.id, '220');
  });

  testWidgets('detail without coordinates: no 지도에서 보기', (tester) async {
    await pumpDetail(tester, feedItemFromJson(_rentalOut()));
    expect(find.text('공고 사이트 이동'), findsOneWidget);
    expect(find.text('지도에서 보기'), findsNothing);
    expect(find.text('임대 조건은 공고문 참고'), findsOneWidget);
    expect(find.byIcon(Icons.location_city), findsOneWidget);
  });

  Future<void> pumpCard(WidgetTester tester, FeedItem item) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          home: Scaffold(body: FeedCardItem(item: item, onTap: () {})),
        ),
      ),
    );
    await tester.pump();
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(ValueKey(key))).data!;

  testWidgets('card: 좌표 없는 서울 광역 공고 → "서울특별시" · 출처 · 임대 조건',
      (tester) async {
    await pumpCard(tester, feedItemFromJson(_seoulWideOut()));
    expect(textOf(tester, 'feed-region-308'), '서울특별시');
    expect(find.text('출처: LH 마이홈'), findsOneWidget);
    expect(textOf(tester, 'feed-rent-308'), '임대 조건은 공고문 참고');
    expect(textOf(tester, 'feed-apply-period-308'), '모집 2026.03.24 ~ 2026.12.31');
    expect(find.byKey(const ValueKey('public-badge-308')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('feed-meta-308')),
        matching: find.textContaining('서울특별시'),
      ),
      findsOneWidget,
      reason: 'region once, not repeated as the neighborhood',
    );
  });

  testWidgets('card: GG 단지 → "경기 양평군" · 출처: 경기도 · 청년 · 40세대',
      (tester) async {
    await pumpCard(tester, feedItemFromJson(_ggComplexOut()));
    expect(textOf(tester, 'feed-region-344'), '경기 양평군');
    expect(find.text('출처: 경기도'), findsOneWidget);
    expect(textOf(tester, 'feed-rent-344'), '청년 · 40세대');
    expect(find.byKey(const ValueKey('feed-apply-period-344')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('housing-type-344')),
        matching: find.text('행복주택'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('detail: 서울 광역 (좌표 없음) → 공고 사이트 이동만', (tester) async {
    final launched = <Uri>[];
    await pumpDetail(tester, feedItemFromJson(_seoulWideOut()), launched: launched);
    expect(find.byKey(const ValueKey('detail-map-cta')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('detail-apply-cta')));
    await tester.pump();
    expect(launched.single.toString(), _seoulApplyUrl);
    expect(find.byKey(const ValueKey('housing-row-주소')), findsOneWidget);
  });

  testWidgets('detail: GG 단지 (apply_url 없음) → 지도에서 보기만 · 단지 정보 행',
      (tester) async {
    await pumpDetail(tester, feedItemFromJson(_ggComplexOut()));
    expect(find.byKey(const ValueKey('detail-apply-cta')), findsNothing);
    expect(find.text('공고 사이트 이동'), findsNothing);
    expect(find.byKey(const ValueKey('detail-map-cta')), findsOneWidget);
    for (final label in ['입주 대상', '공급세대', '준공일', '안내', '주소']) {
      expect(find.byKey(ValueKey('housing-row-$label')), findsOneWidget,
          reason: label);
    }
    expect(find.byKey(const ValueKey('housing-row-출처')), findsNothing);
    expect(find.text('경기도 · 공공데이터'), findsOneWidget);
    expect(find.text('청년 · 40세대'), findsWidgets);
  });
}
