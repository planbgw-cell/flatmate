import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/feed_item.dart';

/// 예약중 / 거래완료 chip; nothing for 판매중.
class TradeStatusBadge extends StatelessWidget {
  const TradeStatusBadge({super.key, required this.status});

  final TradeStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      TradeStatus.selling => (null, null),
      TradeStatus.reserved => (AppColors.statusSuccess, Colors.white),
      TradeStatus.completed => (AppColors.textSecondary, Colors.white),
    };
    if (background == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: AppTypography.badgeText.copyWith(color: foreground),
      ),
    );
  }
}
