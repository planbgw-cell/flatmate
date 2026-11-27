import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../../../feed/presentation/widgets/feed_thumbnail.dart';
import '../../../feed/presentation/widgets/trade_status_badge.dart';

/// Compact row for 내 판매글 / 관심목록 with a trailing action.
class MyFeedTile extends StatelessWidget {
  const MyFeedTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.trailing,
    this.asCard = false,
    this.showClosedBadge = false,
  });

  final FeedItem item;
  final VoidCallback onTap;
  final Widget trailing;

  /// When true, wraps content in a bordered radius-14 card (관심목록).
  final bool asCard;

  /// When true and [TradeStatus.completed], shows 「마감됨」 instead of 거래완료.
  final bool showClosedBadge;

  @override
  Widget build(BuildContext context) {
    final row = InkWell(
      onTap: onTap,
      borderRadius: asCard
          ? BorderRadius.circular(AppSpacing.cardRadius)
          : null,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: asCard ? AppSpacing.sm : AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 64,
                height: 64,
                child: FeedThumbnail(item: item, memCacheWidth: 192),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (showClosedBadge &&
                          item.tradeStatus == TradeStatus.completed) ...[
                        const _ClosedBadge(),
                        const SizedBox(width: 6),
                      ] else if (item.tradeStatus != TradeStatus.selling) ...[
                        TradeStatusBadge(
                          key: ValueKey('my-badge-${item.id}'),
                          status: item.tradeStatus,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (item.neighborhood.isNotEmpty) item.neighborhood,
                      DateFormatter.relative(item.postedAt),
                    ].join(' · '),
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.priceOrCondition,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );

    if (!asCard) return row;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: row,
      ),
    );
  }
}

class _ClosedBadge extends StatelessWidget {
  const _ClosedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('closed-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '마감됨',
        style: AppTypography.badgeText.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
