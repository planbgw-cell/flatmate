import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../block_report/presentation/providers/blocked_users_provider.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../../../feed/presentation/providers/feed_provider.dart';
import '../../../location/presentation/providers/location_provider.dart';

/// 동네소식 (`feed_type=LOCAL_NEWS`) within the current dong radius, paged.
class CommunityFeedNotifier extends AsyncNotifier<FeedListState> {
  static const pageSize = 20;
  static final _category = FeedCategory.community.name;

  Future<List<FeedItem>> _fetch(int page) async {
    final blocked = readBlockedAuthorIds(ref);
    final items = await ref.read(feedRepositoryProvider).fetchFeeds(
          page: page,
          pageSize: pageSize,
          category: _category,
          location: ref.read(currentLocationProvider),
          radiusKm: ref.read(locationRadiusProvider),
        );
    return withoutBlockedAuthors(items, await blocked);
  }

  @override
  Future<FeedListState> build() async {
    ref.watch(currentLocationProvider);
    ref.watch(locationRadiusProvider);
    // New / edited / deleted posts and blocks refetch the list.
    ref.watch(feedMutationTickProvider);
    final items = await _fetch(1);
    return FeedListState(
      items: items,
      page: 1,
      hasMore: items.length >= pageSize,
    );
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final items = await _fetch(1);
      return FeedListState(
        items: items,
        page: 1,
        hasMore: items.length >= pageSize,
      );
    });
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.page + 1;
      final more = await _fetch(nextPage);
      state = AsyncData(
        FeedListState(
          items: [...current.items, ...more],
          page: nextPage,
          hasMore: more.length >= pageSize,
        ),
      );
    } catch (error, stack) {
      state = AsyncError(error, stack);
    }
  }
}

final communityFeedProvider =
    AsyncNotifierProvider<CommunityFeedNotifier, FeedListState>(
  CommunityFeedNotifier.new,
);
