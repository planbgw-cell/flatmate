import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'like_heart.dart';

class DetailBottomBar extends StatelessWidget {
  const DetailBottomBar({
    super.key,
    required this.priceOrCondition,
    required this.ctaLabel,
    required this.liked,
    required this.onLikeToggle,
    required this.onCtaPressed,
    this.ctaKey,
    this.secondaryLabel,
    this.secondaryKey,
    this.onSecondaryPressed,
  });

  /// Shown next to the heart; dropped when two actions need the width.
  final String priceOrCondition;

  /// Main (filled) action; hidden when [onCtaPressed] is null.
  final String ctaLabel;
  final Key? ctaKey;
  final bool liked;
  final VoidCallback onLikeToggle;
  final VoidCallback? onCtaPressed;

  /// Optional outlined action left of the main one (e.g. 지도에서 보기).
  final String? secondaryLabel;
  final Key? secondaryKey;
  final VoidCallback? onSecondaryPressed;

  static final _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSpacing.xs),
  );

  Widget _primary() => FilledButton(
        key: ctaKey,
        onPressed: onCtaPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: _shape,
        ),
        child: Text(
          ctaLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.titleMedium.copyWith(color: Colors.white),
        ),
      );

  Widget _secondary() => OutlinedButton(
        key: secondaryKey,
        onPressed: onSecondaryPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          shape: _shape,
        ),
        child: Text(
          secondaryLabel!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final hasPrimary = onCtaPressed != null;
    final twoActions =
        hasPrimary && secondaryLabel != null && onSecondaryPressed != null;

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
              key: const ValueKey('detail-like'),
              onPressed: onLikeToggle,
              icon: LikeHeart(
                liked: liked,
                inactiveColor: AppColors.textSecondary,
              ),
            ),
            Container(
              width: 1,
              height: 28,
              color: AppColors.divider,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            ),
            if (twoActions) ...[
              Expanded(child: _secondary()),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: _primary()),
            ] else ...[
              Expanded(
                child: Text(
                  priceOrCondition,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium,
                ),
              ),
              if (hasPrimary) ...[
                const SizedBox(width: AppSpacing.xs),
                _primary(),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
