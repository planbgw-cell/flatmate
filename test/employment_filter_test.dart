import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flatmate_app/app/config/app_config.dart';
import 'package:flatmate_app/core/auth/token_refresher.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/core/network/api_client.dart';
import 'package:flatmate_app/features/feed/data/repositories/dio_feed_repository.dart';
import 'package:flatmate_app/features/feed/data/repositories/mock_feed_repository.dart';
import 'package:flatmate_app/features/feed/domain/models/employment_type.dart';
import 'package:flatmate_app/features/feed/domain/models/feed_item.dart';
import 'package:flatmate_app/features/feed/domain/repositories/feed_repository.dart';
import 'package:flatmate_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_screen.dart';
import 'package:flatmate_app/features/location/domain/models/location_item.dart';
import 'package:flatmate_app/features/location/domain/repositories/location_repository.dart';
import 'package:flatmate_app/features/location/presentation/providers/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const _yatap = LocationItem(
  id: '15',
  cityName: '성남시',
  districtName: '분당구',
  dongName: '야탑1동',
  latitude: 37.41205,
  longitude: 127.13027,
);

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final (int, Object?) Function(RequestOptions options) respond;
  final requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = respond(options);
    final bytes = body == null
        ? Uint8List(0)
        : Uint8List.fromList(utf8.encode(jsonEncode(body)));
    return ResponseBody.fromBytes(
      bytes,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _Locations implements LocationRepository {
  @override
  Future<List<LocationItem>> search(String query) async => const [];

  @override
  Future<LocationItem?> getReverseGeo(double lat, double lng) async => _yatap;
}

class _Feeds extends MockFeedRepository {
  final scopedCalls = <({String category, String? employmentType})>[];

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

  @override
  Future<List<FeedItem>> fetchScopedFeeds({
    required String category,
    required int locationId,
    PublicScope scope = PublicScope.sigungu,
    LocationItem? origin,
    FeedSort sort = FeedSort.latest,
    int page = 1,
    int pageSize = 20,
    String? employmentType,
  }) async {
    scopedCalls.add((category: category, employmentType: employmentType));
    return const [];
  }
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('EmploymentType codes and labels', () {
    expect(EmploymentType.all.code, 'ALL');
    expect(EmploymentType.partTime.label, '단기·알바');
    expect(EmploymentType.intern.label, '청년인턴');
    expect(EmploymentType.public.label, '공공일자리');
    expect(EmploymentType.fromCode('PART_TIME'), EmploymentType.partTime);
  });

  test('DioFeedRepository sends employment_type on scoped job fetch', () async {
    final tokens = TokenStorage();
    final adapter = _FakeAdapter((options) {
      expect(options.path, '/feeds');
      expect(options.queryParameters['feed_type'], 'JOB');
      expect(options.queryParameters['employment_type'], 'PART_TIME');
      expect(options.queryParameters['public_scope'], 'zone');
      return (200, <dynamic>[]);
    });
    final config = AppConfig.resolve();
    final refresher =
        TokenRefresher(tokens: tokens, baseUrl: config.apiBaseUrl)
          ..dio.httpClientAdapter = adapter;
    final api = ApiClient(tokens: tokens, refresher: refresher, config: config);
    api.dio.httpClientAdapter = adapter;

    await DioFeedRepository(api).fetchScopedFeeds(
      category: FeedCategory.job.name,
      locationId: 15,
      scope: PublicScope.zone,
      employmentType: EmploymentType.partTime.code,
    );
    expect(adapter.requests, hasLength(1));
  });

  test('feedListProvider passes employment_type for job chip', () async {
    final feeds = _Feeds();
    final container = ProviderContainer(
      overrides: [
        feedRepositoryProvider.overrideWithValue(feeds),
        locationRepositoryProvider.overrideWithValue(_Locations()),
        currentLocationProvider.overrideWith((ref) => _yatap),
      ],
    );
    addTearDown(container.dispose);

    container.read(selectedCategoryProvider.notifier).state =
        FeedCategory.job.name;
    container.read(selectedEmploymentTypeProvider.notifier).state =
        EmploymentType.intern;
    await container.read(feedListProvider.future);

    expect(feeds.scopedCalls.single.category, FeedCategory.job.name);
    expect(feeds.scopedCalls.single.employmentType, 'INTERN');
  });

  testWidgets('job chip shows employment sub-bar; housing hides it',
      (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final feeds = _Feeds();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedRepositoryProvider.overrideWithValue(feeds),
          locationRepositoryProvider.overrideWithValue(_Locations()),
          currentLocationProvider.overrideWith((ref) => _yatap),
          selectedCategoryProvider.overrideWith((ref) => FeedCategory.job.name),
        ],
        child: const MaterialApp(home: FeedScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('job-employment-filter-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('job-employment-ALL')), findsOneWidget);
    expect(find.byKey(const ValueKey('job-employment-PART_TIME')), findsOneWidget);
    expect(find.byKey(const ValueKey('job-employment-INTERN')), findsOneWidget);
    expect(find.byKey(const ValueKey('job-employment-PUBLIC')), findsOneWidget);
    expect(find.text('선택한 조건의 일자리 공고가 아직 없어요'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('job-employment-PART_TIME')));
    await tester.pumpAndSettle();
    expect(
      feeds.scopedCalls.last.employmentType,
      EmploymentType.partTime.code,
    );

    await tester.tap(find.text('룸메·주거'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('job-employment-filter-bar')), findsNothing);
  });
}
