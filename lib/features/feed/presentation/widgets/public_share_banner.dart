import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/models/feed_item.dart';

/// Title/type visual for image-less public share facilities.
enum ShareBannerKind {
  recycle('재활용센터', Color(0xFF059669), Color(0xFF6EE7B7), Icons.recycling),
  facility('공유시설', Color(0xFF2563EB), Color(0xFF93C5FD), Icons.apartment),
  share('공공나눔', Color(0xFFD97706), Color(0xFFFDE68A), Icons.volunteer_activism);

  const ShareBannerKind(this.label, this.primary, this.accent, this.icon);

  final String label;
  final Color primary;
  final Color accent;
  final IconData icon;

  static ShareBannerKind fromItem(FeedItem item) => switch (item.shareCategory) {
        ShareItemCategory.recycle => ShareBannerKind.recycle,
        ShareItemCategory.facility => ShareBannerKind.facility,
        ShareItemCategory.share || null => ShareBannerKind.share,
      };
}

/// Gradient hero/thumb for share facilities without map/원문 images.
class PublicShareBanner extends StatelessWidget {
  const PublicShareBanner({
    super.key,
    required this.item,
    this.large = false,
  });

  final FeedItem item;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final kind = ShareBannerKind.fromItem(item);
    final region = PublicShareNotice.regionFrom(
      address: item.address,
      title: item.title,
    );
    final iconSize = large ? 72.0 : 28.0;
    final labelStyle = large
        ? AppTypography.header2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          )
        : AppTypography.badgeText.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          );

    return Container(
      key: ValueKey('feed-share-banner-${item.id}'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kind.primary,
            Color.lerp(kind.primary, kind.accent, 0.55)!,
            kind.accent.withValues(alpha: 0.95),
          ],
          stops: const [0.0, 0.55, 1.0],
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
              kind.icon,
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
                Icon(kind.icon, size: iconSize, color: Colors.white),
                SizedBox(height: large ? 12 : 4),
                Text(
                  kind.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
                if (large) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      ?region,
                      kind.label,
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
