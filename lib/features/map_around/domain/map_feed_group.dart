import '../../feed/domain/models/feed_item.dart';
import '../../location/domain/models/location_item.dart';

/// Posts sharing one map position (server posts often sit on a dong
/// center), shown as a single marker.
class MapFeedGroup {
  const MapFeedGroup({
    required this.latitude,
    required this.longitude,
    required this.items,
  });

  final double latitude;
  final double longitude;
  final List<FeedItem> items;

  /// Marker id: the first post in feed order.
  String get id => items.first.id;

  bool contains(String feedId) => items.any((item) => item.id == feedId);
}

/// Server `lat` / `lng`, else the mock neighborhood anchor; null if neither.
({double lat, double lng})? feedPosition(FeedItem item) {
  final lat = item.latitude;
  final lng = item.longitude;
  if (lat != null && lng != null) return (lat: lat, lng: lng);
  final anchor = locationForNeighborhood(item.neighborhood);
  if (anchor == null) return null;
  return (lat: anchor.latitude, lng: anchor.longitude);
}

/// Groups by position rounded to 5 decimals (~1 m), keeping feed order.
List<MapFeedGroup> groupFeedsByPosition(List<FeedItem> items) {
  final groups = <String, ({double lat, double lng, List<FeedItem> items})>{};
  for (final item in items) {
    final position = feedPosition(item);
    if (position == null) continue;
    final key = '${position.lat.toStringAsFixed(5)},'
        '${position.lng.toStringAsFixed(5)}';
    groups.putIfAbsent(
      key,
      () => (lat: position.lat, lng: position.lng, items: <FeedItem>[]),
    ).items.add(item);
  }
  return [
    for (final group in groups.values)
      MapFeedGroup(
        latitude: group.lat,
        longitude: group.lng,
        items: List.unmodifiable(group.items),
      ),
  ];
}

/// Short marker badge: the price line (truncated) or the category name.
String markerLabel(FeedItem item) {
  final price = item.priceOrCondition.trim();
  final text = price.isEmpty ? item.category.label : price;
  return text.length <= 9 ? text : '${text.substring(0, 8)}…';
}
