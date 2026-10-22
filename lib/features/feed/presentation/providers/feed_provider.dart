import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/di/injection.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../domain/models/feed_item.dart';
import '../../domain/repositories/feed_repository.dart';

/// Shared repository instance (same GetIt singleton — swap for FastAPI later).
final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return sl<FeedRepository>();
});

/// Selected category filter key (`all`, `housing`, `job`, …).
final selectedCategoryProvider = StateProvider<String>((ref) {
  return FeedCategory.all.name;
});

/// Daangn-style default: newest first within the selected radius.
final feedSortProvider = StateProvider<FeedSort>((ref) => FeedSort.latest);

class FeedListState {
  const FeedListState({
    required this.items,
    required this.page,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<FeedItem> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  FeedListState copyWith({
    List<FeedItem>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return FeedListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class FeedListNotifier extends AsyncNotifier<FeedListState> {
  static const _pageSize = 10;

  FeedRepository get _repo => ref.read(feedRepositoryProvider);

  @override
  Future<FeedListState> build() async {
    final category = ref.watch(selectedCategoryProvider);
    final location = ref.watch(currentLocationProvider);
    final radiusKm = ref.watch(locationRadiusProvider);
    final sort = ref.watch(feedSortProvider);
    final items = await _repo.fetchFeeds(
      page: 1,
      pageSize: _pageSize,
      category: category,
      location: location,
      radiusKm: radiusKm,
      sort: sort,
    );
    return FeedListState(
      items: items,
      page: 1,
      hasMore: items.length >= _pageSize,
    );
  }

  Future<void> refresh() async {
    final category = ref.read(selectedCategoryProvider);
    final location = ref.read(currentLocationProvider);
    final radiusKm = ref.read(locationRadiusProvider);
    final sort = ref.read(feedSortProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchFeeds(
        page: 1,
        pageSize: _pageSize,
        category: category,
        location: location,
        radiusKm: radiusKm,
        sort: sort,
      );
      return FeedListState(
        items: items,
        page: 1,
        hasMore: items.length >= _pageSize,
      );
    });
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final category = ref.read(selectedCategoryProvider);
      final location = ref.read(currentLocationProvider);
      final radiusKm = ref.read(locationRadiusProvider);
      final nextPage = current.page + 1;
      final more = await _repo.fetchFeeds(
        page: nextPage,
        pageSize: _pageSize,
        category: category,
        location: location,
        radiusKm: radiusKm,
        sort: ref.read(feedSortProvider),
      );
      state = AsyncData(
        FeedListState(
          items: [...current.items, ...more],
          page: nextPage,
          hasMore: more.length >= _pageSize,
        ),
      );
    } catch (error, stack) {
      state = AsyncError(error, stack);
    }
  }

  void patchItem(FeedItem updated) {
    final current = state.value;
    if (current == null) return;
    final next = current.items
        .map((item) => item.id == updated.id ? updated : item)
        .toList();
    state = AsyncData(current.copyWith(items: next));
  }

  void removeItem(String id) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        items: current.items.where((item) => item.id != id).toList(),
      ),
    );
  }
}

final feedListProvider =
    AsyncNotifierProvider<FeedListNotifier, FeedListState>(FeedListNotifier.new);

/// Bumped after like / trade-status / delete so other lists (마이페이지)
/// refetch without the feed feature knowing about them.
final feedMutationTickProvider = StateProvider<int>((ref) => 0);

/// Server copies returned by author actions, for screens showing items that
/// are not in the current feed page (e.g. opened from 마이페이지).
final feedOverridesProvider =
    StateProvider<Map<String, FeedItem>>((ref) => const {});

class FavoriteInfo {
  const FavoriteInfo({required this.isFavorite, required this.likeCount});

  final bool isFavorite;
  final int likeCount;
}

/// Per-item favorite state — stays in sync with [feedListProvider].
class FavoriteItemNotifier extends Notifier<FavoriteInfo> {
  FavoriteItemNotifier(this.itemId);

  final String itemId;

  @override
  FavoriteInfo build() {
    final list = ref.watch(feedListProvider).value;
    final fromList = list?.items.where((e) => e.id == itemId).firstOrNull;
    if (fromList != null) {
      return FavoriteInfo(
        isFavorite: fromList.isFavorite,
        likeCount: fromList.likeCount,
      );
    }
    return stateOrNull ??
        const FavoriteInfo(isFavorite: false, likeCount: 0);
  }

  /// Seed counts when opening detail for an item not in the current list page.
  void hydrate(FeedItem item) {
    if (item.id != itemId) return;
    final current = stateOrNull;
    if (current == null ||
        (current.likeCount == 0 &&
            !current.isFavorite &&
            (item.likeCount > 0 || item.isFavorite))) {
      state = FavoriteInfo(
        isFavorite: item.isFavorite,
        likeCount: item.likeCount,
      );
    }
  }

  /// Applies a like change made elsewhere (e.g. 관심목록) to this item.
  void sync({required bool isLiked, required int likeCount}) {
    state = FavoriteInfo(isFavorite: isLiked, likeCount: likeCount);
    final listItem = ref
        .read(feedListProvider)
        .value
        ?.items
        .where((e) => e.id == itemId)
        .firstOrNull;
    if (listItem != null) {
      ref.read(feedListProvider.notifier).patchItem(
            listItem.copyWith(isFavorite: isLiked, likeCount: likeCount),
          );
    }
  }

  /// Optimistic: flips immediately, then syncs with `LikeOut` or rolls back.
  Future<void> toggle() async {
    final before = state;
    final likedNext = !before.isFavorite;
    state = FavoriteInfo(
      isFavorite: likedNext,
      likeCount: math.max(0, before.likeCount + (likedNext ? 1 : -1)),
    );
    try {
      final result = await ref
          .read(feedRepositoryProvider)
          .toggleLike(itemId, currentlyLiked: before.isFavorite);
      final listItem = ref
          .read(feedListProvider)
          .value
          ?.items
          .where((e) => e.id == itemId)
          .firstOrNull;
      if (listItem != null) {
        ref.read(feedListProvider.notifier).patchItem(
              listItem.copyWith(
                isFavorite: result.isLiked,
                likeCount: result.likeCount,
              ),
            );
      }
      state = FavoriteInfo(
        isFavorite: result.isLiked,
        likeCount: result.likeCount,
      );
      ref.read(feedMutationTickProvider.notifier).state++;
    } catch (_) {
      state = before;
      rethrow;
    }
  }
}

final favoriteItemProvider =
    NotifierProvider.family<FavoriteItemNotifier, FavoriteInfo, String>(
  FavoriteItemNotifier.new,
);

/// Latest feed item snapshot (author override → list patch → detail seed),
/// with the live like state applied.
final feedItemProvider = Provider.family<FeedItem, FeedItem>((ref, seed) {
  final override = ref.watch(feedOverridesProvider)[seed.id];
  final list = ref.watch(feedListProvider).value;
  final fromList = list?.items.where((e) => e.id == seed.id).firstOrNull;
  final base = override ?? fromList ?? seed;

  final fav = ref.watch(favoriteItemProvider(seed.id));
  if (fav.isFavorite != base.isFavorite ||
      fav.likeCount != base.likeCount && fav.likeCount != 0) {
    return base.copyWith(
      isFavorite: fav.isFavorite,
      likeCount: fav.likeCount,
    );
  }
  return base;
});