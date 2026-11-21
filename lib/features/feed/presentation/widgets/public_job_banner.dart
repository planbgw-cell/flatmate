import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/models/feed_item.dart';

/// Title-keyword field for image-less public job notices (카드 · 상세 Hero).
enum JobBannerKind {
  medical('의료/보건', Color(0xFFDC2626), Color(0xFFFCA5A5), Icons.local_hospital_outlined),
  education('교육/강사', Color(0xFFCA8A04), Color(0xFFFDE68A), Icons.menu_book_outlined),
  it('IT/디지털', Color(0xFF2563EB), Color(0xFF93C5FD), Icons.computer_outlined),
  admin('행정/사무', Color(0xFF4F46E5), Color(0xFFA5B4FC), Icons.badge_outlined),
  field('현장/기술', Color(0xFFEA580C), Color(0xFFFDBA74), Icons.construction_outlined),
  general('공공일자리', Color(0xFF0F766E), Color(0xFF5EEAD4), Icons.work_outline);

  const JobBannerKind(this.label, this.primary, this.accent, this.icon);

  final String label;
  final Color primary;
  final Color accent;
  final IconData icon;

  /// First matching keyword group in [title]; else [general].
  static JobBannerKind fromTitle(String title) {
    final t = title.toUpperCase();
    if (_containsAny(t, const ['의료', '보건', '간호', '병원', '요양'])) {
      return JobBannerKind.medical;
    }
    if (_containsAny(t, const [
      '교육',
      '강사',
      '교사',
      '학교',
      '도서관',
      '유치원',
      '방과후',
    ])) {
      return JobBannerKind.education;
    }
    if (_containsAny(t, const [
      'IT',
      '디지털',
      '개발',
      'SW',
      '소프트웨어',
      '정보화',
    ])) {
      return JobBannerKind.it;
    }
    if (_containsAny(t, const ['행정', '사무', '민원', '공무'])) {
      return JobBannerKind.admin;
    }
    if (_containsAny(t, const [
      '환경미화',
      '수거',
      '시설관리',
      '현장',
      '운전',
      '공사',
    ])) {
      return JobBannerKind.field;
    }
    return JobBannerKind.general;
  }

  static bool _containsAny(String haystack, List<String> needles) {
    for (final n in needles) {
      if (haystack.contains(n.toUpperCase())) return true;
    }
    return false;
  }
}

/// Gradient + icon silhouette + field label for notices without map images.
class PublicJobBanner extends StatelessWidget {
  const PublicJobBanner({
    super.key,
    required this.item,
    this.large = false,
  });

  final FeedItem item;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final kind = JobBannerKind.fromTitle(item.title);
    final region = PublicJobNotice.regionFrom(
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
      key: ValueKey('feed-job-banner-${item.id}'),
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
