import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/feed_item.dart';

class FeedFilterBar extends StatelessWidget {
  const FeedFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final FeedCategory selected;
  final ValueChanged<FeedCategory> onSelected;

  static const categories = FeedCategory.values;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selected;
          return FilterChip(
            selected: isSelected,
            showCheckmark: false,
            label: Text(category.label),
            labelStyle: AppTypography.badgeText.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            onSelected: (_) => onSelected(category),
          );
        },
      ),
    );
  }
}
