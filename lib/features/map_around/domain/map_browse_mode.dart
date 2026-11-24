import '../../places/domain/models/local_place.dart';

/// 동네지도 icon-bar selection: feed pins or a place category.
sealed class MapBrowseMode {
  const MapBrowseMode();

  static const feeds = MapBrowseFeeds();

  bool get isFeeds => this is MapBrowseFeeds;

  PlaceCategory? get placeCategory => switch (this) {
        MapBrowsePlaces(:final category) => category,
        MapBrowseFeeds() => null,
      };
}

final class MapBrowseFeeds extends MapBrowseMode {
  const MapBrowseFeeds();

  @override
  bool operator ==(Object other) => other is MapBrowseFeeds;

  @override
  int get hashCode => 0;
}

final class MapBrowsePlaces extends MapBrowseMode {
  const MapBrowsePlaces(this.category);

  final PlaceCategory category;

  @override
  bool operator ==(Object other) =>
      other is MapBrowsePlaces && other.category == category;

  @override
  int get hashCode => category.hashCode;
}
