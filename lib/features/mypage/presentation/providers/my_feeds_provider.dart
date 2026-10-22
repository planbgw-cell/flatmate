import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../../../feed/presentation/providers/feed_provider.dart';

enum MyFeedsFilter {
  all('전체'),
  selling('판매중'),
  completed('거래완료');

  const MyFeedsFilter(this.label);
  final String label;
}

final myFeedsFilterProvider =
    StateProvider<MyFeedsFilter>((ref) => MyFeedsFilter.all);

/// 내 판매글 (`GET /users/me/feeds`). Refetches on account change and after
/// any like / trade-status / delete ([feedMutationTickProvider]).
class MyFeedsNotifier extends AsyncNotifier<List<FeedItem>> {
  @override
  Future<List<FeedItem>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    ref.watch(feedMutationTickProvider);
    final filter = ref.watch(myFeedsFilterProvider);
    if (userId == null) return const [];

    final repo = ref.read(feedRepositoryProvider);
    switch (filter) {
      case MyFeedsFilter.all:
        return repo.getMyFeeds();
      case MyFeedsFilter.completed:
        return repo.getMyFeeds(status: TradeStatus.completed);
      case MyFeedsFilter.selling:
        // "판매중" covers 예약중 too, as in Daangn.
        final lists = await Future.wait([
          repo.getMyFeeds(status: TradeStatus.selling),
          repo.getMyFeeds(status: TradeStatus.reserved),
        ]);
        return lists.expand((e) => e).toList()
          ..sort((a, b) => b.postedAt.compareTo(a.postedAt));
    }
  }
}

final myFeedsProvider =
    AsyncNotifierProvider<MyFeedsNotifier, List<FeedItem>>(MyFeedsNotifier.new);

/// 관심목록 (`GET /users/me/likes`).
class MyLikesNotifier extends AsyncNotifier<List<FeedItem>> {
  @override
  Future<List<FeedItem>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    ref.watch(feedMutationTickProvider);
    if (userId == null) return const [];
    return ref.read(feedRepositoryProvider).getMyLikes();
  }

  /// Removes the row immediately; restores it if the unlike call fails.
  Future<void> unlike(FeedItem item) async {
    final before = state.value ?? const <FeedItem>[];
    state = AsyncData(before.where((e) => e.id != item.id).toList());
    try {
      final result = await ref
          .read(feedRepositoryProvider)
          .toggleLike(item.id, currentlyLiked: true);
      ref
          .read(favoriteItemProvider(item.id).notifier)
          .sync(isLiked: result.isLiked, likeCount: result.likeCount);
      ref.read(feedMutationTickProvider.notifier).state++;
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }
}

final myLikesProvider =
    AsyncNotifierProvider<MyLikesNotifier, List<FeedItem>>(MyLikesNotifier.new);
