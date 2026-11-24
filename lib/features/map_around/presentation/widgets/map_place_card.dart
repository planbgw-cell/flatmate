import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/external_url.dart';
import '../../../places/domain/models/local_place.dart';
import 'map_place_marker.dart';

/// Bottom summary card for a selected place pin.
class MapPlaceCard extends ConsumerWidget {
  const MapPlaceCard({super.key, required this.place});

  final LocalPlace place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = MapPlaceMarker.colorFor(place.category);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Material(
        key: const ValueKey('map-place-card'),
        color: AppColors.cardBackground,
        elevation: 4,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      place.name,
                      style: AppTypography.header2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    place.distanceLabel,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  place.subCategory.isEmpty
                      ? place.category.shortLabel
                      : place.subCategory,
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (place.address.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  place.address,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  if (place.phone != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const ValueKey('map-place-call'),
                        onPressed: () {
                          final tel = Uri(
                            scheme: 'tel',
                            path: place.phone!.replaceAll(RegExp(r'[^\d+]'), ''),
                          );
                          ref.read(externalUrlLauncherProvider)(tel);
                        },
                        icon: const Icon(Icons.phone, size: 18),
                        label: Text(place.phone!),
                      ),
                    ),
                  if (place.phone != null) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('map-place-kakao'),
                      onPressed: place.placeUrl.isEmpty
                          ? null
                          : () {
                              final uri = Uri.tryParse(place.placeUrl);
                              if (uri != null) {
                                ref.read(externalUrlLauncherProvider)(uri);
                              }
                            },
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('카카오맵 상세보기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
