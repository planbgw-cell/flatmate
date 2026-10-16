import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Flatmate trust score — inspired by community reputation UX, original design.
class TrustScoreBadge extends StatelessWidget {
  const TrustScoreBadge({super.key, required this.score});

  final double score;

  Color get _color {
    if (score >= 42) return AppColors.trustHigh;
    if (score >= 36) return AppColors.trustMid;
    return AppColors.trustLow;
  }

  String get _label {
    if (score >= 42) return '신뢰 높음';
    if (score >= 36) return '보통';
    return '확인 필요';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, size: 14, color: _color),
          const SizedBox(width: 4),
          Text(
            '${score.toStringAsFixed(1)}° · $_label',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
