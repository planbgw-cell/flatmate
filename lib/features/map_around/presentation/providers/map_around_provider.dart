import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../block_report/presentation/providers/blocked_users_provider.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../../../feed/presentation/providers/feed_provider.dart';
import '../../../location/domain/models/location_item.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../domain/map_feed_group.dart';

/// Network OSM tiles; widget tests turn them off.
final mapTilesEnabledProvider = Provider<bool>((ref) => true);

class MapAroundState {
  const MapAroundState({
    required this.centerLat,
    required this.centerLng,
    required this.items,
    required this.groups,
    this.selectedId,
  });

  /// Center of the last search (`lat` / `lng` sent to `GET /feeds`).
  final double centerLat;
  final double centerLng;

  /// Card order (a tapped marker's posts come first).
  final List<FeedItem> items;
  final List<MapFeedGroup> groups;
  final String? selectedId;

  MapFeedGroup? get selectedGroup {
    final id = selectedId;
    if (id == null) return null;
    return groups.where((g) => g.contains(id)).firstOrNull;
  }

  MapAroundState copyWith({List<FeedItem>? items, String? selectedId}) {
    return MapAroundState(
      centerLat: centerLat,
      centerLng: centerLng,
      items: items ?? this.items,
      groups: groups,
      selectedId: selectedId ?? this.selectedId,
    );
  }
}

/// 내주변: posts within [radiusKm] of the current dong (or a re-searched
/// map center), grouped into markers.
class MapAroundNotifier extends AsyncNotifier<MapAroundState> {
  static const radiusKm = 3.0;
  static const pageSize = 100;

  @override
  Future<MapAroundState> build() {
    final dong = ref.watch(currentLocationProvider);
    return _load(dong.latitude, dong.longitude);
  }

  Future<MapAroundState> _load(double lat, double lng) async {
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
      centerLat: lat,
      centerLng: lng,
      items: items,
      groups: groupFeedsByPosition(items),
      selectedId: items.firstOrNull?.id,
    );
  }

  /// "이 위치에서 재검색" / "내 동네로". The current markers stay until the
  /// new result lands.
  Future<void> searchAt(double lat, double lng) async {
    state = await AsyncValue.guard(() => _load(lat, lng));
  }

  /// Marker tap: that position's posts move to the front of the cards.
  void select(MapFeedGroup group) {
    final current = state.value;
    if (current == null) return;
    final ids = {for (final item in group.items) item.id};
    state = AsyncData(
      current.copyWith(
        items: [
          ...group.items,
          ...current.items.where((item) => !ids.contains(item.id)),
        ],
        selectedId: group.id,
      ),
    );
  }

  /// Card swipe: highlight without reordering.
  void selectFeed(String feedId) {
    final current = state.value;
    if (current == null || current.selectedId == feedId) return;
    state = AsyncData(current.copyWith(selectedId: feedId));
  }
}

final mapAroundProvider =
    AsyncNotifierProvider<MapAroundNotifier, MapAroundState>(
  MapAroundNotifier.new,
);
