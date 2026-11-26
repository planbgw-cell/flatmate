import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../block_report/presentation/providers/blocked_users_provider.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../../../feed/presentation/providers/feed_provider.dart';
import '../../../location/domain/models/location_item.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../../places/domain/models/local_place.dart';
import '../../../places/presentation/providers/places_provider.dart';
import '../../domain/map_browse_mode.dart';
import '../../domain/map_feed_group.dart';

/// Network OSM tiles; widget tests turn them off.
final mapTilesEnabledProvider = Provider<bool>((ref) => true);

/// "지도에서 보기" request from a detail screen; the 동네지도 tab centers on the
/// post, selects it and clears this.
final mapFocusProvider = StateProvider<FeedItem?>((ref) => null);

class MapAroundState {
  const MapAroundState({
    required this.mode,
    required this.centerLat,
    required this.centerLng,
    required this.items,
    required this.groups,
    required this.places,
    this.selectedId,
    this.selectedPlaceId,
    this.message,
  });

  final MapBrowseMode mode;

  /// Center of the last search (`lat` / `lng` sent to feeds or places).
  final double centerLat;
  final double centerLng;

  /// Card order (a tapped marker's posts come first). Feeds mode only.
  final List<FeedItem> items;
  final List<MapFeedGroup> groups;
  final String? selectedId;

  /// Places / keyword-search mode.
  final List<LocalPlace> places;
  final String? selectedPlaceId;
  final String? message;

  MapFeedGroup? get selectedGroup {
    final id = selectedId;
    if (id == null) return null;
    return groups.where((g) => g.contains(id)).firstOrNull;
  }

  LocalPlace? get selectedPlace {
    final id = selectedPlaceId;
    if (id == null) return null;
    return places.where((p) => p.placeId == id).firstOrNull;
  }

