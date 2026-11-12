import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/feed_item.dart';

/// 공고 정보: 모집 기간 · 당첨자 발표 · 문의 · 신청 URL, then the notice details.
class PublicHousingNoticeCard extends StatelessWidget {
  const PublicHousingNoticeCard({
    super.key,
    required this.notice,
    required this.onOpenUrl,
  });

  final PublicHousingNotice notice;
  final ValueChanged<String> onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final rows = notice.rows;
    return Container(
      key: const ValueKey('detail-card-housing'),
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
          Text('공고 정보', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            Row(
              key: ValueKey('housing-row-${rows[i].label}'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 84,
                  child: Text(rows[i].label, style: AppTypography.bodyMedium),
                ),
                Expanded(
                  child: rows[i].label == '신청'
                      ? InkWell(
                          key: const ValueKey('housing-apply-link'),
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
