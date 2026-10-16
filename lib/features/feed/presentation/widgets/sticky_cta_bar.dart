import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class StickyCtaBar extends StatelessWidget {
  const StickyCtaBar({
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
      color: AppColors.surface,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md + bottom,
        ),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onLikeToggle,
              icon: Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: liked ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                priceOrCondition,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FilledButton(
              onPressed: onCtaPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(120, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
              ),
              child: Text(ctaLabel),
            ),
          ],
        ),
      ),
    );
  }
}
