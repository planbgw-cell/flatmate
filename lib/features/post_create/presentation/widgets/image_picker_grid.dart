import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/create_post_provider.dart';

/// Horizontal photo strip: add (camera / gallery), first photo is the 대표
/// (thumbnail), X removes, tap a photo to make it the 대표.
class ImagePickerGrid extends ConsumerWidget {
  const ImagePickerGrid({
    super.key,
    required this.images,
    required this.onChanged,
    this.maxImages = 10,
  });

  final List<XFile> images;
  final ValueChanged<List<XFile>> onChanged;
  final int maxImages;

  int get _remaining => maxImages - images.length;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    if (_remaining <= 0) {
      messenger.showSnackBar(
        SnackBar(content: Text('사진은 최대 $maxImages장까지 첨부할 수 있어요.')),
      );
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('앨범에서 선택 (최대 $_remaining장)'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ref.read(postImagePickerProvider);
    try {
      final picked = source == ImageSource.camera
          ? [?await picker.pickFromCamera()]
          : await picker.pickFromGallery(limit: _remaining);
      if (picked.isEmpty) return;
      final next = [...images, ...picked];
      if (next.length > maxImages) {
        messenger.showSnackBar(
          SnackBar(content: Text('최대 $maxImages장까지만 첨부했어요.')),
        );
      }
      onChanged(next.take(maxImages).toList());
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('사진을 불러오지 못했어요. 권한을 확인해 주세요.')),
      );
    }
  }

  void _removeAt(int index) => onChanged([...images]..removeAt(index));

  void _makeCover(int index) {
    if (index == 0) return;
    final next = [...images];
    final cover = next.removeAt(index);
    onChanged([cover, ...next]);
  }

  Future<void> _showActions(BuildContext context, int index) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index != 0)
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('대표 사진으로 설정'),
                onTap: () => Navigator.pop(context, 'cover'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('삭제'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    switch (action) {
      case 'cover':
        _makeCover(index);
      case 'delete':
        _removeAt(index);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _AddTile(
            key: const ValueKey('image-add'),
            countLabel: '${images.length}/$maxImages',
            enabled: _remaining > 0,
            onTap: () => _add(context, ref),
          ),
          for (var i = 0; i < images.length; i++) ...[
            const SizedBox(width: AppSpacing.xs),
            _ThumbTile(
              key: ValueKey('image-thumb-$i'),
              index: i,
              path: images[i].path,
              isCover: i == 0,
              onTap: () => _showActions(context, i),
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
    super.key,
    required this.countLabel,
    required this.enabled,
    required this.onTap,
  });

  final String countLabel;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.textSecondary : AppColors.textHint;
    return InkWell(
      onTap: onTap,
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
            Icon(Icons.camera_alt_outlined, color: color),
            const SizedBox(height: 4),
            Text(countLabel, style: AppTypography.caption.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _ThumbTile extends StatelessWidget {
  const _ThumbTile({
    super.key,
    required this.index,
    required this.path,
    required this.isCover,
    required this.onTap,
    required this.onRemove,
  });

  final int index;
  final String path;
  final bool isCover;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(path),
              width: 88,
              height: 96,
              fit: BoxFit.cover,
              cacheWidth: 264,
              errorBuilder: (_, _, _) => Container(
                width: 88,
                height: 96,
                color: AppColors.border,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          if (isCover)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                ),
                child: Text(
                  '대표',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
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
                key: ValueKey('image-remove-$index'),
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
      ),
    );
  }
}
