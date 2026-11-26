import 'package:flutter/material.dart';

import 'map_marker_style_cache.dart';

/// Circular count badge for a zoomed-out marker cluster.
class MapClusterBadge extends StatelessWidget {
  const MapClusterBadge({
    super.key,
    required this.count,
    required this.onTap,
  });

  static const width = 48.0;
  static const height = 48.0;

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = MapMarkerStyleCache.clusterSize(count);
    final label = MapMarkerStyleCache.clusterLabel(count);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: MapMarkerStyleCache.clusterDecoration(count),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
