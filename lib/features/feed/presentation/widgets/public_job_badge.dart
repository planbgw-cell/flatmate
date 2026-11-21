import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/models/feed_item.dart';
import 'feed_visual.dart';

/// [공공 일자리] badge for collected job notices.
class PublicJobBenefitBadge extends StatelessWidget {
  const PublicJobBenefitBadge({super.key});

  static const color = Color(0xFF0F766E);

  @override
  Widget build(BuildContext context) => const _Badge(
        label: '공공 일자리',
        color: color,
        filled: true,
      );
}

/// [공공일자리] / [단기알바] / [청년인턴].
class PublicJobTypeBadge extends StatelessWidget {
  const PublicJobTypeBadge({super.key, required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    final type = item.jobType;
    if (type == null) return const SizedBox.shrink();
    return _Badge(label: type.label, color: feedVisual(item).color);
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.filled = false});

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: AppTypography.badgeText.copyWith(
          color: filled ? Colors.white : color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
