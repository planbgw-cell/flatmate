import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Shared sage-tint category / notice badge (primaryLight + primary text).
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    super.key,
    required this.label,
    this.dense = false,
    this.urgent = false,
  });

  final String label;
  final bool dense;

  /// Uses terracotta accent for urgency / deadline callouts.
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final bg = urgent ? AppColors.accentLight : AppColors.primaryLight;
    final fg = urgent ? AppColors.accent : AppColors.primary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 5 : 7,
        vertical: dense ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.badgeText.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
