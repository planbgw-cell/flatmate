import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/common_widgets/skeleton_card.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../feed/presentation/feed_actions.dart';
import '../../../feed/presentation/widgets/feed_card_item.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../providers/community_feed_provider.dart';

/// Tab 1 — 동네소식 목록.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dong = ref.watch(currentLocationProvider).dongName;
    final feedAsync = ref.watch(communityFeedProvider);
    final data = feedAsync.value;

    final Widget body;
    if (data == null) {
      final error = feedAsync.error;
      body = feedAsync.hasError
          ? Center(
              child: Text(
                error is ApiException ? error.message : '동네소식을 불러오지 못했어요.',
                style: AppTypography.bodyMedium,
              ),
            )
          : const SkeletonCardList(count: 5);
    } else {
      final items = data.items;
      final showLoader = data.hasMore || data.isLoadingMore;
      body = RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(communityFeedProvider.notifier).refresh(),
        child: items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Text(
                    '아직 우리 동네 소식이 없어요.\n첫 소식을 올려 보세요.',
                    key: const ValueKey('community-empty'),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium,
                  ),
                ],
              )
            : NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  final metrics = notification.metrics;
                  if (metrics.pixels >= metrics.maxScrollExtent - 240) {
                    ref.read(communityFeedProvider.notifier).loadMore();
                  }
                  return false;
                },
                child: ListView.separated(
                  key: const ValueKey('community-list'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: items.length + (showLoader ? 1 : 0),
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index >= items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final item = items[index];
                    return FeedCardItem(
                      item: item,
                      onTap: () =>
                          context.push(RouteNames.feedDetail, extra: item),
                      onFavoriteToggle: () =>
                          toggleFeedLike(context, ref, item.id),
                    );
                  },
                ),
              ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('동네소식 · $dong', style: AppTypography.header2),
      ),
      body: body,
    );
  }
}
