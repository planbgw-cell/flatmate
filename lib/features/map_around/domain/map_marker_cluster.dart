/// Lightweight geographic bounds (south/west → north/east).
class MapLatLngBounds {
  const MapLatLngBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final double south;
  final double west;
  final double north;
  final double east;

  bool contains(double lat, double lng) =>
      lat >= south && lat <= north && lng >= west && lng <= east;

  /// Expand each edge by [margin] fraction of the span (e.g. 0.15 = 15%).
  MapLatLngBounds padded(double margin) {
    final latPad = (north - south) * margin;
    final lngPad = (east - west) * margin;
    return MapLatLngBounds(
      south: south - latPad,
      west: west - lngPad,
      north: north + latPad,
      east: east + lngPad,
    );
  }
}

class MapClusterPoint {
  const MapClusterPoint({
    required this.id,
    required this.lat,
    required this.lng,
  });

  final String id;
  final double lat;
  final double lng;
}

/// Result of [clusterMapPoints]: either a single pin or a count badge.
sealed class MapOverlayItem {
  const MapOverlayItem();

  double get lat;
  double get lng;
}

final class MapOverlayPin extends MapOverlayItem {
  const MapOverlayPin({
    required this.id,
    required this.lat,
    required this.lng,
  });

  final String id;

  @override
  final double lat;

  @override
  final double lng;
}

final class MapOverlayCluster extends MapOverlayItem {
  const MapOverlayCluster({
    required this.lat,
    required this.lng,
    required this.count,
    required this.memberIds,
  });

  @override
  final double lat;

  @override
  final double lng;

  final int count;
  final List<String> memberIds;

  /// Display text: `99+` when [count] ≥ 100.
  String get label => count >= 100 ? '99+' : '$count';
}

/// Zoom below this shows grid clusters; at/above shows individual pins.
const mapClusterZoomThreshold = 14.5;

/// Target on-screen cell size (px) used to derive geographic grid size.
const _clusterCellPx = 56.0;

/// Web-Mercator world width in pixels at zoom 0.
const _tileSize = 256.0;

/// Groups [points] by viewport + zoom. Pure Dart — no Flutter/map SDK.
List<MapOverlayItem> clusterMapPoints({
  required List<MapClusterPoint> points,
  required double zoom,
  MapLatLngBounds? bounds,
  double clusterBelowZoom = mapClusterZoomThreshold,
}) {
  final visible = bounds == null
      ? points
      : points.where((p) => bounds.contains(p.lat, p.lng)).toList();

  if (visible.isEmpty) return const [];

  if (zoom >= clusterBelowZoom) {
    return [
      for (final p in visible)
        MapOverlayPin(id: p.id, lat: p.lat, lng: p.lng),
    ];
  }

  // Degrees spanned by one ~[_clusterCellPx] cell at this zoom.
  final degreesPerPx = 360.0 / (_tileSize * (1 << zoom.floor()).toDouble());
  final cellDeg = degreesPerPx * _clusterCellPx;
  if (cellDeg <= 0) {
    return [
      for (final p in visible)
        MapOverlayPin(id: p.id, lat: p.lat, lng: p.lng),
    ];
  }

  final cells = <String, List<MapClusterPoint>>{};
  for (final p in visible) {
    final gx = (p.lng / cellDeg).floor();
    final gy = (p.lat / cellDeg).floor();
    cells.putIfAbsent('$gx:$gy', () => <MapClusterPoint>[]).add(p);
  }

  final out = <MapOverlayItem>[];
  for (final members in cells.values) {
    if (members.length == 1) {
      final p = members.first;
      out.add(MapOverlayPin(id: p.id, lat: p.lat, lng: p.lng));
      continue;
    }
    var sumLat = 0.0;
    var sumLng = 0.0;
    for (final p in members) {
      sumLat += p.lat;
      sumLng += p.lng;
    }
    final n = members.length;
    out.add(
      MapOverlayCluster(
        lat: sumLat / n,
        lng: sumLng / n,
        count: n,
        memberIds: [for (final p in members) p.id],
      ),
    );
  }
  return out;
}
