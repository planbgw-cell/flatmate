import 'package:flatmate_app/app/routes/route_names.dart';
import 'package:flatmate_app/core/utils/external_url.dart';
import 'package:flatmate_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flatmate_app/features/feed/data/mappers/feed_item_mapper.dart';
import 'package:flatmate_app/features/feed/data/repositories/mock_feed_repository.dart';
import 'package:flatmate_app/features/feed/domain/models/feed_item.dart';
import 'package:flatmate_app/features/feed/domain/repositories/feed_repository.dart';
import 'package:flatmate_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_detail_screen.dart';
import 'package:flatmate_app/features/feed/presentation/widgets/feed_card_item.dart';
import 'package:flatmate_app/features/location/domain/models/location_item.dart';
import 'package:flatmate_app/features/map_around/presentation/providers/map_around_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _ggApplyUrl =
    'https://www.gg.go.kr/bbs/boardView.do?bsIdx=464&bIdx=12345';

/// 서울시 공공일자리 (시급, apply_url 없음, 좌표 없음).
Map<String, dynamic> _seoulJobOut() => {
      'id': 501,
      'feed_type': 'JOB',
      'source': 'SEOUL_JOB',
      'is_public_data': true,
      'source_name': '서울시 공공일자리',
      'author_id': null,
      'title': '[공공 일자리] 서대문구 환경정비 공공근로',
      'content': '모집 기관: 서대문구청\n'
          '급여: 시급 12,121원\n'
          '근무 시간: 09:00~18:00\n'
          '모집 기간: 2026.11.01 ~ 2026.12.31\n'
          '출처: 서울시 공공일자리',
      'address': '서울특별시 서대문구',
      'lat': null,
      'lng': null,
      'extra_meta': {
        'category': 'PUBLIC_JOB',
        'job_type': 'PUBLIC_WORK',
        'company_name': '서대문구청',
        'wage_summary': '시급 12,121원',
        'work_hours': '09:00~18:00',
        'apply_url': null,
        'pay_type': 'HOURLY',
        'pay_amount': 12121,
        'event_start_date': '2026-11-01',
        'event_end_date': '2026-12-31',
      },
      'price_text': '시급 12,121원',
      'image_urls': const <String>[],
      'thumbnail_url': null,
      'published_at': '2026-11-15T09:00:00Z',
    };

/// 경기도 단기알바 (apply_url 있음, 제목 권역 토큰, 좌표 없음).
Map<String, dynamic> _ggJobOut() => {
      'id': 502,
      'feed_type': 'JOB',
      'source': 'GG_JOB',
      'is_public_data': true,
      'source_name': '경기도 일자리',
      'title': '[공공 일자리] [양평군] 도서관 단기 보조인력',
      'content': '모집 기관: 양평군청\n'
          '급여: 일급 80,000원\n'
          '신청: $_ggApplyUrl\n'
          '출처: 경기도 일자리',
      'address': null,
      'lat': null,
      'lng': null,
      'extra_meta': {
        'category': 'PUBLIC_JOB',
        'job_type': 'CONTRACT',
        'company_name': '양평군청',
        'wage_summary': '일급 80,000원',
        'work_hours': null,
        'apply_url': _ggApplyUrl,
        'event_start_date': '2026-11-10',
        'event_end_date': '2026-11-30',
      },
      'price_text': '일급 80,000원',
      'image_urls': const <String>[],
      'thumbnail_url': null,
      'published_at': '2026-11-15T10:00:00Z',
    };

