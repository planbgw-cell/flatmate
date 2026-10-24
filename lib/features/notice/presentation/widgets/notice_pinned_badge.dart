import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// 상단 고정 공지 표시: pin + [필독].
class NoticePinnedBadge extends StatelessWidget {
  const NoticePinnedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.push_pin, size: 12, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            '필독',
            style: AppTypography.badgeText.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
