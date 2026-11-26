import 'dart:async';

import 'package:flatmate_app/features/feed/data/repositories/mock_feed_repository.dart';
import 'package:flatmate_app/features/feed/domain/models/feed_item.dart';
import 'package:flatmate_app/features/feed/domain/repositories/feed_repository.dart';
import 'package:flatmate_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:flatmate_app/features/location/domain/models/location_item.dart';
import 'package:flatmate_app/features/location/presentation/providers/location_provider.dart';
import 'package:flatmate_app/features/map_around/domain/map_browse_mode.dart';
import 'package:flatmate_app/features/map_around/domain/map_marker_cluster.dart';
import 'package:flatmate_app/features/map_around/presentation/providers/map_around_provider.dart';
import 'package:flatmate_app/features/map_around/presentation/widgets/map_marker_style_cache.dart';
import 'package:flatmate_app/features/places/domain/models/local_place.dart';
import 'package:flatmate_app/features/places/domain/repositories/places_repository.dart';
import 'package:flatmate_app/features/places/presentation/providers/places_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _yatap = LocationItem(
  id: '15',
  cityName: '성남시',
  districtName: '분당구',
  dongName: '야탑1동',
  latitude: 37.41205,
  longitude: 127.13027,
);

void main() {
  group('clusterMapPoints', () {
    test('zoom >= 14.5 returns individual pins inside bounds', () {
      final items = clusterMapPoints(
        points: const [
          MapClusterPoint(id: 'a', lat: 37.41, lng: 127.13),
          MapClusterPoint(id: 'b', lat: 37.411, lng: 127.131),
        ],
        zoom: 14.5,
        bounds: const MapLatLngBounds(
          south: 37.40,
          west: 127.12,
          north: 37.42,
          east: 127.14,
        ),
      );
      expect(items, hasLength(2));
      expect(items.whereType<MapOverlayPin>(), hasLength(2));
    });

    test('zoom < 14.5 groups nearby points into a cluster', () {
      final items = clusterMapPoints(
        points: const [
          MapClusterPoint(id: 'a', lat: 37.4120, lng: 127.1300),
          MapClusterPoint(id: 'b', lat: 37.4121, lng: 127.1301),
          MapClusterPoint(id: 'c', lat: 37.4122, lng: 127.1302),
        ],
        zoom: 12.0,
      );
      expect(items, hasLength(1));
      final cluster = items.single as MapOverlayCluster;
      expect(cluster.count, 3);
      expect(cluster.label, '3');
      expect(cluster.memberIds, ['a', 'b', 'c']);
    });

    test('label uses 99+ for counts >= 100', () {
      final points = [
        for (var i = 0; i < 120; i++)
          MapClusterPoint(
            id: '$i',
            lat: 37.41 + (i % 3) * 0.00001,
            lng: 127.13 + (i % 3) * 0.00001,
          ),
      ];
      final items = clusterMapPoints(points: points, zoom: 10.0);
      expect(items, isNotEmpty);
      final cluster = items.whereType<MapOverlayCluster>().first;
      expect(cluster.count, greaterThanOrEqualTo(100));
      expect(cluster.label, '99+');
    });

    test('viewport filter drops points outside bounds', () {
      final items = clusterMapPoints(
        points: const [
          MapClusterPoint(id: 'in', lat: 37.41, lng: 127.13),
          MapClusterPoint(id: 'out', lat: 37.50, lng: 127.20),
        ],
        zoom: 15.0,
        bounds: const MapLatLngBounds(
          south: 37.405,
          west: 127.125,
          north: 37.415,
          east: 127.135,
        ),
      );
      expect(items, hasLength(1));
      expect((items.single as MapOverlayPin).id, 'in');
    });

    test('bounds.padded expands by margin fraction', () {
      const raw = MapLatLngBounds(
        south: 0,
        west: 0,
        north: 10,
        east: 20,
      );
      final padded = raw.padded(0.15);
      expect(padded.south, -1.5);
      expect(padded.north, 11.5);
      expect(padded.west, -3.0);
      expect(padded.east, 23.0);
    });
  });

  group('MapMarkerStyleCache', () {
    tearDown(MapMarkerStyleCache.clearForTest);

    test('clusterLabel and bucket', () {
      expect(MapMarkerStyleCache.clusterLabel(7), '7');
      expect(MapMarkerStyleCache.clusterLabel(42), '42');
      expect(MapMarkerStyleCache.clusterLabel(100), '99+');
      expect(MapMarkerStyleCache.clusterBucket(7), 7);
      expect(MapMarkerStyleCache.clusterBucket(42), 10);
      expect(MapMarkerStyleCache.clusterBucket(150), 100);
    });
  });

  group('MapAroundNotifier request seq + cache', () {
    test('stale setMode response is discarded', () async {
      final places = _DeferredPlaces();
      final feeds = _Feeds();
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

      final notifier = container.read(mapAroundProvider.notifier);
      final foodGate = Completer<NearbyPlacesResult>();
      places.enqueue(foodGate.future);

      final foodFuture =
          notifier.setMode(const MapBrowsePlaces(PlaceCategory.food));
      await Future<void>.delayed(Duration.zero);

      places.enqueue(
        Future.value(
          NearbyPlacesResult(
            items: [
              _place(id: 'cafe', category: PlaceCategory.cafe, name: '카페'),
            ],
          ),
        ),
      );
      await notifier.setMode(const MapBrowsePlaces(PlaceCategory.cafe));

      foodGate.complete(
        NearbyPlacesResult(
          items: [
            _place(id: 'food', category: PlaceCategory.food, name: '김밥'),
          ],
        ),
      );
      await foodFuture;

      final state = container.read(mapAroundProvider).value!;
      expect(state.mode.placeCategory, PlaceCategory.cafe);
      expect(state.places.single.placeId, 'cafe');
    });

    test('cache hit skips network on category round-trip', () async {
      final places = _Places();
      final feeds = _Feeds();
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

      final notifier = container.read(mapAroundProvider.notifier);
      await notifier.setMode(const MapBrowsePlaces(PlaceCategory.food));
      expect(places.calls, hasLength(1));

      await notifier.setMode(MapBrowseMode.feeds);
      await notifier.setMode(const MapBrowsePlaces(PlaceCategory.food));
      expect(places.calls, hasLength(1), reason: 'second FOOD uses cache');
      expect(
        container.read(mapAroundProvider).value!.places.single.placeId,
        'p1',
      );
    });
  });
}

