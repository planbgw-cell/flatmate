import '../../../location/domain/models/location_item.dart';
import '../../domain/models/feed_item.dart';
import '../../domain/repositories/feed_repository.dart';
import 'mock_feed_repository.dart';

/// Compatibility wrapper — delegates to [MockFeedRepository].
class FeedRepositoryImpl implements FeedRepository {
  FeedRepositoryImpl([MockFeedRepository? mock])
      : _mock = mock ?? MockFeedRepository();

  final MockFeedRepository _mock;

  @override
  Future<List<FeedItem>> fetchPage({
    required int page,
    int pageSize = 10,
    String category = 'all',
    LocationItem? location,
    double radiusKm = 3,
  }) {
    return _mock.fetchPage(
      page: page,
      pageSize: pageSize,
      category: category,
      location: location,
      radiusKm: radiusKm,
    );
  }

  @override
  Future<List<FeedItem>> fetchFeeds({
    required int page,
    int pageSize = 10,
    String category = 'all',
    LocationItem? location,
    double radiusKm = 3,
    FeedSort sort = FeedSort.latest,
  }) {
    return _mock.fetchFeeds(
      page: page,
      pageSize: pageSize,
      category: category,
      location: location,
      radiusKm: radiusKm,
      sort: sort,
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
    return _mock.fetchByCategory(
      category,
      page: page,
      pageSize: pageSize,
      location: location,
      radiusKm: radiusKm,
    );
  }

  @override
  Future<FeedItem?> fetchById(String id) => _mock.fetchById(id);

  @override
  Future<FeedItem> toggleFavorite(String id) => _mock.toggleFavorite(id);

  @override
  Future<FeedItem> createPost(FeedItem item, {LocationItem? location}) =>
      _mock.createPost(item, location: location);
}
