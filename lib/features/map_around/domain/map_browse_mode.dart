import '../../places/domain/models/local_place.dart';

/// 동네지도 icon-bar / keyword search selection.
sealed class MapBrowseMode {
  const MapBrowseMode();

  static const feeds = MapBrowseFeeds();

  bool get isFeeds => this is MapBrowseFeeds;

  bool get isSearch => this is MapBrowseSearch;

  bool get showsPlaces => this is MapBrowsePlaces || this is MapBrowseSearch;

  PlaceCategory? get placeCategory => switch (this) {
        MapBrowsePlaces(:final category) => category,
        MapBrowseFeeds() || MapBrowseSearch() => null,
      };

  String? get searchQuery => switch (this) {
        MapBrowseSearch(:final query) => query,
        _ => null,
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

final class MapBrowseSearch extends MapBrowseMode {
  const MapBrowseSearch(this.query);

  final String query;

  @override
  bool operator ==(Object other) =>
      other is MapBrowseSearch && other.query == query;

  @override
  int get hashCode => query.hashCode;
}
