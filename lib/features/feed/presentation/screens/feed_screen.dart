import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/common_widgets/custom_app_bar.dart';
import '../../../../core/common_widgets/skeleton_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../../location/presentation/widgets/location_select_modal.dart';
import '../../domain/models/feed_item.dart';
import '../../domain/repositories/feed_repository.dart';
import '../feed_actions.dart';
import '../providers/feed_provider.dart';
import '../widgets/feed_card_item.dart';
import '../widgets/feed_filter_bar.dart';

/// Tab 0 — 통합 피드 (Riverpod + 무한 스크롤 + Pull-to-Refresh).
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      ref.read(feedListProvider.notifier).loadMore();
    }
  }

  void _handleUserScroll(UserScrollNotification notification) {
    final direction = notification.direction;
    if (direction == ScrollDirection.reverse && _chromeVisible) {
      setState(() => _chromeVisible = false);
    } else if (direction == ScrollDirection.forward && !_chromeVisible) {
      setState(() => _chromeVisible = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryKey = ref.watch(selectedCategoryProvider);
    final category = FeedCategoryX.fromKey(categoryKey);
    final feedAsync = ref.watch(feedListProvider);
    final location = ref.watch(currentLocationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        locationName: location.displayName,
        visible: _chromeVisible,
        notificationBadge: true,
        onLocationTap: () => showLocationSelectModal(context),
        onSearchTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('검색은 준비 중입니다.')),
          );
        },
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          _handleUserScroll(notification);
          return false;
        },
        child: Column(
          children: [
            FeedFilterBar(
              selected: category,
              onSelected: (value) {
                ref.read(selectedCategoryProvider.notifier).state = value.name;
              },
            ),
            _FeedSortBar(
              selected: ref.watch(feedSortProvider),
              onSelected: (sort) =>
                  ref.read(feedSortProvider.notifier).state = sort,
            ),
            const Divider(height: 1),
            Expanded(
              child: feedAsync.when(
                loading: () => const SkeletonCardList(count: 5),
                error: (error, _) => Center(child: Text('$error')),
                data: (data) {
                  final items = data.items;
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () =>
                        ref.read(feedListProvider.notifier).refresh(),
                    child: items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.sizeOf(context).height * 0.4,
                                child: Center(
                                  child: Text(
                                    '${category.label} 게시글이 아직 없습니다.',
                                    style: AppTypography.bodyMedium,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: items.length +
                                ((data.hasMore || data.isLoadingMore)
                                    ? 1
                                    : 0),
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              if (index >= items.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(AppSpacing.lg),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              final item = items[index];
                              return FeedCardItem(
                                item: item,
                                onTap: () => context.push(
                                  RouteNames.feedDetail,
                                  extra: item,
                                ),
                                onFavoriteToggle: () =>
                                    toggleFeedLike(context, ref, item.id),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedSortBar extends StatelessWidget {
  const _FeedSortBar({required this.selected, required this.onSelected});

  final FeedSort selected;
  final ValueChanged<FeedSort> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.xs,
        AppSpacing.xxs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (final sort in FeedSort.values)
            TextButton(
              key: ValueKey('feed-sort-${sort.name}'),
              onPressed: sort == selected ? null : () => onSelected(sort),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                minimumSize: const Size(0, 32),
              ),
              child: Text(
                sort.label,
                style: AppTypography.bodyMedium.copyWith(
                  color: sort == selected
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                  fontWeight:
                      sort == selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
