import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/feed_item.dart';

/// 고용형태별 지원 전 체크리스트 + 접수 절차 3단계 (접이식).
class JobApplyGuideCard extends StatelessWidget {
  const JobApplyGuideCard({super.key, required this.item});

  final FeedItem item;

  static const _steps = [
    '1. 공고문 확인',
    '2. 온라인/방문 접수',
    '3. 서류·면접(해당 시)',
  ];

  /// Checklist badge label (CONTRACT → 계약직; card type badge stays 단기알바).
  static String guideLabel(PublicJobType type) => switch (type) {
        PublicJobType.publicWork => '공공일자리',
        PublicJobType.intern => '청년인턴',
        PublicJobType.contract => '계약직',
        PublicJobType.partTime => '단기알바',
      };

  static Color guideColor(PublicJobType type) => switch (type) {
        PublicJobType.publicWork => const Color(0xFF0F766E),
        PublicJobType.intern => const Color(0xFF7C3AED),
        PublicJobType.contract => const Color(0xFF2563EB),
        PublicJobType.partTime => const Color(0xFF0891B2),
      };

  @override
  Widget build(BuildContext context) {
    final type = item.jobType ?? PublicJobType.publicWork;
    final label = guideLabel(type);
    final color = guideColor(type);
    final points = _pointsFor(type);
    return Material(
      key: const ValueKey('detail-card-job-guide'),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const ValueKey('detail-job-guide-tile'),
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
            '공공일자리 지원 전 체크리스트',
            style: AppTypography.titleMedium,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Text(
                  label,
                  style: AppTypography.badgeText.copyWith(
                    color: color,
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
            Text('지원 절차', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _steps.join(' → '),
              key: const ValueKey('detail-job-guide-steps'),
              style: AppTypography.bodyLarge.copyWith(height: 1.45),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '실제 자격·일정·서류는 해당 공고문을 기준으로 하세요.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<String> _pointsFor(PublicJobType type) => switch (type) {
        PublicJobType.publicWork => const [
            '거주·연령·소득 등 모집 대상 요건을 공고문에서 확인하세요.',
            '근무 시간·장소·급여(시급/일급) 조건을 미리 체크하세요.',
            '접수 방법(온라인·방문)과 마감일을 놓치지 마세요.',
          ],
        PublicJobType.intern => const [
            '청년 연령·재학/졸업 요건이 공고마다 달라요.',
            '인턴 기간·급여·근무지를 공고문에서 확인하세요.',
            '자기소개서·성적증명 등 제출 서류를 미리 준비하세요.',
          ],
        PublicJobType.contract => const [
            '계약 기간·근로 형태(기간제 등)를 공고문에서 확인하세요.',
            '자격·경력 요건과 전형 일정(필기·면접)을 체크하세요.',
            '응시원서·증빙 서류 목록을 마감 전에 준비하세요.',
          ],
        PublicJobType.partTime => const [
            '근무 요일·시간·시급을 공고문에서 확인하세요.',
            '단기·대체 인력인 경우 근무 기간을 꼭 확인하세요.',
            '온라인/방문 접수 방법과 필요 서류를 미리 챙기세요.',
          ],
      };
}
