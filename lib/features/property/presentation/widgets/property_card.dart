import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common_widgets/badge_chip.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/property.dart';

class PropertyCard extends StatelessWidget {
  const PropertyCard({super.key, required this.property});

  final Property property;

  String get _thumb =>
      property.thumbnailUrl ??
      'https://picsum.photos/seed/${property.id}/400/400';

  String get _typeLabel => switch (property.type) {
        PropertyType.room => '원룸',
        PropertyType.shortStay => '단기',
        PropertyType.listing => '매물',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.push('/property/${property.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.thumbRadius),
              child: CachedNetworkImage(
                imageUrl: _thumb,
                width: AppSpacing.thumbSize,
                height: AppSpacing.thumbSize,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  width: AppSpacing.thumbSize,
                  height: AppSpacing.thumbSize,
                  color: AppColors.skeletonBase,
                ),
                errorWidget: (_, _, _) => Container(
                  width: AppSpacing.thumbSize,
                  height: AppSpacing.thumbSize,
                  color: AppColors.skeletonBase,
                  child: const Icon(Icons.apartment_outlined),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SizedBox(
                height: AppSpacing.thumbSize,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BadgeChip(
                      label: _typeLabel,
                      type: BadgeType.warning,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      property.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      property.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            CurrencyFormatter.krw(property.monthlyRent),
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (property.availableFrom != null)
                          Text(
                            '입주 ${DateFormatter.ymd(property.availableFrom!)}',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
