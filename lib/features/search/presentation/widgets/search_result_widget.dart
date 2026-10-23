import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/common_widgets/skeleton_card.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../feed/presentation/feed_actions.dart';
import '../../../feed/presentation/widgets/feed_card_item.dart';
import '../providers/search_provider.dart';

/// `GET /feeds?q=` results as feed cards (infinite scroll).
class SearchResultWidget extends ConsumerWidget {
  const SearchResultWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider);
    final data = resultsAsync.value;
    if (data == null) {
      if (resultsAsync.hasError) {
        final error = resultsAsync.error;
        return Center(
          child: Text(
            error is ApiException ? error.message : '검색하지 못했어요.',
            style: AppTypography.bodyMedium,
          ),
        );
      }
      return const SkeletonCardList(count: 5);
    }
    if (data.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Text(
          '검색 결과가 없습니다.',
          key: const ValueKey('search-empty'),
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
      );
    }

    final items = data.items;
    final showLoader = data.hasMore || data.isLoadingMore;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        if (metrics.pixels >= metrics.maxScrollExtent - 240) {
          ref.read(searchResultsProvider.notifier).loadMore();
        }
        return false;
      },
      child: ListView.separated(
        key: const ValueKey('search-results'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: items.length + (showLoader ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final item = items[index];
          return FeedCardItem(
            item: item,
            onTap: () => context.push(RouteNames.feedDetail, extra: item),
            onFavoriteToggle: () => toggleFeedLike(context, ref, item.id),
          );
        },
      ),
    );
  }
}
