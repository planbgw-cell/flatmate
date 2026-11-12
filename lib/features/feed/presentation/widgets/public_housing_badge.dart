import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/models/feed_item.dart';
import 'feed_visual.dart';

/// [공공 혜택] badge for public housing notices.
class PublicBenefitBadge extends StatelessWidget {
  const PublicBenefitBadge({super.key});

  static const color = Color(0xFF15803D);

  @override
  Widget build(BuildContext context) => const _Badge(
        label: '공공 혜택',
        color: color,
        filled: true,
      );
}

/// [행복주택] / [청년주택] / [공공임대].
class HousingTypeBadge extends StatelessWidget {
  const HousingTypeBadge({super.key, required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    final type = item.housingType;
    if (type == null) return const SizedBox.shrink();
    return _Badge(label: type.label, color: feedVisual(item).color);
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
