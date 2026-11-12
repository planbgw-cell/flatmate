import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/feed_item.dart';

/// [축제] badge for 한국관광공사 festival posts.
class FestivalBadge extends StatelessWidget {
  const FestivalBadge({super.key, this.dense = false, this.label = '축제'});

  static const color = Color(0xFFE5487F);

  final bool dense;

  /// "축제", or a 권역 label such as "수도권 축제".
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 5 : 7,
        vertical: dense ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: AppTypography.badgeText.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// "출처: 한국관광공사" for public-data posts.
class SourceLabel extends StatelessWidget {
  const SourceLabel({super.key, required this.sourceName});

  final String sourceName;

  @override
  Widget build(BuildContext context) {
    return Text(
      '출처: $sourceName',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
    );
  }
}

/// Replaces the author card on public-data posts (no author / 매너온도).
class SourceInfoCard extends StatelessWidget {
  const SourceInfoCard({super.key, required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    final source = item.sourceName ?? '공공데이터';
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryContainer,
            child: Icon(Icons.account_balance, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$source · 공공데이터', style: AppTypography.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '출처: $source',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
