import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../block_report/presentation/providers/blocked_users_provider.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../../../feed/domain/repositories/feed_repository.dart';
import '../../../feed/presentation/providers/feed_provider.dart';
import '../../../location/presentation/providers/location_provider.dart';

/// 동네소식 chips: [우리 동네] (`sigungu`, default) / [우리 권역 축제] (`zone`).
final communityScopeProvider =
    StateProvider<PublicScope>((ref) => PublicScope.sigungu);

/// 동네소식 (`feed_type=LOCAL_NEWS`) of the current dong by [PublicScope],
/// paged.
class CommunityFeedNotifier extends AsyncNotifier<FeedListState> {
  static const pageSize = 20;

  Future<List<FeedItem>> _fetch(int page) async {
    final scope = ref.read(communityScopeProvider);
    final dong = await ref.read(serverDongProvider.future);
    final locationId = int.tryParse(dong?.id ?? '');
    if (locationId == null) {
      throw StateError('동네 정보를 확인할 수 없어요. 동네를 다시 설정해 주세요.');
    }
    final blocked = readBlockedAuthorIds(ref);
    final items = await ref.read(feedRepositoryProvider).fetchScopedFeeds(
          category: FeedCategory.community.name,
          locationId: locationId,
          scope: scope,
          page: page,
          pageSize: pageSize,
        );
    return withoutBlockedAuthors(items, await blocked);
  }

  @override
  Future<FeedListState> build() async {
    ref.watch(communityScopeProvider);
    // `.future`: refetch on a new dong, not on its loading → data transition.
    await ref.watch(serverDongProvider.future);
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
