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
    final urgent = type == BadgeType.urgent;
    final bg = urgent ? AppColors.accentLight : AppColors.primaryLight;
    final textColor = urgent ? AppColors.accent : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        label,
        style: AppTypography.badgeText.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
