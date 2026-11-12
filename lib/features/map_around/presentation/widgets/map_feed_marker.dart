import 'package:flutter/material.dart';

import '../../../feed/domain/models/feed_item.dart';
import '../../../feed/presentation/widgets/feed_visual.dart';
import '../../domain/map_feed_group.dart';

/// Marker pin: category icon + price badge, or a 건수 badge for a group.
class MapFeedMarker extends StatelessWidget {
  const MapFeedMarker({
    super.key,
    required this.group,
    required this.selected,
    required this.onTap,
  });

  static const width = 112.0;
  static const height = 48.0;

  final MapFeedGroup group;
  final bool selected;
  final VoidCallback onTap;

  /// 축제 / 공공 주거 types / categories (see [feedVisual]).
  static Color colorFor(FeedItem item) => feedVisual(item).color;

  static IconData iconFor(FeedItem item) => feedVisual(item).icon;

  @override
  Widget build(BuildContext context) {
    final lead = group.items.first;
    final color = colorFor(lead);
    final count = group.items.length;
    final label = count > 1 ? '$count건' : markerLabel(lead);
    final background = selected ? color : Colors.white;
    final foreground = selected ? Colors.white : color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.15 : 1,
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    count > 1 ? Icons.layers : iconFor(lead),
                    size: 14,
                    color: foreground,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}
