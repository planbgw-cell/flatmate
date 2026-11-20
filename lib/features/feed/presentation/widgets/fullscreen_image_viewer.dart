import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Full-screen gallery for detail Hero photos. Optional [onOpenMap] shows
/// [지도에서 보기] under the pager (공공 주거 map/로드뷰).
class FullscreenImageViewer extends StatefulWidget {
  const FullscreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.onOpenMap,
  });

  final List<String> images;
  final int initialIndex;
  final VoidCallback? onOpenMap;

  static Future<void> open(
    BuildContext context, {
    required List<String> images,
    int initialIndex = 0,
    VoidCallback? onOpenMap,
  }) {
    final urls = images.where((u) => u.trim().isNotEmpty).toList();
    if (urls.isEmpty) return Future.value();
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) => FullscreenImageViewer(
          images: urls,
          initialIndex: initialIndex.clamp(0, urls.length - 1),
          onOpenMap: onOpenMap,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.images.length;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: total,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: widget.images[i],
                        fit: BoxFit.contain,
                        memCacheWidth: 2160,
                        placeholder: (_, _) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (_, _, _) => const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 48,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: AppSpacing.xs,
                left: AppSpacing.xs,
                child: IconButton(
                  key: const ValueKey('detail-viewer-close'),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                top: AppSpacing.md,
                right: AppSpacing.md,
                child: Text(
                  '${_index + 1} / $total',
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                ),
              ),
              if (widget.onOpenMap != null)
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.lg,
                  child: FilledButton(
                    key: const ValueKey('detail-viewer-map-cta'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onOpenMap!();
                    },
                    child: const Text('지도에서 보기'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
