import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/notice.dart';
import '../widgets/notice_pinned_badge.dart';

/// 공지사항 상세 (no detail API; shows the notice from the list).
class NoticeDetailScreen extends StatelessWidget {
  const NoticeDetailScreen({super.key, required this.notice});

  final Notice notice;

  static String formatDateTime(DateTime at) {
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    return '${DateFormatter.ymd(at)} $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('공지사항')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Card(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (notice.isPinned) ...[
                  const NoticePinnedBadge(),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Text(
                  notice.title,
                  key: const ValueKey('notice-detail-title'),
                  style: AppTypography.header2,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  formatDateTime(notice.createdAt),
                  key: const ValueKey('notice-detail-date'),
                  style: AppTypography.caption,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Divider(height: 1),
                ),
                SelectableText(
                  notice.content,
                  key: const ValueKey('notice-detail-content'),
                  style: AppTypography.bodyLarge.copyWith(height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
