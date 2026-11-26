import 'package:cached_network_image/cached_network_image.dart';
import 'package:flatmate_app/app/config/app_config.dart';
import 'package:flatmate_app/app/routes/route_names.dart';
import 'package:flatmate_app/core/network/media_url.dart';
import 'package:flatmate_app/core/utils/external_url.dart';
import 'package:flatmate_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flatmate_app/features/feed/data/mappers/feed_item_mapper.dart';
import 'package:flatmate_app/features/feed/data/repositories/mock_feed_repository.dart';
import 'package:flatmate_app/features/feed/domain/models/feed_item.dart';
import 'package:flatmate_app/features/feed/domain/repositories/feed_repository.dart';
import 'package:flatmate_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_detail_screen.dart';
import 'package:flatmate_app/features/feed/presentation/widgets/feed_card_item.dart';
import 'package:flatmate_app/features/feed/presentation/widgets/fullscreen_image_viewer.dart';
import 'package:flatmate_app/features/location/domain/models/location_item.dart';
import 'package:flatmate_app/features/map_around/presentation/providers/map_around_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _seoulDetailUrl =
    'http://www.zungo.co.kr/main/main.php?CPC_REFERER=http%3A%2F%2Ffleamarket.seoul.go.kr';
const _shareMapPath = '/api/v1/public-items/39/map.jpg';

Map<String, dynamic> _ggRecycleOut() => {
      'id': 1974,
      'feed_type': 'GENERAL',
      'source': 'GG_SHARE',
      'is_public_data': true,
      'source_name': '경기도',
      'title': '[공공 나눔] 의정부시재활용센터',
      'content': '경기도 재활용센터\n'
          '운영: (사)한국생활자원재활용협회 의정부지회\n'
          '취급: 가전+가구 등\n'
          '평일 운영: 09:00 ~ 18:00\n'
          '휴무: 토+일+공휴일\n'
          '문의: 031-844-7282\n'
          '\n'
          '운영: (사)한국생활자원재활용협회 의정부지회\n'
          '이용: 센터 문의\n'
          '위치: 경기도 의정부시 장곡로 450(신곡동)\n'
          '출처: 경기도',
      'address': '경기도 의정부시 장곡로 450(신곡동)',
      'lat': 37.74351676,
      'lng': 127.0551989,
      'extra_meta': {
        'category': 'PUBLIC_SHARE',
        'item_category': 'RECYCLE',
        'provider_name': '(사)한국생활자원재활용협회 의정부지회',
        'price_summary': '센터 문의',
        'detail_url': null,
        'nearby_summary': {
          'subway': '의정부경전철 동오역 도보 4분 (250m)',
          'convenience': 75,
          'mart': 2,
          'hospital': 138,
        },
      },
      'price_text': '센터 문의',
      'image_urls': const [_shareMapPath],
      'thumbnail_url': _shareMapPath,
      'published_at': '2026-11-21T08:14:56Z',
    };

Map<String, dynamic> _seoulRecycleOut() => {
      'id': 1956,
      'feed_type': 'GENERAL',
      'source': 'SEOUL_SHARE',
      'is_public_data': true,
      'source_name': '서울시',
      'title': '[공공 나눔] 성북구 재활용센터',
      'content': '서울 재활용·벼룩시장 시설\n'
          '운영: 서울시 성북구\n'
          '이용: 센터 문의\n'
          '위치: 서울 성북구 삼선동1가\n'
          '안내: $_seoulDetailUrl\n'
          '출처: 서울시',
      'address': '서울 성북구 삼선동1가',
      'lat': 37.58079664277135,
      'lng': 127.00863578989066,
      'extra_meta': {
        'category': 'PUBLIC_SHARE',
        'item_category': 'RECYCLE',
        'provider_name': '서울시 성북구',
        'price_summary': '센터 문의',
        'detail_url': _seoulDetailUrl,
        'nearby_summary': {
          'subway': '수도권4호선 혜화역 도보 8분 (606m)',
          'convenience': 64,
          'mart': 4,
          'hospital': 89,
        },
      },
      'price_text': '센터 문의',
      'image_urls': const ['/api/v1/public-items/9/map.jpg'],
      'thumbnail_url': '/api/v1/public-items/9/map.jpg',
      'published_at': '2026-11-21T08:14:55Z',
    };

Map<String, dynamic> _facilityNoImageOut() => {
      'id': 1980,
      'feed_type': 'GENERAL',
      'source': 'GG_SHARE',
      'is_public_data': true,
      'source_name': '경기도',
      'title': '[공공 나눔] 공유창고 체험관',
      'content': '운영: 경기도\n이용: 무료 예약\n위치: 경기도 수원시',
      'address': '경기도 수원시',
      'lat': null,
      'lng': null,
      'extra_meta': {
        'category': 'PUBLIC_SHARE',
        'item_category': 'FACILITY',
        'provider_name': '경기도',
        'price_summary': '무료 예약',
        'detail_url': null,
      },
      'price_text': '무료 예약',
      'image_urls': const <String>[],
      'thumbnail_url': null,
      'published_at': '2026-11-21T09:00:00Z',
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
    String? employmentType,
  }) async =>
      const [];
}

