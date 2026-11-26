import 'package:flutter/material.dart';

import '../../../../core/common_widgets/category_badge.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/feed_item.dart';

/// [공공 혜택] badge for public housing notices.
class PublicBenefitBadge extends StatelessWidget {
  const PublicBenefitBadge({super.key});

  static const color = AppColors.primary;

  @override
  Widget build(BuildContext context) => const CategoryBadge(label: '공공 혜택');
}

/// [행복주택] / [청년주택] / [공공임대].
class HousingTypeBadge extends StatelessWidget {
  const HousingTypeBadge({super.key, required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    final type = item.housingType;
    if (type == null) return const SizedBox.shrink();
    return CategoryBadge(label: type.label);
  }
}

/// Both badges in a row, for cards and the detail header.
class PublicHousingBadges extends StatelessWidget {
  const PublicHousingBadges({super.key, required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        PublicBenefitBadge(key: ValueKey('public-badge-${item.id}')),
        HousingTypeBadge(key: ValueKey('housing-type-${item.id}'), item: item),
      ],
    );
  }
}
