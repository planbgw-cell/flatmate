import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/feed_item.dart';

/// 주변 입지 요약: 가까운 지하철 + 1km 내 편의점·마트·병원 개수.
class NearbyLocationCard extends StatelessWidget {
  const NearbyLocationCard({super.key, required this.nearby});

  final NearbySummary nearby;

  @override
  Widget build(BuildContext context) {
    if (!nearby.hasContent) return const SizedBox.shrink();
    return Container(
      key: const ValueKey('detail-card-nearby'),
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
          Text('주변 입지 요약', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (nearby.subway case final subway?)
            _Row(
              key: const ValueKey('nearby-row-subway'),
              icon: Icons.subway_outlined,
              label: '지하철',
              value: subway,
            ),
          if (nearby.convenience > 0)
            _Row(
              key: const ValueKey('nearby-row-convenience'),
              icon: Icons.store_outlined,
              label: '편의점',
              value: '1km 내 ${nearby.convenience}곳',
            ),
          if (nearby.mart > 0)
            _Row(
              key: const ValueKey('nearby-row-mart'),
              icon: Icons.local_grocery_store_outlined,
              label: '마트',
              value: '1km 내 ${nearby.mart}곳',
            ),
          if (nearby.hospital > 0)
            _Row(
              key: const ValueKey('nearby-row-hospital'),
              icon: Icons.local_hospital_outlined,
              label: '병원',
              value: '1km 내 ${nearby.hospital}곳',
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 52,
            child: Text(label, style: AppTypography.bodyMedium),
          ),
          Expanded(
            child: Text(value, style: AppTypography.bodyLarge),
          ),
        ],
      ),
    );
  }
}
