import 'dart:math';

import '../../../location/domain/models/location_item.dart';
import '../../domain/models/feed_item.dart';
import '../../domain/repositories/feed_repository.dart';

/// In-memory Mock REST layer with artificial network latency (300–500ms).
class MockFeedRepository implements FeedRepository {
  MockFeedRepository({Random? random}) : _random = random ?? Random();

  final Random _random;
  final Map<String, FeedItem> _store = {};
  final Set<String> _favorites = {};
  final List<String> _likedOrder = [];
  final Set<String> _deleted = {};
  final List<String> _userPostIds = [];
  bool _seeded = false;

  static const _maxPages = 2;

  Future<void> _delay() {
    final ms = 300 + _random.nextInt(201);
    return Future<void>.delayed(Duration(milliseconds: ms));
  }

  void _ensureSeed() {
    if (_seeded) return;
    for (final item in buildMockFeedItems()) {
      _store[item.id] = item;
    }
    _seeded = true;
  }

  List<FeedItem> _catalog() {
    _ensureSeed();
    return _store.values.toList()
      ..sort((a, b) => b.postedAt.compareTo(a.postedAt));
  }

  FeedItem _withFavorite(FeedItem item) {
    final liked = _favorites.contains(item.id);
    return item.copyWith(isFavorite: liked);
  }

  bool _withinRadius(FeedItem item, LocationItem? location, double radiusKm) {
    if (location == null) return true;
    final anchor = locationForNeighborhood(item.neighborhood);
    if (anchor == null) return true;
    return location.distanceKmTo(anchor) <= radiusKm;
  }

  List<FeedItem> _userPostsFiltered({
    required String category,
    LocationItem? location,
    double radiusKm = 3,
  }) {
    return _userPostIds
        .map((id) => _store[id])
        .whereType<FeedItem>()
        .where((item) => item.matchesCategoryKey(category))
        .where((item) => _withinRadius(item, location, radiusKm))
        .map(_withFavorite)
        .toList();
  }

  List<FeedItem> _paged({
    required int page,
    required int pageSize,
    required String category,
    LocationItem? location,
    double radiusKm = 3,
  }) {
    final userPosts = _userPostsFiltered(
      category: category,
      location: location,
      radiusKm: radiusKm,
    );

    final seed = _catalog()
        .where((item) => !_userPostIds.contains(item.id))
        .where((item) => item.matchesCategoryKey(category))
        .where((item) => _withinRadius(item, location, radiusKm))
        .toList();

    if (page == 1) {
      if (seed.isEmpty) {
        return userPosts.take(pageSize).toList();
      }
      final remaining = pageSize - userPosts.length;
      if (remaining <= 0) return userPosts.take(pageSize).toList();

      final cloned = List.generate(remaining.clamp(0, pageSize), (index) {
        final source = seed[index % seed.length];
        final id = '${source.id}-p$page-$index';
        final existing = _store[id];
        if (existing != null) return _withFavorite(existing);
        final item = source.copyWith(
          id: id,
          postedAt: source.postedAt.subtract(Duration(minutes: index * 7)),
          likeCount: source.likeCount + (index % 5),
          chatCount: source.chatCount + (index % 3),
          isBumped: source.isBumped && index < 2,
          isFavorite: _favorites.contains(id),
        );
        _store[id] = item;
        return item;
      });
      return [...userPosts, ...cloned];
    }

    if (seed.isEmpty) return const [];
    final maxItems = seed.length * _maxPages;
    final start = (page - 1) * pageSize;
    if (start >= maxItems) return const [];

    final count = (maxItems - start).clamp(0, pageSize);
    return List.generate(count, (index) {
      final source = seed[(start + index) % seed.length];
      final pageOffset = start + index;
      final id = '${source.id}-p$page-$pageOffset';

      final existing = _store[id];
      if (existing != null) return _withFavorite(existing);

      final cloned = source.copyWith(
        id: id,
        postedAt: source.postedAt.subtract(Duration(minutes: pageOffset * 7)),
        likeCount: source.likeCount + (pageOffset % 5),
        chatCount: source.chatCount + (pageOffset % 3),
        isBumped: false,
        isFavorite: _favorites.contains(id),
      );
      _store[id] = cloned;
      return cloned;
    });
  }

