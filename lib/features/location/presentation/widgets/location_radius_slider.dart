import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/location_provider.dart';

class LocationRadiusSlider extends ConsumerWidget {
  const LocationRadiusSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = ref.watch(locationRadiusProvider);
    final nearbyCount = ref.watch(nearbyLocationCountProvider);
    final stepIndex = kLocationRadiusSteps
        .indexOf(radius)
        .clamp(0, kLocationRadiusSteps.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('내 동네 범위 설정', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          radiusLabel(radius),
          style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.12),
            trackHeight: 4,
          ),
          child: Slider(
            min: 0,
            max: (kLocationRadiusSteps.length - 1).toDouble(),
            divisions: kLocationRadiusSteps.length - 1,
            value: stepIndex.toDouble(),
            label: '${radius.toStringAsFixed(0)}km',
            onChanged: (value) {
              final next = kLocationRadiusSteps[value.round()];
              ref.read(locationRadiusProvider.notifier).state = next;
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final step in kLocationRadiusSteps)
              Text(
                '${step.toStringAsFixed(0)}km',
                style: AppTypography.caption.copyWith(
                  color: step == radius
                      ? AppColors.primary
                      : AppColors.textHint,
                  fontWeight:
                      step == radius ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.xs),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.map_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '근처 동네 $nearbyCount개 포함',
                  style: AppTypography.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
