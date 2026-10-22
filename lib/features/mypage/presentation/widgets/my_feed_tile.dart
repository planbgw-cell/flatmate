import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/common_widgets/image_error_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../feed/domain/models/feed_item.dart';
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
              child: CachedNetworkImage(
                imageUrl: item.thumbnailUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: AppColors.border),
                errorWidget: (_, _, _) => const ImageErrorWidget(
                  width: 64,
                  height: 64,
                  iconSize: 22,
                ),
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
