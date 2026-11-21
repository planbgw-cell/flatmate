import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/models/feed_item.dart';

/// Gradient hero/thumb for image-less public job notices.
class PublicJobBanner extends StatelessWidget {
  const PublicJobBanner({
    super.key,
    required this.item,
    this.large = false,
  });

  final FeedItem item;
  final bool large;

  static ({Color primary, Color accent, IconData icon}) visualFor(
    PublicJobType type,
  ) =>
      switch (type) {
        PublicJobType.publicWork => (
            primary: const Color(0xFF0F766E),
            accent: const Color(0xFF5EEAD4),
            icon: Icons.work_outline,
          ),
        PublicJobType.contract || PublicJobType.partTime => (
            primary: const Color(0xFF2563EB),
            accent: const Color(0xFF93C5FD),
            icon: Icons.schedule,
          ),
        PublicJobType.intern => (
            primary: const Color(0xFF7C3AED),
            accent: const Color(0xFFC4B5FD),
            icon: Icons.school_outlined,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final type = item.jobType ?? PublicJobType.publicWork;
    final visual = visualFor(type);
    final region = PublicJobNotice.regionFrom(
      address: item.address,
      title: item.title,
    );
    final iconSize = large ? 72.0 : 28.0;

    return Container(
      key: ValueKey('feed-job-banner-${item.id}'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            visual.primary,
            Color.lerp(visual.primary, visual.accent, 0.55)!,
            visual.accent.withValues(alpha: 0.95),
          ],
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: large ? -24 : -10,
            bottom: large ? -28 : -12,
            child: Icon(
              visual.icon,
              size: large ? 180 : 72,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(large ? 20 : 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
                  large ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Icon(visual.icon, size: iconSize, color: Colors.white),
                SizedBox(height: large ? 12 : 4),
                Text(
                  type.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: large
                      ? AppTypography.header2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        )
                      : AppTypography.badgeText.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                ),
                if (large) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      ?region,
                      '공공 일자리',
                    ].join(' · '),
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
