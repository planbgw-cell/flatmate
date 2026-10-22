import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common_widgets/badge_chip.dart';
import '../../../../core/common_widgets/image_error_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/models/feed_item.dart';
import '../providers/feed_provider.dart';
import 'like_heart.dart';
import 'trade_status_badge.dart';

class FeedCardItem extends ConsumerWidget {
  const FeedCardItem({
    super.key,
    required this.item,
    required this.onTap,
    this.onFavoriteToggle,
  });

  final FeedItem item;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  static const _thumb = 90.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fav = ref.watch(favoriteItemProvider(item.id));
    final likeCount = fav.likeCount > 0 || fav.isFavorite
        ? fav.likeCount
        : item.likeCount;
    final liked = fav.isFavorite;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _thumb,
              height: _thumb,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CachedNetworkImage(
                    imageUrl: item.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: AppColors.border),
                    errorWidget: (_, _, _) => const ImageErrorWidget(
                      iconSize: 28,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.tradeStatus != TradeStatus.selling) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: TradeStatusBadge(
                            key: ValueKey('trade-badge-${item.id}'),
                            status: item.tradeStatus,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    [
                      item.authorName,
                      if (item.neighborhood.isNotEmpty) item.neighborhood,
                      _timeLabel(item),
                    ].join(' · '),
                    key: ValueKey('feed-meta-${item.id}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.priceOrCondition,
                    key: ValueKey('feed-price-${item.id}'),
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: AppSpacing.xxs,
                          runSpacing: AppSpacing.xxs,
                          children: item.badges
                              .take(3)
                              .map(_badgeChip)
                              .toList(),
                        ),
                      ),
                      InkWell(
                        key: ValueKey('feed-like-${item.id}'),
                        onTap: onFavoriteToggle,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LikeHeart(liked: liked, size: 16),
                              if (likeCount > 0) ...[
                                const SizedBox(width: 2),
                                Text(
                                  '$likeCount',
                                  key: ValueKey('feed-like-count-${item.id}'),
                                  style: AppTypography.caption.copyWith(
                                    color: liked
                                        ? AppColors.primary
                                        : AppColors.textHint,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _CountIcon(
                        icon: Icons.chat_bubble_outline,
                        count: item.chatCount,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BadgeChip _badgeChip(FeedBadge badge) {
    final type = switch (badge) {
      FeedBadge.urgent => BadgeType.urgent,
      FeedBadge.bumped || FeedBadge.sharing => BadgeType.success,
      FeedBadge.shortStay || FeedBadge.roommate || FeedBadge.housing =>
        BadgeType.warning,
      _ => BadgeType.normal,
    };
    return BadgeChip(label: badge.label, type: type);
  }

  String _timeLabel(FeedItem item) {
    final relative = DateFormatter.relative(item.postedAt);
    if (item.isBumped) return '끌올 $relative';
    return relative;
  }
}

class _CountIcon extends StatelessWidget {
  const _CountIcon({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 2),
        Text('$count', style: AppTypography.caption),
      ],
    );
  }
}
