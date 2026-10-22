import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Heart that pops (scale bounce) whenever [liked] flips.
class LikeHeart extends StatelessWidget {
  const LikeHeart({
    super.key,
    required this.liked,
    this.size = 24,
    this.inactiveColor = AppColors.textHint,
  });

  final bool liked;
  final double size;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
        child: child,
      ),
      child: Icon(
        liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        key: ValueKey(liked),
        size: size,
        color: liked ? AppColors.primary : inactiveColor,
      ),
    );
  }
}
