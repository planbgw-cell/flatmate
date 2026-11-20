import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/feed_item.dart';
import 'public_housing_banner.dart';

/// 유형별 핵심 입주 자격 요약 + 청약 절차 3단계 (접이식).
class EligibilityGuideCard extends StatelessWidget {
  const EligibilityGuideCard({super.key, required this.item});

  final FeedItem item;

  static const _steps = [
    '1. 공고문 확인',
    '2. 온라인 청약 신청',
    '3. 서류 제출 및 당첨 발표',
  ];

  @override
  Widget build(BuildContext context) {
    final kind = HousingBannerKind.fromItem(item);
    final points = _pointsFor(kind);
    return Material(
      key: const ValueKey('detail-card-eligibility'),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const ValueKey('detail-eligibility-tile'),
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
            '핵심 입주 자격 & 청약 가이드',
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
            Text('신청 절차', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _steps.join(' → '),
              key: const ValueKey('detail-eligibility-steps'),
              style: AppTypography.bodyLarge.copyWith(height: 1.45),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '실제 자격·일정은 해당 공고문을 기준으로 하세요.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<String> _pointsFor(HousingBannerKind kind) => switch (kind) {
        HousingBannerKind.happyHouse => const [
            '무주택 세대구성원이 기본 요건입니다.',
            '대학생·청년·신혼부부 등 계층별 연령·소득 기준이 달라요.',
            '소득·자산 기준과 입주 계층은 공고문에서 확인하세요.',
          ],
        HousingBannerKind.youthHouse => const [
            '만 19~39세 청년이 주요 대상입니다.',
            '무주택 요건을 충족해야 합니다.',
            '소득·자산 기준은 공고문에서 확인하세요.',
          ],
        HousingBannerKind.jeonseRental => const [
            '무주택 저소득·신혼·청년 등이 주요 대상입니다.',
            'LH 전세임대는 보증금 지원 요건이 공고마다 달라요.',
            '입주 자격·보증금·신청 기간은 공고문에서 확인하세요.',
          ],
        HousingBannerKind.publicRental => const [
            '무주택 서민·생애최초 등이 주요 대상입니다.',
            '공급유형(영구·국민·행복 등)마다 자격이 달라요.',
            '소득·자산·가점 기준은 공고문에서 확인하세요.',
          ],
      };
}
