import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/notice.dart';
import '../providers/notice_provider.dart';
import '../widgets/notice_pinned_badge.dart';

/// 공지사항 목록: 필독 (pinned) first, then newest.
class NoticeListScreen extends ConsumerWidget {
  const NoticeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(noticesProvider);
    final notices = noticesAsync.value;

    final Widget body;
    if (notices == null) {
      final error = noticesAsync.error;
      body = noticesAsync.hasError
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error is ApiException
                        ? error.message
                        : '공지사항을 불러오지 못했어요.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(noticesProvider),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator());
    } else {
      body = RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(noticesProvider.notifier).refresh(),
        child: notices.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Text(
                    '등록된 공지사항이 없습니다.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium,
                  ),
                ],
              )
            : ListView.separated(
                key: const ValueKey('notice-list'),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: notices.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) => _NoticeTile(
                  notice: notices[index],
                  onTap: () => context.push(
                    RouteNames.noticeDetail,
                    extra: notices[index],
                  ),
                ),
              ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('공지사항')),
      body: body,
    );
  }
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({required this.notice, required this.onTap});

  final Notice notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: notice.isPinned ? AppColors.primaryContainer : Colors.transparent,
      child: InkWell(
        key: ValueKey('notice-tile-${notice.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (notice.isPinned) ...[
                          NoticePinnedBadge(
                            key: ValueKey('notice-pinned-${notice.id}'),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Expanded(
                          child: Text(
                            notice.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: notice.isPinned
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      DateFormatter.ymd(notice.createdAt),
                      key: ValueKey('notice-date-${notice.id}'),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
