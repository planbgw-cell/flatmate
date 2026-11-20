import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/models/feed_item.dart';

/// Visual variant for image-less public housing notices (카드 · 상세 Hero).
/// Server `housing_type` stays 3 codes; 전세임대 is title / 공급유형 only.
enum HousingBannerKind {
  happyHouse('행복주택', Color(0xFF16A34A), Color(0xFF86EFAC), Icons.home_work),
  youthHouse('청년주택', Color(0xFF4F46E5), Color(0xFFA5B4FC), Icons.school),
  jeonseRental('전세임대', Color(0xFFD97706), Color(0xFFFDE68A), Icons.key),
  publicRental('공공임대', Color(0xFF0D9488), Color(0xFF5EEAD4), Icons.location_city);

  const HousingBannerKind(this.label, this.primary, this.accent, this.icon);

  final String label;
  final Color primary;
  final Color accent;
  final IconData icon;

  /// `PUBLIC_RENTAL` + "전세임대" in title or 공급유형 → [jeonseRental].
  static HousingBannerKind fromItem(FeedItem item) {
    final type = item.housingType;
    if (type == HousingType.happyHouse) return HousingBannerKind.happyHouse;
    if (type == HousingType.youthHouse) return HousingBannerKind.youthHouse;
    final haystack =
        '${item.title} ${item.publicNotice?.supplyType ?? ''}';
    if (haystack.contains('전세임대')) return HousingBannerKind.jeonseRental;
    return HousingBannerKind.publicRental;
  }
}

/// Gradient + icon silhouette + type label for notices without map/로드뷰 images.
class PublicHousingBanner extends StatelessWidget {
  const PublicHousingBanner({
    super.key,
    required this.item,
    this.large = false,
  });

  final FeedItem item;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final kind = HousingBannerKind.fromItem(item);
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
      key: ValueKey('feed-housing-banner-${item.id}'),
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
          Positioned(
            left: large ? -40 : -16,
            top: large ? -30 : -8,
            child: Container(
              width: large ? 140 : 56,
              height: large ? 140 : 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
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
                  textAlign: large ? TextAlign.start : TextAlign.center,
                  style: labelStyle,
                ),
                if (large) ...[
                  const SizedBox(height: 4),
                  Text(
                    '공공 주거 공고',
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