/// 청년인턴 + 좌표 (지도 CTA).
Map<String, dynamic> _internJobOut() => {
      'id': 503,
      'feed_type': 'JOB',
      'source': 'SEOUL_JOB',
      'is_public_data': true,
      'source_name': '서울시 공공일자리',
      'title': '[공공 일자리] 청년 행정인턴',
      'content': '모집 기관: 서울시청\n급여: 월급 2,060,280원',
      'address': '서울특별시 중구',
      'lat': 37.5665,
      'lng': 126.9780,
      'extra_meta': {
        'category': 'PUBLIC_JOB',
        'job_type': 'INTERN',
        'company_name': '서울시청',
        'wage_summary': '월급 2,060,280원',
        'apply_url': 'https://job.seoul.go.kr/intern',
        'event_start_date': '2026-12-01',
        'event_end_date': '2026-12-15',
      },
      'price_text': '월급 2,060,280원',
      'image_urls': const <String>[],
      'thumbnail_url': null,
      'published_at': '2026-11-16T08:00:00Z',
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
    test('PublicJobType.fromCode + labels', () {
      expect(PublicJobType.fromCode('PUBLIC_WORK'), PublicJobType.publicWork);
      expect(PublicJobType.fromCode('CONTRACT').label, '단기알바');
      expect(PublicJobType.fromCode('PART_TIME').label, '단기알바');
      expect(PublicJobType.fromCode('INTERN').label, '청년인턴');
      expect(PublicJobType.fromCode('???'), PublicJobType.publicWork);
    });

    test('SEOUL_JOB: 시급 · 마감 · prefix strip · no apply_url', () {
      final item = feedItemFromJson(_seoulJobOut());
      expect(item.category, FeedCategory.job);
      expect(item.isPublicData, isTrue);
      expect(item.isPublicJob, isTrue);
      expect(item.jobType, PublicJobType.publicWork);
      expect(item.sourceName, '서울시 공공일자리');
      expect(item.displayTitle, '서대문구 환경정비 공공근로');
      expect(FeedCategory.job.label, '구인구직/알바');

      final job = item.publicJob!;
      expect(job.companyName, '서대문구청');
      expect(job.wageSummary, '시급 12,121원');
      expect(job.workHours, '09:00~18:00');
      expect(job.deadlineLabel, '2026.12.31');
      expect(job.applyUrl, isNull);
      expect(
        PublicJobNotice.regionFrom(address: item.address, title: item.title),
        '서울특별시 서대문구',
      );
    });

    test('GG_JOB: apply_url · title [양평군] region', () {
      final item = feedItemFromJson(_ggJobOut());
      expect(item.isPublicJob, isTrue);
      expect(item.jobType, PublicJobType.contract);
      final job = item.publicJob!;
      expect(job.applyUrl, _ggApplyUrl);
      expect(job.wageSummary, '일급 80,000원');
      expect(job.deadlineLabel, '2026.11.30');
      expect(
        PublicJobNotice.regionFrom(address: item.address, title: item.title),
        '양평군',
      );
    });

    test('summaryRows: 채용 핵심 정보 labels', () {
      final item = feedItemFromJson(_seoulJobOut());
      final labels = item.publicJob!
          .summaryRows(address: item.address, title: item.title)
          .map((r) => r.label)
          .toList();
      expect(labels, containsAll(['모집 기관', '급여 조건', '근무 형태', '접수 마감', '근무 지역']));
      expect(labels, isNot(contains('신청')));
    });

    test('user job posts are not public jobs', () {
      final app = feedItemFromJson({
        'id': 9,
        'feed_type': 'JOB',
        'title': '[공공 일자리] 아님',
        'extra_meta': {'wage': 12000},
      });
      expect(app.isPublicJob, isFalse);
      expect(app.publicJob, isNull);
      expect(app.displayTitle, '[공공 일자리] 아님');
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

  testWidgets('card: 뱃지 · 시급 · 기관 · 접수 마감 · 배너', (tester) async {
    final item = feedItemFromJson(_seoulJobOut());
    await pumpCard(tester, item);

    expect(find.byKey(const ValueKey('public-job-badge-501')), findsOneWidget);
    expect(find.text('공공 일자리'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('job-type-501')),
        matching: find.text('공공일자리'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('[공공 일자리]'), findsNothing);
    expect(find.byKey(const ValueKey('feed-wage-501')), findsOneWidget);
    expect(find.text('시급 12,121원'), findsOneWidget);
    expect(find.text('접수 마감 2026.12.31'), findsOneWidget);
    expect(find.textContaining('서대문구청'), findsOneWidget);
    expect(find.text('출처: 서울시 공공일자리'), findsOneWidget);
    expect(find.byKey(const ValueKey('feed-job-banner-501')), findsOneWidget);
  });

  testWidgets('card: GG 단기알바 · 양평군 · apply 없는 목록 메타', (tester) async {
    await pumpCard(tester, feedItemFromJson(_ggJobOut()));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('job-type-502')),
        matching: find.text('단기알바'),
      ),
      findsOneWidget,
    );
    expect(find.text('일급 80,000원'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('feed-meta-502'))).data,
      contains('양평군'),
    );
    expect(find.text('접수 마감 2026.11.30'), findsOneWidget);
  });

  testWidgets('detail: 채용 핵심 정보 · 지원 사이트 · no chat', (tester) async {
    final launched = <Uri>[];
    await pumpDetail(tester, feedItemFromJson(_ggJobOut()), launched: launched);

    expect(find.text('경기도 일자리 · 공공데이터'), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-job-badges')), findsOneWidget);
    expect(find.byKey(const ValueKey('feed-job-banner-502')), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-card-job')), findsOneWidget);
    for (final label in ['모집 기관', '급여 조건', '근무 형태', '접수 마감', '근무 지역', '신청']) {
      expect(find.byKey(ValueKey('job-row-$label')), findsOneWidget, reason: label);
    }
    expect(find.text('채팅하기'), findsNothing);
    expect(find.textContaining('채팅 '), findsNothing);
    expect(find.text('지원하기'), findsNothing);
    expect(find.text('지원 사이트 이동'), findsOneWidget);
    expect(find.text('지도에서 보기'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('detail-apply-cta')));
    await tester.pump();
    expect(launched.single.toString(), _ggApplyUrl);
  });

  testWidgets('detail: 좌표+apply → 지원 사이트 + 지도', (tester) async {
    final launched = <Uri>[];
    await pumpDetail(
      tester,
      feedItemFromJson(_internJobOut()),
      launched: launched,
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('job-type-503')),
        matching: find.text('청년인턴'),
      ),
      findsWidgets,
    );
    expect(find.text('지원 사이트 이동'), findsOneWidget);
    expect(find.text('지도에서 보기'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('detail-apply-cta')));
    await tester.pump();
    expect(launched.single.toString(), 'https://job.seoul.go.kr/intern');

    final container = ProviderScope.containerOf(
      tester.element(find.byType(FeedDetailScreen)),
    );
    await tester.tap(find.byKey(const ValueKey('detail-map-cta')));
    await tester.pumpAndSettle();
    expect(find.text('around-tab'), findsOneWidget);
    expect(container.read(mapFocusProvider)?.id, '503');
  });

  testWidgets('detail: SEOUL without apply/좌표 → like + wage only',
      (tester) async {
    await pumpDetail(tester, feedItemFromJson(_seoulJobOut()));
    expect(find.byKey(const ValueKey('detail-apply-cta')), findsNothing);
    expect(find.byKey(const ValueKey('detail-map-cta')), findsNothing);
    expect(find.text('지원 사이트 이동'), findsNothing);
    expect(find.text('지도에서 보기'), findsNothing);
    expect(find.text('시급 12,121원'), findsWidgets);
    expect(find.byKey(const ValueKey('detail-like')), findsOneWidget);
  });
}
