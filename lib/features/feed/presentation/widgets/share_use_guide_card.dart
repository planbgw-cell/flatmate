import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/feed_item.dart';
import 'public_share_banner.dart';

/// 시설 유형별 이용 안내 + 방문 절차 3단계 (접이식).
class ShareUseGuideCard extends StatelessWidget {
  const ShareUseGuideCard({super.key, required this.item});

  final FeedItem item;

  static const _steps = [
    '1. 취급 품목·이용 조건 확인',
    '2. 운영 시간·휴무일 확인',
    '3. 방문 또는 안내 사이트로 문의',
  ];

  @override
  Widget build(BuildContext context) {
    final kind = ShareBannerKind.fromItem(item);
    final points = _pointsFor(item.shareCategory ?? ShareItemCategory.share);
    return Material(
      key: const ValueKey('detail-card-share-guide'),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const ValueKey('detail-share-guide-tile'),
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xxs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          title: Text(
            '공공 재활용·공유시설 이용 안내',
            style: AppTypography.titleMedium,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: kind.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: kind.primary.withValues(alpha: 0.5)),
                ),
                child: Text(
                  kind.label,
                  style: AppTypography.badgeText.copyWith(
                    color: kind.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          children: [
            for (final point in points)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('· ', style: AppTypography.bodyLarge),
                    Expanded(
                      child: Text(point, style: AppTypography.bodyLarge),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Text('이용 절차', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _steps.join(' → '),
              key: const ValueKey('detail-share-guide-steps'),
              style: AppTypography.bodyLarge.copyWith(height: 1.45),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '실제 취급 품목·요금·운영 시간은 해당 센터 안내를 기준으로 하세요.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<String> _pointsFor(ShareItemCategory type) => switch (type) {
        ShareItemCategory.recycle => const [
            '가전·가구 등 대형 폐기물/중고 물품 반입 기준을 미리 확인하세요.',
            '평일 운영·휴무일(주말·공휴일)을 센터별로 확인하세요.',
            '요금·수거 가능 여부는 전화 또는 안내 사이트에서 확인하세요.',
          ],
        ShareItemCategory.facility => const [
            '공유 물품·공간 이용 자격과 예약 방법을 확인하세요.',
            '이용 시간·반납 규칙을 공지사항에서 체크하세요.',
            '문의처·안내 사이트로 이용 가능 여부를 확인하세요.',
          ],
        ShareItemCategory.share => const [
            '나눔·벼룩시장 일정과 참여 조건을 공지에서 확인하세요.',
            '물품 반입·판매 가능 품목을 미리 체크하세요.',
            '장소·운영 시간은 해당 구청·센터 안내를 따르세요.',
          ],
      };
}
