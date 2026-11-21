import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/models/feed_item.dart';
import 'feed_visual.dart';

/// [공공나눔] badge for collected share / recycle facilities.
class PublicShareBenefitBadge extends StatelessWidget {
  const PublicShareBenefitBadge({super.key});

  static const color = Color(0xFF059669);

  @override
  Widget build(BuildContext context) => const _Badge(
        label: '공공나눔',
        color: color,
        filled: true,
      );
}

/// [재활용센터] / [공유시설] / [공공나눔].
class PublicShareTypeBadge extends StatelessWidget {
  const PublicShareTypeBadge({super.key, required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    final type = item.shareCategory;
    if (type == null) return const SizedBox.shrink();
    return _Badge(label: type.label, color: feedVisual(item).color);
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
