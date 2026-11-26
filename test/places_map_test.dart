import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flatmate_app/app/config/app_config.dart';
import 'package:flatmate_app/core/auth/token_refresher.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/core/network/api_client.dart';
import 'package:flatmate_app/core/utils/external_url.dart';
import 'package:flatmate_app/features/feed/data/repositories/mock_feed_repository.dart';
import 'package:flatmate_app/features/feed/domain/models/feed_item.dart';
import 'package:flatmate_app/features/feed/domain/repositories/feed_repository.dart';
import 'package:flatmate_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:flatmate_app/features/location/domain/models/location_item.dart';
import 'package:flatmate_app/features/location/presentation/providers/location_provider.dart';
import 'package:flatmate_app/features/map_around/domain/map_browse_mode.dart';
import 'package:flatmate_app/features/map_around/presentation/providers/map_around_provider.dart';
import 'package:flatmate_app/features/map_around/presentation/screens/map_around_screen.dart';
import 'package:flatmate_app/features/map_around/presentation/widgets/map_category_icon_bar.dart';
import 'package:flatmate_app/features/map_around/presentation/widgets/map_place_card.dart';
import 'package:flatmate_app/features/map_around/presentation/widgets/map_place_search_overlay.dart';
import 'package:flatmate_app/features/places/data/repositories/dio_places_repository.dart';
import 'package:flatmate_app/features/places/domain/models/local_place.dart';
import 'package:flatmate_app/features/places/domain/repositories/places_repository.dart';
import 'package:flatmate_app/features/places/presentation/providers/places_provider.dart';
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

class _Places implements PlacesRepository {
  final calls =
      <({double lat, double lng, PlaceCategory? category, String? q, int radius})>[];
  NearbyPlacesResult result = const NearbyPlacesResult(items: []);

  @override
  Future<NearbyPlacesResult> nearby({
    required double lat,
    required double lng,
    PlaceCategory? category,
    String? q,
    int radius = 1000,
    int limit = 20,
  }) async {
    calls.add((lat: lat, lng: lng, category: category, q: q, radius: radius));
    return result;
  }
}

class _Feeds extends MockFeedRepository {
  _Feeds({this.around = const []});

  List<FeedItem> around;

  @override
  Future<List<FeedItem>> fetchFeeds({
    required int page,
    int pageSize = 10,
    String category = 'all',
    LocationItem? location,
    double radiusKm = 3,
    FeedSort sort = FeedSort.latest,
  }) async {
    if (page > 1) return const [];
    return around;
  }
}

