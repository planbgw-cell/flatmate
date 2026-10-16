import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class DetailBottomBar extends StatelessWidget {
  const DetailBottomBar({
    super.key,
    required this.priceOrCondition,
    required this.ctaLabel,
    required this.liked,
    required this.onLikeToggle,
    required this.onCtaPressed,
  });

  final String priceOrCondition;
  final String ctaLabel;
  final bool liked;
  final VoidCallback onLikeToggle;
  final VoidCallback onCtaPressed;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      elevation: 8,
      color: AppColors.background,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm + bottom,
        ),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onLikeToggle,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey(liked),
                  color: liked ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
            Container(
              width: 1,
              height: 28,
              color: AppColors.divider,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            ),
            Expanded(
              child: Text(
                priceOrCondition,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            FilledButton(
              onPressed: onCtaPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
              ),
              child: Text(
                ctaLabel,
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
