import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/employment_type.dart';

/// Sub-filter chips under [일자리·알바]: 전체 / 단기·알바 / 청년인턴 / 공공일자리.
class JobEmploymentFilterBar extends StatelessWidget {
  const JobEmploymentFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final EmploymentType selected;
  final ValueChanged<EmploymentType> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('job-employment-filter-bar'),
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        itemCount: EmploymentType.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final type = EmploymentType.values[index];
          final isSelected = type == selected;
          return FilterChip(
            key: ValueKey('job-employment-${type.code}'),
            selected: isSelected,
            showCheckmark: false,
            label: Text(type.label),
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
            onSelected: (_) => onSelected(type),
          );
        },
      ),
    );
  }
}