  @override
  Future<List<FeedItem>> fetchFeeds({
    required int page,
    int pageSize = 10,
    String category = 'all',
    LocationItem? location,
    double radiusKm = 3,
    FeedSort sort = FeedSort.latest,
  }) async {
    await _delay();
    if (page < 1) return const [];
    final items = _paged(
      page: page,
      pageSize: pageSize,
      category: category,
      location: location,
      radiusKm: radiusKm,
    ).where((item) => !_deleted.contains(item.id)).toList();
    if (sort != FeedSort.distance || location == null) return items;
    double distance(FeedItem item) {
      final anchor = locationForNeighborhood(item.neighborhood);
      return anchor == null ? double.infinity : location.distanceKmTo(anchor);
    }

    return [...items]..sort((a, b) => distance(a).compareTo(distance(b)));
  }

  @override
  Future<List<FeedItem>> fetchPage({
    required int page,
    int pageSize = 10,
    String category = 'all',
    LocationItem? location,
    double radiusKm = 3,
  }) {
    return fetchFeeds(
      page: page,
      pageSize: pageSize,
      category: category,
      location: location,
      radiusKm: radiusKm,
    );
  }

  @override
  Future<List<FeedItem>> fetchByCategory(
    String category, {
    int page = 1,
    int pageSize = 10,
    LocationItem? location,
    double radiusKm = 3,
  }) {
    return fetchFeeds(
      page: page,
      pageSize: pageSize,
      category: category,
      location: location,
      radiusKm: radiusKm,
    );
  }

  @override
  Future<FeedItem?> fetchById(String id) async {
    await _delay();
    _ensureSeed();
    if (_deleted.contains(id)) return null;
    final cached = _store[id];
    if (cached != null) return _withFavorite(cached);

    final baseId = id.split('-p').first;
    final base = _store[baseId];
    if (base != null) {
      final cloned = base.copyWith(id: id, isFavorite: _favorites.contains(id));
      _store[id] = cloned;
      return cloned;
    }
    return null;
  }

  @override
  Future<LikeResult> toggleLike(
    String id, {
    required bool currentlyLiked,
  }) async {
    final item = await fetchById(id);
    if (item == null) {
      throw StateError('Feed item not found: $id');
    }
    final liked = !currentlyLiked;
    final wasLiked = _favorites.contains(id);
    liked ? _favorites.add(id) : _favorites.remove(id);
    final delta = liked == wasLiked ? 0 : (liked ? 1 : -1);
    final count = (item.likeCount + delta).clamp(0, 1 << 30);
    _store[id] = item.copyWith(isFavorite: liked, likeCount: count);
    if (liked) {
      _likedOrder
        ..remove(id)
        ..insert(0, id);
    } else {
      _likedOrder.remove(id);
    }
    return (isLiked: liked, likeCount: count);
  }

  @override
  Future<FeedItem> updateTradeStatus(String id, TradeStatus status) async {
    final item = await fetchById(id);
    if (item == null) {
      throw StateError('Feed item not found: $id');
    }
    final updated = item.copyWith(tradeStatus: status);
    _store[id] = updated;
    return updated;
  }

  @override
  Future<void> deleteFeed(String id) async {
    await _delay();
    _deleted.add(id);
    _userPostIds.remove(id);
    _likedOrder.remove(id);
    _favorites.remove(id);
  }

  /// Posts created in this session stand in for "mine".
  @override
  Future<List<FeedItem>> getMyFeeds({TradeStatus? status, int page = 1}) async {
    await _delay();
    if (page > 1) return const [];
    return _userPostIds
        .map((id) => _store[id])
        .whereType<FeedItem>()
        .where((item) => status == null || item.tradeStatus == status)
        .map(_withFavorite)
        .toList();
  }

  @override
  Future<List<FeedItem>> getMyLikes({int page = 1}) async {
    await _delay();
    if (page > 1) return const [];
    return _likedOrder
        .map((id) => _store[id])
        .whereType<FeedItem>()
        .map(_withFavorite)
        .toList();
  }

  @override
  Future<FeedItem> createPost(FeedItem item, {LocationItem? location}) async {
    await _delay();
    _ensureSeed();
    final created = item.copyWith(postedAt: DateTime.now());
    _store[created.id] = created;
    _userPostIds.remove(created.id);
    _userPostIds.insert(0, created.id);
    return created;
  }
}