LocalPlace _place({
  String id = 'p1',
  PlaceCategory category = PlaceCategory.food,
  String name = '야탑 김밥',
}) =>
    LocalPlace(
      placeId: id,
      category: category,
      subCategory: '한식',
      name: name,
      address: '성남시 분당구 야탑동 1',
      phone: '031-123-4567',
      lat: 37.413,
      lng: 127.131,
      distanceM: 180,
      placeUrl: 'http://place.map.kakao.com/123',
    );

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('PlaceCategory / LocalPlace parse', () {
    test('fromCode and nearbyPlacesFromJson', () {
      expect(PlaceCategory.fromCode('CAFE'), PlaceCategory.cafe);
      expect(PlaceCategory.fromCode('food'), PlaceCategory.food);
      final result = nearbyPlacesFromJson({
        'items': [
          {
            'place_id': '21301719',
            'category': 'FOOD',
            'sub_category': '한식',
            'name': '김밥천국',
            'address': '서울 중구',
            'phone': '02-111-2222',
            'lat': 37.41,
            'lng': 127.13,
            'distance_m': 180,
            'place_url': 'http://place.map.kakao.com/21301719',
          },
        ],
        'message': '일부 결과가 제한되었습니다.',
      });
      expect(result.message, '일부 결과가 제한되었습니다.');
      expect(result.items, hasLength(1));
      final p = result.items.single;
      expect(p.placeId, '21301719');
      expect(p.category, PlaceCategory.food);
      expect(p.distanceLabel, '180m');
    });
  });

  group('DioPlacesRepository', () {
    test('nearby sends category/radius/limit query', () async {
      final tokens = TokenStorage();
      final adapter = _FakeAdapter((options) {
        expect(options.path, '/places/nearby');
        expect(options.queryParameters['lat'], 37.41);
        expect(options.queryParameters['lng'], 127.13);
        expect(options.queryParameters['category'], 'FOOD');
        expect(options.queryParameters['radius'], 1000);
        expect(options.queryParameters['limit'], 20);
        return (
          200,
          {
            'items': [
              {
                'place_id': '1',
                'category': 'FOOD',
                'sub_category': '분식',
                'name': '분식집',
                'address': '주소',
                'lat': 37.41,
                'lng': 127.13,
                'distance_m': 50,
                'place_url': 'http://place.map.kakao.com/1',
              },
            ],
          },
        );
      });
      final config = AppConfig.resolve();
      final refresher =
          TokenRefresher(tokens: tokens, baseUrl: config.apiBaseUrl)
            ..dio.httpClientAdapter = adapter;
      final api = ApiClient(tokens: tokens, refresher: refresher, config: config);
      api.dio.httpClientAdapter = adapter;

      final result = await DioPlacesRepository(api).nearby(
        lat: 37.41,
        lng: 127.13,
        category: PlaceCategory.food,
      );
      expect(result.items.single.name, '분식집');
      expect(adapter.requests, hasLength(1));
    });

    test('nearby keyword search sends q without category', () async {
      final tokens = TokenStorage();
      final adapter = _FakeAdapter((options) {
        expect(options.queryParameters['q'], '정형외과');
        expect(options.queryParameters['radius'], 2000);
        expect(options.queryParameters.containsKey('category'), isFalse);
        return (
          200,
          {
            'items': [
              {
                'place_id': '9',
                'category': 'MEDICAL',
                'sub_category': '정형외과',
                'name': '야탑정형외과',
                'address': '성남',
                'lat': 37.41,
                'lng': 127.13,
                'distance_m': 80,
                'place_url': 'http://place.map.kakao.com/9',
              },
            ],
          },
        );
      });
      final config = AppConfig.resolve();
      final refresher =
          TokenRefresher(tokens: tokens, baseUrl: config.apiBaseUrl)
            ..dio.httpClientAdapter = adapter;
      final api = ApiClient(tokens: tokens, refresher: refresher, config: config);
      api.dio.httpClientAdapter = adapter;

      final result = await DioPlacesRepository(api).nearby(
        lat: 37.41,
        lng: 127.13,
        q: '정형외과',
        radius: 2000,
      );
      expect(result.items.single.name, '야탑정형외과');
    });
  });

  group('MapAroundNotifier mode', () {
    test('feeds ↔ FOOD switches repository calls', () async {
      final feeds = _Feeds(
        around: [
          FeedItem(
            id: '1',
            title: '책상',
            neighborhood: '야탑동',
            postedAt: DateTime(2026, 10, 24),
            priceOrCondition: '1만원',
            thumbnailUrl: '',
            likeCount: 0,
            chatCount: 0,
            category: FeedCategory.market,
            badges: const [],
            isBumped: false,
            latitude: 37.41205,
            longitude: 127.13027,
          ),
        ],
      );
      final places = _Places()
        ..result = NearbyPlacesResult(items: [_place()]);
      final container = ProviderContainer(
        overrides: [
          feedRepositoryProvider.overrideWithValue(feeds),
          placesRepositoryProvider.overrideWithValue(places),
          currentLocationProvider.overrideWith((ref) => _yatap),
          mapTilesEnabledProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      var state = await container.read(mapAroundProvider.future);
      expect(state.mode, MapBrowseMode.feeds);
      expect(state.items, hasLength(1));
      expect(places.calls, isEmpty);

      await container
          .read(mapAroundProvider.notifier)
          .setMode(const MapBrowsePlaces(PlaceCategory.food));
      state = container.read(mapAroundProvider).value!;
      expect(state.mode.placeCategory, PlaceCategory.food);
      expect(state.places.single.name, '야탑 김밥');
      expect(places.calls.single.category, PlaceCategory.food);

      await container
          .read(mapAroundProvider.notifier)
          .setMode(MapBrowseMode.feeds);
      state = container.read(mapAroundProvider).value!;
      expect(state.mode.isFeeds, isTrue);
      expect(state.items, hasLength(1));
    });

    test('applySearch then clearSearch restores feeds', () async {
      final feeds = _Feeds(
        around: [
          FeedItem(
            id: '1',
            title: '책상',
            neighborhood: '야탑동',
            postedAt: DateTime(2026, 10, 24),
            priceOrCondition: '1만원',
            thumbnailUrl: '',
            likeCount: 0,
            chatCount: 0,
            category: FeedCategory.market,
            badges: const [],
            isBumped: false,
            latitude: 37.41205,
            longitude: 127.13027,
          ),
        ],
      );
      final places = _Places();
      final container = ProviderContainer(
        overrides: [
          feedRepositoryProvider.overrideWithValue(feeds),
          placesRepositoryProvider.overrideWithValue(places),
          currentLocationProvider.overrideWith((ref) => _yatap),
          mapTilesEnabledProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);
      await container.read(mapAroundProvider.future);

      final hit = _place(id: 'ortho', name: '야탑정형외과');
      container.read(mapAroundProvider.notifier).applySearch(
            query: '정형외과',
            places: [hit],
            selected: hit,
            centerLat: _yatap.latitude,
            centerLng: _yatap.longitude,
          );
      var state = container.read(mapAroundProvider).value!;
      expect(state.mode.isSearch, isTrue);
      expect(state.mode.searchQuery, '정형외과');
      expect(state.selectedPlaceId, 'ortho');

      await container.read(mapAroundProvider.notifier).clearSearch();
      state = container.read(mapAroundProvider).value!;
      expect(state.mode.isFeeds, isTrue);
      expect(state.items, hasLength(1));
    });
  });

  testWidgets('icon bar selects FOOD with primary emphasis', (tester) async {
    MapBrowseMode mode = MapBrowseMode.feeds;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: MapCategoryIconBar(
              mode: mode,
              onChanged: (next) => setState(() => mode = next),
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('map-cat-피드/공공')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('map-cat-음식점')));
    await tester.pumpAndSettle();
    expect(mode, const MapBrowsePlaces(PlaceCategory.food));
  });

  testWidgets('place card shows CTA and launches URLs', (tester) async {
    final launched = <Uri>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          externalUrlLauncherProvider.overrideWithValue((uri) async {
            launched.add(uri);
            return true;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(body: MapPlaceCard(place: _place())),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('map-place-card')), findsOneWidget);
    expect(find.text('야탑 김밥'), findsOneWidget);
    expect(find.text('180m'), findsOneWidget);
    expect(find.text('카카오맵 상세보기'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('map-place-kakao')));
    await tester.pumpAndSettle();
    expect(launched.single.toString(), 'http://place.map.kakao.com/123');

    await tester.tap(find.byKey(const ValueKey('map-place-call')));
    await tester.pumpAndSettle();
    expect(launched.last.scheme, 'tel');
  });

  testWidgets('map places mode shows place marker and card', (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final places = _Places()
      ..result = NearbyPlacesResult(items: [_place()]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedRepositoryProvider.overrideWithValue(_Feeds()),
          placesRepositoryProvider.overrideWithValue(places),
          currentLocationProvider.overrideWith((ref) => _yatap),
          mapTilesEnabledProvider.overrideWithValue(false),
          externalUrlLauncherProvider.overrideWithValue((_) async => true),
        ],
        child: const MaterialApp(home: MapAroundScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('동네지도 · 야탑1동'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('map-cat-음식점')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-place-p1')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-place-card')), findsOneWidget);
    expect(find.text('카카오맵 상세보기'), findsOneWidget);
  });

  testWidgets('map search: suggestions → result → card + clear badge',
      (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final places = _Places()
      ..result = NearbyPlacesResult(
        items: [_place(id: 'ortho', name: '야탑정형외과')],
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedRepositoryProvider.overrideWithValue(_Feeds()),
          placesRepositoryProvider.overrideWithValue(places),
          currentLocationProvider.overrideWith((ref) => _yatap),
          mapTilesEnabledProvider.overrideWithValue(false),
          externalUrlLauncherProvider.overrideWithValue((_) async => true),
        ],
        child: const MaterialApp(home: MapAroundScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('map-search-button')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('map-search-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('map-place-search-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-place-suggest-정형외과')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('map-place-suggest-정형외과')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('map-place-search-row-ortho')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('map-place-search-row-ortho')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('map-place-card')), findsOneWidget);
    expect(find.text('야탑정형외과'), findsOneWidget);
    expect(find.byKey(const ValueKey('map-search-clear-badge')), findsOneWidget);
    expect(places.calls.last.q, '정형외과');
    expect(places.calls.last.radius, 2000);
    expect(places.calls.last.category, isNull);

    await tester.tap(find.byKey(const ValueKey('map-search-clear-badge')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-search-clear-badge')), findsNothing);
    expect(find.byKey(const ValueKey('map-place-card')), findsNothing);
  });

  testWidgets('search overlay shows hint and clear', (tester) async {
    final places = _Places();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          placesRepositoryProvider.overrideWithValue(places),
        ],
        child: const MaterialApp(
          home: MapPlaceSearchOverlay(lat: 37.41, lng: 127.13),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('상호명, 업종, 편의시설 검색 (예: 스타벅스, 정형외과)'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('map-place-search-field')),
      '다이소',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('map-place-search-clear')), findsOneWidget);
  });
}
