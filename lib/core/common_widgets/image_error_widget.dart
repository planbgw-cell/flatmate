import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared placeholder when network / asset images fail to load.
class ImageErrorWidget extends StatelessWidget {
  const ImageErrorWidget({
    super.key,
    this.width,
    this.height,
    this.iconSize = 28,
    this.borderRadius = 0,
  });

  final double? width;
  final double? height;
  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final child = ColoredBox(
      color: AppColors.border,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: iconSize,
          color: AppColors.textHint,
        ),
      ),
    );

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(width: width, height: height, child: child),
      );
    }
    return SizedBox(width: width, height: height, child: child);
  }
}
