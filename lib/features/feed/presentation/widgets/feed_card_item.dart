import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common_widgets/badge_chip.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/models/feed_extra_meta.dart';
import '../../domain/models/feed_item.dart';
import '../../domain/models/region.dart';
import '../providers/feed_provider.dart';
import 'feed_thumbnail.dart';
import 'festival_badge.dart';
import 'like_heart.dart';
import 'public_housing_badge.dart';
import 'trade_status_badge.dart';

class FeedCardItem extends ConsumerWidget {
  const FeedCardItem({
    super.key,
    required this.item,
    required this.onTap,
    this.onFavoriteToggle,
    this.showRegion = false,
  });

  final FeedItem item;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  /// 권역 lists: festivals show "[수도권 축제] 경기 가평군" so far-away events
  /// read as such.
  final bool showRegion;

  static const _thumb = 90.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fav = ref.watch(favoriteItemProvider(item.id));
    final likeCount = fav.likeCount > 0 || fav.isFavorite
        ? fav.likeCount
        : item.likeCount;
    final liked = fav.isFavorite;
    final festivalPeriod = item.isFestival
        ? FeedExtraMeta(item.category, item.extraMeta).eventPeriodLabel
        : '';
    final zone = showRegion && item.isFestival
        ? zoneOfAddress(item.address)
        : null;
    final region = zone == null ? '' : regionLabel(item.address);
    final notice = item.publicNotice;
    final noticeRegion =
        notice == null ? '' : noticeRegionLabel(item.address ?? notice.address);

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
                  child: FeedThumbnail(
                    key: ValueKey('feed-thumb-${item.id}'),
                    item: item,
                    memCacheWidth: 270,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notice != null) ...[
                    PublicHousingBadges(item: item),
                    const SizedBox(height: AppSpacing.xxs),
                  ],
                  if (zone != null) ...[
                    Row(
                      key: ValueKey('festival-region-${item.id}'),
                      children: [
                        FestivalBadge(label: '$zone 축제'),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            region,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.badgeText.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                  ],
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
                      if (item.isFestival && zone == null) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: FestivalBadge(
                            key: ValueKey('festival-badge-${item.id}'),
                          ),
                        ),
                        const SizedBox(width: 6),
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
                  const SizedBox(height: AppSpacing.xxs),
                  if (noticeRegion.isNotEmpty)
                    Row(
                      key: ValueKey('feed-meta-${item.id}'),
                      children: [
                        Flexible(
                          child: Text(
                            noticeRegion,
                            key: ValueKey('feed-region-${item.id}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          ' · ${_timeLabel(item)}',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    )
                  else
                    Text(
                      [
                        if (!item.isPublicData) item.authorName,
                        if (item.neighborhood.isNotEmpty) item.neighborhood,
                        _timeLabel(item),
                      ].join(' · '),
                      key: ValueKey('feed-meta-${item.id}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium,
                    ),
                  if (item.isPublicData && item.sourceName != null)
                    SourceLabel(
                      key: ValueKey('feed-source-${item.id}'),
                      sourceName: item.sourceName!,
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  if (notice != null) ...[
                    Text(
                      notice.rentSummary,
                      key: ValueKey('feed-rent-${item.id}'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (notice.applyPeriod case final period?)
                      Text(
                        '모집 $period',
                        key: ValueKey('feed-apply-period-${item.id}'),
                        style: AppTypography.caption.copyWith(
                          color: PublicBenefitBadge.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                  ] else if (item.isFestival && festivalPeriod.isNotEmpty) ...[
                    Text(
                      festivalPeriod,
                      key: ValueKey('feed-period-${item.id}'),
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: FestivalBadge.color,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ] else if (item.priceOrCondition.isNotEmpty) ...[
                    Text(
                      item.priceOrCondition,
                      key: ValueKey('feed-price-${item.id}'),
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
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