LocalPlace _place({
  String id = 'p1',
  PlaceCategory category = PlaceCategory.food,
  String name = '야탑 김밥',
}) {
  return LocalPlace(
    placeId: id,
    category: category,
    subCategory: '분식',
    name: name,
    address: '성남',
    lat: _yatap.latitude,
    lng: _yatap.longitude,
    distanceM: 50,
    placeUrl: 'http://place.map.kakao.com/$id',
  );
}

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

class _Places implements PlacesRepository {
  final calls = <PlaceCategory?>[];

  @override
  Future<NearbyPlacesResult> nearby({
    required double lat,
    required double lng,
    PlaceCategory? category,
    String? q,
    int radius = 1000,
    int limit = 20,
  }) async {
    calls.add(category);
    return NearbyPlacesResult(
      items: [_place(category: category ?? PlaceCategory.food)],
    );
  }
}

class _DeferredPlaces implements PlacesRepository {
  final _queue = <Future<NearbyPlacesResult>>[];

  void enqueue(Future<NearbyPlacesResult> future) => _queue.add(future);

  @override
  Future<NearbyPlacesResult> nearby({
    required double lat,
    required double lng,
    PlaceCategory? category,
    String? q,
    int radius = 1000,
    int limit = 20,
  }) {
    if (_queue.isEmpty) {
      return Future.value(
        NearbyPlacesResult(
          items: [
            _place(
              id: category?.name ?? 'x',
              category: category ?? PlaceCategory.food,
            ),
          ],
        ),
      );
    }
    return _queue.removeAt(0);
  }
}
