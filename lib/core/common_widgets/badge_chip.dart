import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum BadgeType { urgent, success, normal, warning }

class BadgeChip extends StatelessWidget {
  const BadgeChip({
    super.key,
    required this.label,
    this.type = BadgeType.normal,
  });

  final String label;
  final BadgeType type;

  @override
  Widget build(BuildContext context) {
    late final Color bgColor;
    late final Color textColor;

    switch (type) {
      case BadgeType.urgent:
        bgColor = AppColors.statusUrgent.withValues(alpha: 0.12);
        textColor = AppColors.statusUrgent;
      case BadgeType.success:
        bgColor = AppColors.statusSuccess.withValues(alpha: 0.12);
        textColor = AppColors.statusSuccess;
      case BadgeType.warning:
        bgColor = AppColors.statusWarning.withValues(alpha: 0.12);
        textColor = AppColors.statusWarning;
      case BadgeType.normal:
        bgColor = AppColors.surface;
        textColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        label,
        style: AppTypography.badgeText.copyWith(color: textColor),
      ),
    );
  }
}