void main() {
  group('model', () {
    test('ShareItemCategory.fromCode', () {
      expect(ShareItemCategory.fromCode('RECYCLE'), ShareItemCategory.recycle);
      expect(ShareItemCategory.fromCode('FACILITY').label, '공유시설');
      expect(ShareItemCategory.fromCode('SHARE_FACILITY').label, '공유시설');
      expect(ShareItemCategory.fromCode('FLEA').label, '공공나눔');
      expect(ShareItemCategory.fromCode(null), ShareItemCategory.share);
    });

    test('GG_SHARE RECYCLE: provider · price · nearby · map path', () {
      final item = feedItemFromJson(_ggRecycleOut());
      expect(item.category, FeedCategory.market);
      expect(item.isPublicShare, isTrue);
      expect(item.shareCategory, ShareItemCategory.recycle);
      expect(item.displayTitle, '의정부시재활용센터');
      expect(item.nearbySummary?.subway, contains('동오역'));

      final share = item.publicShare!;
      expect(share.providerName, contains('의정부지회'));
      expect(share.priceSummary, '센터 문의');
      expect(share.detailUrl, isNull);
      expect(share.itemsHandled, '가전+가구 등');
      expect(share.hoursLabel, contains('09:00'));

      final expected = Uri.parse(AppConfig.devServerBaseUrl)
          .replace(path: _shareMapPath)
          .toString();
      expect(
        resolveMediaUrl(_shareMapPath, apiBaseUrl: AppConfig.devServerBaseUrl),
        expected,
      );
      expect(item.thumbnailUrl, expected);
    });

    test('SEOUL_SHARE: detail_url', () {
      final item = feedItemFromJson(_seoulRecycleOut());
      expect(item.publicShare!.detailUrl, _seoulDetailUrl);
      expect(item.sourceName, '서울시');
    });

    test('user market posts are not public share', () {
      final app = feedItemFromJson({
        'id': 3,
        'feed_type': 'GENERAL',
        'title': '[공공 나눔] 아님',
        'extra_meta': {'price': 0, 'is_free': true},
      });
      expect(app.isPublicShare, isFalse);
      expect(app.publicShare, isNull);
      expect(app.displayTitle, '[공공 나눔] 아님');
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

  Future<void> pumpDetail(
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
  }

  testWidgets('card: 뱃지 · 기관 · 이용조건 · map.jpg', (tester) async {
    await pumpCard(tester, feedItemFromJson(_ggRecycleOut()));
    expect(find.byKey(const ValueKey('public-share-badge-1974')), findsOneWidget);
    expect(find.text('공공나눔'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('share-type-1974')),
        matching: find.text('재활용센터'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('[공공 나눔]'), findsNothing);
    expect(find.text('센터 문의'), findsOneWidget);
    expect(find.textContaining('의정부지회'), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsOneWidget);
    expect(find.byKey(const ValueKey('feed-share-banner-1974')), findsNothing);
  });

  testWidgets('card: FACILITY 무이미지 → 공유시설 배너', (tester) async {
    await pumpCard(tester, feedItemFromJson(_facilityNoImageOut()));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('feed-share-banner-1980')),
        matching: find.text('공유시설'),
      ),
      findsOneWidget,
    );
    expect(find.text('무료 예약'), findsOneWidget);
  });

  testWidgets('detail: 시설 정보 · 입지 · 가이드 · 지도 CTA', (tester) async {
    await pumpDetail(tester, feedItemFromJson(_ggRecycleOut()));
    expect(find.text('경기도 · 공공데이터'), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-share-badges')), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-card-share')), findsOneWidget);
    for (final label in ['운영 기관', '이용 조건', '취급 품목', '시설 유형', '운영 안내', '위치']) {
      expect(find.byKey(ValueKey('share-row-$label')), findsOneWidget,
          reason: label);
    }
    expect(find.byKey(const ValueKey('detail-card-nearby')), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-card-share-guide')), findsOneWidget);
    expect(find.text('채팅하기'), findsNothing);
    expect(find.text('안내 사이트 이동'), findsNothing);
    expect(find.text('지도에서 보기'), findsOneWidget);

    await Scrollable.ensureVisible(
      tester.element(find.byKey(const ValueKey('detail-share-guide-tile'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('detail-share-guide-tile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('detail-share-guide-steps')), findsOneWidget);
  });

  testWidgets('detail: SEOUL detail_url → 안내 사이트 + 지도', (tester) async {
    final launched = <Uri>[];
    await pumpDetail(
      tester,
      feedItemFromJson(_seoulRecycleOut()),
      launched: launched,
    );
    expect(find.text('안내 사이트 이동'), findsOneWidget);
    expect(find.text('지도에서 보기'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('detail-info-cta')));
    await tester.pump();
    expect(launched.single.toString(), _seoulDetailUrl);
  });

  testWidgets('detail: map.jpg Hero 탭 → 뷰어 + 지도에서 보기', (tester) async {
    await pumpDetail(tester, feedItemFromJson(_ggRecycleOut()));
    expect(find.byKey(const ValueKey('detail-image-0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('detail-image-0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(FullscreenImageViewer), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-viewer-map-cta')), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(FeedDetailScreen)),
    );
    await tester.tap(find.byKey(const ValueKey('detail-viewer-map-cta')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('around-tab'), findsOneWidget);
    expect(container.read(mapFocusProvider)?.id, '1974');
  });
}
