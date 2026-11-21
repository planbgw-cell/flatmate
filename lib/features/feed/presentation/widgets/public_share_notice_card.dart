import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/feed_item.dart';

/// 나눔·공유 시설 정보: 운영 기관 · 이용 조건 · 취급 · 위치 · 안내.
class PublicShareNoticeCard extends StatelessWidget {
  const PublicShareNoticeCard({
    super.key,
    required this.item,
    required this.onOpenUrl,
  });

  final FeedItem item;
  final ValueChanged<String> onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final notice = item.publicShare;
    if (notice == null) return const SizedBox.shrink();
    final rows = notice.summaryRows(address: item.address, title: item.title);
    return Container(
      key: const ValueKey('detail-card-share'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('나눔·공유 시설 정보', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            Row(
              key: ValueKey('share-row-${rows[i].label}'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 84,
                  child: Text(rows[i].label, style: AppTypography.bodyMedium),
                ),
                Expanded(
                  child: rows[i].label == '안내'
                      ? InkWell(
                          key: const ValueKey('share-info-link'),
                          onTap: () => onOpenUrl(rows[i].value),
                          child: Text(
                            rows[i].value,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        )
                      : SelectableText(
                          rows[i].value,
                          style: AppTypography.bodyLarge,
                        ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
