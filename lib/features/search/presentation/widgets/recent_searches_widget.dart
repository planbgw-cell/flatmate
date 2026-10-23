import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/search_provider.dart';

/// 최근 검색: tap a term to search again, X to remove, 전체 삭제 to clear.
class RecentSearchesWidget extends ConsumerWidget {
  const RecentSearchesWidget({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('최근 검색어를 모두 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            key: const ValueKey('confirm-clear-search'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(recentSearchesProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terms = ref.watch(recentSearchesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.xxs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text('최근 검색', style: AppTypography.titleMedium),
              ),
              if (terms.isNotEmpty)
                TextButton(
                  key: const ValueKey('search-clear-all'),
                  onPressed: () => _confirmClear(context, ref),
                  child: Text(
                    '전체 삭제',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: terms.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Text(
                    '최근 검색어가 없습니다.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium,
                  ),
                )
              : ListView.builder(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: terms.length,
                  itemBuilder: (context, index) {
                    final term = terms[index];
                    return ListTile(
                      key: ValueKey('recent-search-$term'),
                      dense: true,
                      leading: const Icon(
                        Icons.access_time,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                      title: Text(term, style: AppTypography.bodyLarge),
                      trailing: IconButton(
                        key: ValueKey('recent-remove-$term'),
                        tooltip: '삭제',
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textHint,
                          size: 18,
                        ),
                        onPressed: () => ref
                            .read(recentSearchesProvider.notifier)
                            .remove(term),
                      ),
                      onTap: () => onSelected(term),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
