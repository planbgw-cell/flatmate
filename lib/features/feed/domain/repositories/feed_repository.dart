import '../../../location/domain/models/location_item.dart';
import '../models/feed_item.dart';

/// Feed API contract — swap [MockFeedRepository] for a Dio/FastAPI impl later.
abstract class FeedRepository {
  /// Paginated feed with category + geo filter.
  Future<List<FeedItem>> fetchPage({
    required int page,
    int pageSize = 10,
    String category = 'all',
    LocationItem? location,
    double radiusKm = 3,
  });

  /// Explicit geo-aware list API (FastAPI-ready signature).
  Future<List<FeedItem>> fetchFeeds({
    required int page,
    int pageSize = 10,
    String category = 'all',
    LocationItem? location,
    double radiusKm = 3,
  });

  /// Single post detail by id.
  Future<FeedItem?> fetchById(String id);

  /// Toggle favorite (관심) and return the updated item (likeCount synced).
  Future<FeedItem> toggleFavorite(String id);

  /// Insert a newly created post (appears at top of subsequent fetches).
  /// [location] supplies the PostGIS point for geo queries.
  Future<FeedItem> createPost(FeedItem item, {LocationItem? location});

  /// Convenience: category-filtered first page.
  Future<List<FeedItem>> fetchByCategory(
    String category, {
    int page = 1,
    int pageSize = 10,
    LocationItem? location,
    double radiusKm = 3,
  });
}
