import 'package:flatmate_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flatmate_app/features/feed/data/repositories/mock_feed_repository.dart';
import 'package:flatmate_app/features/feed/domain/models/feed_item.dart';
import 'package:flatmate_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:flatmate_app/features/location/domain/models/location_item.dart';
import 'package:flatmate_app/features/search/data/search_history_repository.dart';
import 'package:flatmate_app/features/search/presentation/providers/search_provider.dart';
import 'package:flatmate_app/features/search/presentation/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SearchHistoryRepository> _history([List<String>? initial]) async {
  SharedPreferences.setMockInitialValues({
    SearchHistoryRepository.storageKey: ?initial,
  });
  return SearchHistoryRepository(await SharedPreferences.getInstance());
}

final _piano = FeedItem(
  id: '31',
  title: '디지털피아노 팝니다',
  neighborhood: '정자동',
  postedAt: DateTime(2026, 10, 23),
  priceOrCondition: '150,000원',
  thumbnailUrl: '',
  likeCount: 0,
  chatCount: 0,
  category: FeedCategory.market,
  badges: const [],
  isBumped: false,
  authorId: '5',
);

class _SearchFeeds extends MockFeedRepository {
  final queries = <String>[];
  LocationItem? lastLocation;
  double? lastRadius;

  @override
  Future<List<FeedItem>> searchFeeds({
    required String query,
    int page = 1,
    int pageSize = 20,
    LocationItem? location,
    double radiusKm = 3,
  }) async {
    queries.add(query);
    lastLocation = location;
    lastRadius = radiusKm;
    return query.contains('피아노') ? [_piano] : const [];
  }
}

void main() {
  group('SearchHistoryRepository', () {
    test('newest first; a repeated term moves to the front', () async {
      final repo = await _history();
      await repo.addSearchTerm('자전거');
      await repo.addSearchTerm(' 디지털피아노 ');
      await repo.addSearchTerm('자전거');
      expect(repo.getRecentSearches(), ['자전거', '디지털피아노']);
    });

    test('keeps at most 10 terms, dropping the oldest', () async {
      final repo = await _history();
      for (var i = 1; i <= 11; i++) {
        await repo.addSearchTerm('검색어$i');
      }
      final terms = repo.getRecentSearches();
      expect(terms, hasLength(10));
      expect(terms.first, '검색어11');
      expect(terms, isNot(contains('검색어1')));
    });

    test('blank terms are ignored; remove and clear persist', () async {
      final repo = await _history(['책상', '의자', '램프']);
      await repo.addSearchTerm('   ');
      expect(repo.getRecentSearches(), ['책상', '의자', '램프']);

      await repo.removeSearchTerm('의자');
      expect(repo.getRecentSearches(), ['책상', '램프']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(SearchHistoryRepository.storageKey),
          ['책상', '램프']);

      await repo.clearAllSearchTerms();
      expect(repo.getRecentSearches(), isEmpty);
    });
  });

  testWidgets(
      'search screen: dong hint · recent tap searches · empty result · '
      'X / 전체 삭제', (tester) async {
    final history = await _history(['디지털피아노', '자전거']);
    final feeds = _SearchFeeds();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchHistoryRepositoryProvider.overrideWithValue(history),
          feedRepositoryProvider.overrideWithValue(feeds),
          currentUserIdProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('${kDefaultLocation.dongName} 근처에서 검색'),
      findsOneWidget,
    );
    expect(find.text('최근 검색'), findsOneWidget);
    expect(find.byKey(const ValueKey('recent-search-디지털피아노')), findsOneWidget);
    expect(find.byKey(const ValueKey('recent-search-자전거')), findsOneWidget);

    // Recent tile → field filled, search runs within the dong radius.
    await tester.tap(find.byKey(const ValueKey('recent-search-디지털피아노')));
    await tester.pumpAndSettle();
    expect(feeds.queries, ['디지털피아노']);
    expect(feeds.lastLocation?.id, kDefaultLocation.id);
    expect(feeds.lastRadius, 3);
    expect(find.text('디지털피아노 팝니다'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('search-field')))
          .controller
          ?.text,
      '디지털피아노',
    );

    // No-match keyword via the keyboard search action.
    await tester.tap(find.byKey(const ValueKey('search-clear-text')));
    await tester.pumpAndSettle();
    expect(find.text('최근 검색'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('search-field')), '없는검색어');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('검색 결과가 없습니다.'), findsOneWidget);
    expect(history.getRecentSearches(), ['없는검색어', '디지털피아노', '자전거']);

    // Back to 최근 검색: X removes one, 전체 삭제 (confirmed) clears all.
    await tester.tap(find.byKey(const ValueKey('search-clear-text')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recent-remove-자전거')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recent-search-자전거')), findsNothing);
    expect(history.getRecentSearches(), ['없는검색어', '디지털피아노']);

    await tester.tap(find.byKey(const ValueKey('search-clear-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-clear-search')));
    await tester.pumpAndSettle();
    expect(find.text('최근 검색어가 없습니다.'), findsOneWidget);
    expect(history.getRecentSearches(), isEmpty);
  });

  testWidgets('search button ignores a blank keyword', (tester) async {
    final feeds = _SearchFeeds();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchHistoryRepositoryProvider.overrideWithValue(await _history()),
          feedRepositoryProvider.overrideWithValue(feeds),
          currentUserIdProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.enterText(find.byKey(const ValueKey('search-field')), '   ');
    await tester.tap(find.byKey(const ValueKey('search-submit')));
    await tester.pumpAndSettle();
    expect(feeds.queries, isEmpty);
    expect(find.text('최근 검색어가 없습니다.'), findsOneWidget);
  });
}
