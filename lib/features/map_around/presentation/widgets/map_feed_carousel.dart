import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../feed/domain/models/feed_item.dart';
import 'map_feed_marker.dart';

/// Horizontal post cards under the map; the selected one has an orange border.
class MapFeedCarousel extends StatelessWidget {
  const MapFeedCarousel({
    super.key,
    required this.controller,
    required this.items,
    required this.selectedId,
    required this.onPageChanged,
    required this.onOpen,
  });

  static const height = 116.0;

  final PageController controller;
  final List<FeedItem> items;
  final String? selectedId;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<FeedItem> onOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: PageView.builder(
        key: const ValueKey('map-carousel'),
        controller: controller,
        itemCount: items.length,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          final item = items[index];
          return _MapFeedCard(
            item: item,
            selected: item.id == selectedId,
            onTap: () => onOpen(item),
          );
        },
      ),
    );
  }
}

class _MapFeedCard extends StatelessWidget {
  const _MapFeedCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final FeedItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumb = item.thumbnailUrl;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      child: Material(
        color: AppColors.cardBackground,
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: ValueKey('map-card-${item.id}'),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: thumb.isEmpty
                        ? Container(
                            color: AppColors.surface,
                            child: Icon(
                              MapFeedMarker.iconFor(item.category),
                              color: MapFeedMarker.colorFor(item.category),
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: thumb,
                            fit: BoxFit.cover,
                            memCacheWidth: 252,
                            placeholder: (_, _) =>
                                Container(color: AppColors.border),
                            errorWidget: (_, _, _) => Container(
                              color: AppColors.surface,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium,
                      ),
                      if (item.priceOrCondition.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.priceOrCondition,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        '${item.neighborhood} · ${item.category.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
