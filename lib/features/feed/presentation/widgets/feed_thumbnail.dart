import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/feed_item.dart';
import 'feed_visual.dart';

/// Post image, or a kind-specific placeholder (e.g. 행복주택 / 공공임대 for LH
/// notices that ship without images) when the URL is empty or fails.
class FeedThumbnail extends StatelessWidget {
  const FeedThumbnail({
    super.key,
    required this.item,
    this.url,
    this.memCacheWidth,
    this.large = false,
  });

  final FeedItem item;

  /// Defaults to [FeedItem.thumbnailUrl].
  final String? url;
  final int? memCacheWidth;

  /// Detail-header size: bigger icon plus the kind label.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final src = (url ?? item.thumbnailUrl).trim();
    if (src.isEmpty) return FeedPlaceholder(item: item, large: large);
    return CachedNetworkImage(
      imageUrl: src,
      fit: BoxFit.cover,
      memCacheWidth: memCacheWidth,
      placeholder: (_, _) => Container(color: AppColors.border),
      errorWidget: (_, _, _) => FeedPlaceholder(item: item, large: large),
    );
  }
}

class FeedPlaceholder extends StatelessWidget {
  const FeedPlaceholder({super.key, required this.item, this.large = false});

  final FeedItem item;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final visual = feedVisual(item);
    final label = item.housingType?.label ??
        (item.isFestival ? '축제' : item.category.label);
    return Container(
      key: ValueKey('feed-placeholder-${item.id}'),
      color: visual.color.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visual.icon, size: large ? 72 : 34, color: visual.color),
          if (large) ...[
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.titleMedium.copyWith(color: visual.color),
            ),
          ],
        ],
      ),
    );
  }
}
