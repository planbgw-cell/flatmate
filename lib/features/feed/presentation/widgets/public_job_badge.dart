import 'package:flutter/material.dart';

import '../../../../core/common_widgets/category_badge.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/feed_item.dart';

/// [공공 일자리] badge for collected job notices.
class PublicJobBenefitBadge extends StatelessWidget {
  const PublicJobBenefitBadge({super.key});

  static const color = AppColors.primary;

  @override
  Widget build(BuildContext context) => const CategoryBadge(label: '공공 일자리');
}

/// [공공일자리] / [단기알바] / [청년인턴].
class PublicJobTypeBadge extends StatelessWidget {
  const PublicJobTypeBadge({super.key, required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    final type = item.jobType;
    if (type == null) return const SizedBox.shrink();
    return CategoryBadge(label: type.label);
  }
}

class PublicJobBadges extends StatelessWidget {
  const PublicJobBadges({super.key, required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        PublicJobBenefitBadge(key: ValueKey('public-job-badge-${item.id}')),
        PublicJobTypeBadge(key: ValueKey('job-type-${item.id}'), item: item),
      ],
    );
  }
}
