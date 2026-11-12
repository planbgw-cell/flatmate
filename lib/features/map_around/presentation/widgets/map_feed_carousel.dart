import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../feed/domain/models/feed_extra_meta.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../../../feed/presentation/widgets/feed_thumbnail.dart';
import '../../../feed/presentation/widgets/festival_badge.dart';
import '../../../feed/presentation/widgets/public_housing_badge.dart';

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
    final secondLine = item.isFestival
        ? FeedExtraMeta(item.category, item.extraMeta).eventPeriodLabel
        : item.publicNotice?.rentSummary ?? item.priceOrCondition;
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
                    child: FeedThumbnail(item: item, memCacheWidth: 252),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.isFestival) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: FestivalBadge(
                                key: ValueKey('map-festival-badge-${item.id}'),
                                dense: true,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (item.isPublicHousing) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: HousingTypeBadge(
                                key: ValueKey('map-housing-badge-${item.id}'),
                                item: item,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              item.displayTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      if (secondLine.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          secondLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: item.isFestival ? FestivalBadge.color : null,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        item.isPublicData && item.sourceName != null
                            ? '${item.neighborhood} · 출처: ${item.sourceName}'
                            : '${item.neighborhood} · ${item.category.label}',
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
