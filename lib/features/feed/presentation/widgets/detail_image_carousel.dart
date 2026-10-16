import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class DetailImageCarousel extends StatelessWidget {
  const DetailImageCarousel({
    super.key,
    required this.images,
    required this.index,
    required this.onPageChanged,
  });

  final List<String> images;
  final int index;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final total = images.isEmpty ? 1 : images.length;
    final safeIndex = index.clamp(0, total - 1);

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: total,
          onPageChanged: onPageChanged,
          itemBuilder: (context, i) {
            final url = images.isEmpty ? '' : images[i];
            if (url.isEmpty) {
              return Container(color: AppColors.border);
            }
            return CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: AppColors.border),
              errorWidget: (_, _, _) => Container(
                color: AppColors.border,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  size: 48,
                  color: AppColors.textHint,
                ),
              ),
            );
          },
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [Color(0x66000000), Colors.transparent],
            ),
          ),
        ),
        Positioned(
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${safeIndex + 1} / $total',
              style: AppTypography.caption.copyWith(color: Colors.white),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.md + 28,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final active = i == safeIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.white54,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
