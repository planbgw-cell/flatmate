import 'package:flutter/material.dart';

import '../../../../core/common_widgets/category_badge.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/feed_item.dart';

/// [공공나눔] badge for collected share / recycle facilities.
class PublicShareBenefitBadge extends StatelessWidget {
  const PublicShareBenefitBadge({super.key});

  static const color = AppColors.primary;

  @override
  Widget build(BuildContext context) => const CategoryBadge(label: '공공나눔');
}

/// [재활용센터] / [공유시설] / [공공나눔].
class PublicShareTypeBadge extends StatelessWidget {
  const PublicShareTypeBadge({super.key, required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    final type = item.shareCategory;
    if (type == null) return const SizedBox.shrink();
    return CategoryBadge(label: type.label);
  }
}

class PublicShareBadges extends StatelessWidget {
  const PublicShareBadges({super.key, required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        PublicShareBenefitBadge(key: ValueKey('public-share-badge-${item.id}')),
        PublicShareTypeBadge(
          key: ValueKey('share-type-${item.id}'),
          item: item,
        ),
      ],
    );
  }
}
