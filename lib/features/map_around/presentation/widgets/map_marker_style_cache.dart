import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../places/domain/models/local_place.dart';
import 'map_place_marker.dart';

/// In-memory presets for place pins and cluster badges (widget markers).
class MapMarkerStyleCache {
  MapMarkerStyleCache._();

  static final Map<String, BoxDecoration> _decorations = {};
  static final Map<int, String> _clusterLabels = {};

  static String clusterLabel(int count) {
    if (count >= 100) {
      return _clusterLabels.putIfAbsent(100, () => '99+');
    }
    return _clusterLabels.putIfAbsent(count, () => '$count');
  }

  /// Buckets: exact 2–9, shared 10–99, shared 99+.
  static int clusterBucket(int count) {
    if (count >= 100) return 100;
    if (count >= 10) return 10;
    return count.clamp(2, 9);
  }

  static BoxDecoration clusterDecoration(int count) {
    final bucket = clusterBucket(count);
    return _decorations.putIfAbsent(
      'cluster-$bucket',
      () => BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  static double clusterSize(int count) {
    final bucket = clusterBucket(count);
    if (bucket >= 100) return 48;
    if (bucket >= 10) return 42;
    return 36;
  }

  static BoxDecoration placeDecoration({
    required PlaceCategory category,
    required bool selected,
  }) {
    final key = 'place-${category.name}-$selected';
    return _decorations.putIfAbsent(key, () {
      final color = MapPlaceMarker.colorFor(category);
      return BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : Colors.white,
          width: selected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      );
    });
  }

  @visibleForTesting
  static void clearForTest() {
    _decorations.clear();
    _clusterLabels.clear();
  }
}