  MapAroundState copyWith({
    MapBrowseMode? mode,
    List<FeedItem>? items,
    List<MapFeedGroup>? groups,
    List<LocalPlace>? places,
    String? selectedId,
    String? selectedPlaceId,
    String? message,
    bool clearMessage = false,
    bool clearSelectedPlace = false,
  }) {
    return MapAroundState(
      mode: mode ?? this.mode,
      centerLat: centerLat,
      centerLng: centerLng,
      items: items ?? this.items,
      groups: groups ?? this.groups,
      places: places ?? this.places,
      selectedId: selectedId ?? this.selectedId,
      selectedPlaceId:
          clearSelectedPlace ? null : (selectedPlaceId ?? this.selectedPlaceId),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class _CacheEntry {
  const _CacheEntry(this.state, this.storedAt);

  final MapAroundState state;
  final DateTime storedAt;
}

/// 동네지도: feed pins, category places, or keyword search places.
class MapAroundNotifier extends AsyncNotifier<MapAroundState> {
  static const radiusKm = 3.0;
  static const placesRadiusM = 1000;
  static const searchRadiusM = 2000;
  static const pageSize = 100;
  static const cacheTtl = Duration(minutes: 2);

  MapBrowseMode _mode = MapBrowseMode.feeds;
  int _requestSeq = 0;
  final Map<String, _CacheEntry> _cache = {};

  /// Latest request sequence (tests assert stale discard).
  int get requestSeq => _requestSeq;

  @override
  Future<MapAroundState> build() async {
    final dong = ref.watch(currentLocationProvider);
    final seq = ++_requestSeq;
    final loaded =
        await _loadAndCache(dong.latitude, dong.longitude, _mode);
    if (seq != _requestSeq) {
      return state.value ?? loaded;
    }
    return loaded;
  }

  String _cacheKey(MapBrowseMode mode, double lat, double lng) {
    final gLat = (lat * 1000).round();
    final gLng = (lng * 1000).round();
    final modeKey = switch (mode) {
      MapBrowseFeeds() => 'feeds',
      MapBrowsePlaces(:final category) => 'places:${category.name}',
      MapBrowseSearch(:final query) => 'search:$query',
    };
    return '$modeKey|$gLat|$gLng';
  }

  MapAroundState? _cacheGet(MapBrowseMode mode, double lat, double lng) {
    final key = _cacheKey(mode, lat, lng);
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.storedAt) > cacheTtl) {
      _cache.remove(key);
      return null;
    }
    return entry.state;
  }

  void _cachePut(MapAroundState value) {
    _cache[_cacheKey(value.mode, value.centerLat, value.centerLng)] =
        _CacheEntry(value, DateTime.now());
  }

  Future<MapAroundState> _loadAndCache(
    double lat,
    double lng,
    MapBrowseMode mode,
  ) async {
    final loaded = await _load(lat, lng, mode);
    _cachePut(loaded);
    return loaded;
  }

  Future<MapAroundState> _load(
    double lat,
    double lng,
    MapBrowseMode mode,
  ) async {
    // Do not assign `_mode` here — a stale in-flight load must not clobber it.
    return switch (mode) {
      MapBrowsePlaces(:final category) =>
        _loadPlacesByCategory(lat, lng, category),
      MapBrowseSearch(:final query) => _loadPlacesByQuery(lat, lng, query),
      MapBrowseFeeds() => _loadFeeds(lat, lng),
    };
  }

  Future<MapAroundState> _loadFeeds(double lat, double lng) async {
    final dong = ref.read(currentLocationProvider);
    final center = LocationItem(
      id: 'map-center',
      cityName: dong.cityName,
      districtName: dong.districtName,
      dongName: dong.dongName,
      latitude: lat,
      longitude: lng,
    );
    final blocked = readBlockedAuthorIds(ref);
    final fetched = await ref.read(feedRepositoryProvider).fetchFeeds(
          page: 1,
          pageSize: pageSize,
          location: center,
          radiusKm: radiusKm,
        );
    final items = withoutBlockedAuthors(fetched, await blocked)
        .where((item) => feedPosition(item) != null)
        .toList();
    return MapAroundState(
      mode: MapBrowseMode.feeds,
      centerLat: lat,
      centerLng: lng,
      items: items,
      groups: groupFeedsByPosition(items),
      places: const [],
      selectedId: items.firstOrNull?.id,
    );
  }

  Future<MapAroundState> _loadPlacesByCategory(
    double lat,
    double lng,
    PlaceCategory category,
  ) async {
    final result = await ref.read(placesRepositoryProvider).nearby(
          lat: lat,
          lng: lng,
          category: category,
          radius: placesRadiusM,
          limit: 20,
        );
    return MapAroundState(
      mode: MapBrowsePlaces(category),
      centerLat: lat,
      centerLng: lng,
      items: const [],
      groups: const [],
      places: result.items,
      selectedPlaceId: result.items.firstOrNull?.placeId,
      message: result.message,
    );
  }

  Future<MapAroundState> _loadPlacesByQuery(
    double lat,
    double lng,
    String query,
  ) async {
    final result = await ref.read(placesRepositoryProvider).nearby(
          lat: lat,
          lng: lng,
          q: query,
          radius: searchRadiusM,
          limit: 20,
        );
    return MapAroundState(
      mode: MapBrowseSearch(query),
      centerLat: lat,
      centerLng: lng,
      items: const [],
      groups: const [],
      places: result.items,
      selectedPlaceId: result.items.firstOrNull?.placeId,
      message: result.message,
    );
  }

  /// Apply [result] only if [seq] is still the latest request.
  bool _commit(int seq, AsyncValue<MapAroundState> result) {
    if (seq != _requestSeq) return false;
    if (result case AsyncData(:final value)) {
      _cachePut(value);
    }
    state = result;
    return true;
  }

  Future<void> setMode(MapBrowseMode mode) async {
    if (_mode == mode && state.hasValue) return;
    final current = state.value;
    final lat = current?.centerLat ?? ref.read(currentLocationProvider).latitude;
    final lng =
        current?.centerLng ?? ref.read(currentLocationProvider).longitude;

    final cached = _cacheGet(mode, lat, lng);
    if (cached != null) {
      _requestSeq++;
      _mode = mode;
      state = AsyncData(cached);
      return;
    }

    final seq = ++_requestSeq;
    _mode = mode;
    final result = await AsyncValue.guard(() => _load(lat, lng, mode));
    _commit(seq, result);
  }

  /// Apply a keyword search hit: show [places] with [selected] focused.
  void applySearch({
    required String query,
    required List<LocalPlace> places,
    required LocalPlace selected,
    required double centerLat,
    required double centerLng,
  }) {
    _requestSeq++;
    _mode = MapBrowseSearch(query);
    final ordered = [
      selected,
      ...places.where((p) => p.placeId != selected.placeId),
    ];
    final next = MapAroundState(
      mode: MapBrowseSearch(query),
      centerLat: centerLat,
      centerLng: centerLng,
      items: const [],
      groups: const [],
      places: ordered,
      selectedPlaceId: selected.placeId,
    );
    _cachePut(next);
    state = AsyncData(next);
  }

  /// Leave keyword search and restore 피드/공공.
  Future<void> clearSearch() async {
    final current = state.value;
    final lat = current?.centerLat ?? ref.read(currentLocationProvider).latitude;
    final lng =
        current?.centerLng ?? ref.read(currentLocationProvider).longitude;

    final cached = _cacheGet(MapBrowseMode.feeds, lat, lng);
    if (cached != null) {
      _requestSeq++;
      _mode = MapBrowseMode.feeds;
      state = AsyncData(cached);
      return;
    }

    final seq = ++_requestSeq;
    _mode = MapBrowseMode.feeds;
    final result = await AsyncValue.guard(
      () => _load(lat, lng, MapBrowseMode.feeds),
    );
    _commit(seq, result);
  }

  /// "이 지역 재검색" / "내 동네로". Markers stay until the new result lands.
  Future<void> searchAt(double lat, double lng) async {
    final mode = _mode;
    final cached = _cacheGet(mode, lat, lng);
    if (cached != null) {
      _requestSeq++;
      state = AsyncData(cached);
      return;
    }

    final seq = ++_requestSeq;
    final result = await AsyncValue.guard(() => _load(lat, lng, mode));
    _commit(seq, result);
  }

  void select(MapFeedGroup group, {String? focusId}) {
    final current = state.value;
    if (current == null || !current.mode.isFeeds) return;
    final ids = {for (final item in group.items) item.id};
    final groupItems = [
      ...group.items.where((item) => item.id == focusId),
      ...group.items.where((item) => item.id != focusId),
    ];
    state = AsyncData(
      current.copyWith(
        items: [
          ...groupItems,
          ...current.items.where((item) => !ids.contains(item.id)),
        ],
        selectedId: groupItems.first.id,
      ),
    );
  }

  void selectPlace(LocalPlace place) {
    final current = state.value;
    if (current == null || current.mode.isFeeds) return;
    if (current.selectedPlaceId == place.placeId) return;
    state = AsyncData(current.copyWith(selectedPlaceId: place.placeId));
  }

  /// "지도에서 보기": switch to feeds mode, search around [item], select it.
  Future<void> focus(FeedItem item) async {
    final position = feedPosition(item);
    if (position == null) return;
    _mode = MapBrowseMode.feeds;
    await searchAt(position.lat, position.lng);
    var current = state.value;
    if (current == null) return;
    if (!current.items.any((e) => e.id == item.id)) {
      final items = [item, ...current.items];
      current = MapAroundState(
        mode: MapBrowseMode.feeds,
        centerLat: current.centerLat,
        centerLng: current.centerLng,
        items: items,
        groups: groupFeedsByPosition(items),
        places: const [],
      );
      state = AsyncData(current);
    }
    final group = current.groups.firstWhere((g) => g.contains(item.id));
    select(group, focusId: item.id);
  }

  /// Card swipe: highlight without reordering.
  void selectFeed(String feedId) {
    final current = state.value;
    if (current == null || current.selectedId == feedId) return;
    state = AsyncData(current.copyWith(selectedId: feedId));
  }

  void clearMessage() {
    final current = state.value;
    if (current == null || current.message == null) return;
    state = AsyncData(current.copyWith(clearMessage: true));
  }

  /// Test helper: seed cache without network.
  void debugPutCache(MapAroundState value) => _cachePut(value);
}

final mapAroundProvider =
    AsyncNotifierProvider<MapAroundNotifier, MapAroundState>(
  MapAroundNotifier.new,
);
