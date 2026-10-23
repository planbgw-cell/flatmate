import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection.dart';
import '../../../block_report/presentation/providers/blocked_users_provider.dart';
import '../../../feed/presentation/providers/feed_provider.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../data/search_history_repository.dart';

final searchHistoryRepositoryProvider = Provider<SearchHistoryRepository>((ref) {
  return SearchHistoryRepository(sl<SharedPreferences>());
});

/// 최근 검색어, newest first (max [SearchHistoryRepository.maxTerms]).
class RecentSearchesNotifier extends Notifier<List<String>> {
  SearchHistoryRepository get _repo =>
      ref.read(searchHistoryRepositoryProvider);

  @override
  List<String> build() => _repo.getRecentSearches();

  Future<void> add(String term) async => state = await _repo.addSearchTerm(term);

  Future<void> remove(String term) async =>
      state = await _repo.removeSearchTerm(term);

  Future<void> clear() async {
    await _repo.clearAllSearchTerms();
    state = const [];
  }
}

final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(
  RecentSearchesNotifier.new,
);

/// Submitted keyword; empty shows 최근 검색 instead of results. Reset each
/// time the search screen opens.
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// `GET /feeds?q=` within the current dong radius, paged.
class SearchResultsNotifier extends AsyncNotifier<FeedListState> {
  static const pageSize = 20;

  @override
  Future<FeedListState> build() async {
    final query = ref.watch(searchQueryProvider).trim();
    final location = ref.watch(currentLocationProvider);
    final radiusKm = ref.watch(locationRadiusProvider);
    // Deletes / blocks elsewhere refetch the results.
    ref.watch(feedMutationTickProvider);
    if (query.isEmpty) {
      return const FeedListState(items: [], page: 1, hasMore: false);
    }
    final blocked = readBlockedAuthorIds(ref);
    final items = await ref.read(feedRepositoryProvider).searchFeeds(
          query: query,
          pageSize: pageSize,
          location: location,
          radiusKm: radiusKm,
        );
    return FeedListState(
      items: withoutBlockedAuthors(items, await blocked),
      page: 1,
      hasMore: items.length >= pageSize,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.page + 1;
      final more = await ref.read(feedRepositoryProvider).searchFeeds(
            query: ref.read(searchQueryProvider).trim(),
            page: nextPage,
            pageSize: pageSize,
            location: ref.read(currentLocationProvider),
            radiusKm: ref.read(locationRadiusProvider),
          );
      final blocked = await readBlockedAuthorIds(ref);
      state = AsyncData(
        FeedListState(
          items: [...current.items, ...withoutBlockedAuthors(more, blocked)],
          page: nextPage,
          hasMore: more.length >= pageSize,
        ),
      );
    } catch (error, stack) {
      state = AsyncError(error, stack);
    }
  }
}

final searchResultsProvider =
    AsyncNotifierProvider.autoDispose<SearchResultsNotifier, FeedListState>(
  SearchResultsNotifier.new,
);
