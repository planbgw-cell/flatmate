import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

enum WriteComposeAction { property, job, post, community }

/// Bottom sheet: 룸메·주거 / 일자리·알바 / 나눔·공유 / 축제·나들이
Future<WriteComposeAction?> showWriteComposeSheet(BuildContext context) {
  return showModalBottomSheet<WriteComposeAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const WriteComposeSheet(),
  );
}

class WriteComposeSheet extends StatelessWidget {
  const WriteComposeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('무엇을 올릴까요?', style: AppTypography.header2),
            const SizedBox(height: AppSpacing.sm),
            _WriteOptionTile(
              icon: Icons.apartment_outlined,
              title: '룸메·주거 등록',
              subtitle: '단기임대 · 원룸 · 룸메이트',
              onTap: () => Navigator.pop(context, WriteComposeAction.property),
            ),
            _WriteOptionTile(
              icon: Icons.work_outline,
              title: '일자리·알바 공고',
              subtitle: '단기 알바 · 심부름',
              onTap: () => Navigator.pop(context, WriteComposeAction.job),
            ),
            _WriteOptionTile(
              icon: Icons.edit_outlined,
              title: '나눔·공유 글쓰기',
              subtitle: '동네생활 · 중고 · 나눔',
              onTap: () => Navigator.pop(context, WriteComposeAction.post),
            ),
            _WriteOptionTile(
              icon: Icons.campaign_outlined,
              title: '축제·나들이 쓰기',
              subtitle: '우리 동네 축제 · 나들이 정보',
              onTap: () =>
                  Navigator.pop(context, WriteComposeAction.community),
            ),
          ],
        ),
      ),
    );
  }
}

class _WriteOptionTile extends StatelessWidget {
  const _WriteOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryContainer,
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: AppTypography.titleMedium),
      subtitle: Text(subtitle, style: AppTypography.bodyMedium),
      onTap: onTap,
    );
  }
}
