import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/feed_item.dart';

/// 채용 핵심 정보: 모집 기관 · 급여 · 근무 시간/형태 · 마감 · 지역.
class PublicJobNoticeCard extends StatelessWidget {
  const PublicJobNoticeCard({
    super.key,
    required this.item,
    required this.onOpenUrl,
  });

  final FeedItem item;
  final ValueChanged<String> onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final notice = item.publicJob;
    if (notice == null) return const SizedBox.shrink();
    final rows = notice.summaryRows(address: item.address, title: item.title);
    return Container(
      key: const ValueKey('detail-card-job'),
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
          Text('채용 핵심 정보', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            Row(
              key: ValueKey('job-row-${rows[i].label}'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 84,
                  child: Text(rows[i].label, style: AppTypography.bodyMedium),
                ),
                Expanded(
                  child: rows[i].label == '신청'
                      ? InkWell(
                          key: const ValueKey('job-apply-link'),
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
