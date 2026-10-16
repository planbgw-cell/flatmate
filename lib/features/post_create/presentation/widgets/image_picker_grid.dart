import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Horizontal photo picker strip (mock pick — picsum URLs, max 10).
class ImagePickerGrid extends StatelessWidget {
  const ImagePickerGrid({
    super.key,
    required this.images,
    required this.onChanged,
    this.maxImages = 10,
  });

  final List<String> images;
  final ValueChanged<List<String>> onChanged;
  final int maxImages;

  void _addMockImage() {
    if (images.length >= maxImages) return;
    final seed = DateTime.now().millisecondsSinceEpoch;
    onChanged([
      ...images,
      'https://picsum.photos/seed/flatpost$seed/400/400',
    ]);
  }

  void _removeAt(int index) {
    final next = [...images]..removeAt(index);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _AddTile(
            countLabel: '${images.length} / $maxImages',
            enabled: images.length < maxImages,
            onTap: _addMockImage,
          ),
          for (var i = 0; i < images.length; i++) ...[
            const SizedBox(width: AppSpacing.xs),
            _ThumbTile(
              url: images[i],
              onRemove: () => _removeAt(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.countLabel,
    required this.enabled,
    required this.onTap,
  });

  final String countLabel;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 88,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              color: enabled ? AppColors.textSecondary : AppColors.textHint,
            ),
            const SizedBox(height: 4),
            Text(
              countLabel,
              style: AppTypography.caption.copyWith(
                color: enabled ? AppColors.textSecondary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbTile extends StatelessWidget {
  const _ThumbTile({required this.url, required this.onRemove});

  final String url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: url,
            width: 88,
            height: 96,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: AppColors.border),
            errorWidget: (_, _, _) => Container(
              color: AppColors.border,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
