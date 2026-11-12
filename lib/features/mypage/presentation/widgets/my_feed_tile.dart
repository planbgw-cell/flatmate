import 'package:flutter/material.dart';

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
  });

  final FeedItem item;
  final VoidCallback onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
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
                      if (item.tradeStatus != TradeStatus.selling) ...[
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
  }
}
