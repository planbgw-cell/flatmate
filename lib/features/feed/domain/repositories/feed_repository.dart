import '../../../location/domain/models/location_item.dart';
import '../models/feed_item.dart';

/// Feed ordering (`GET /feeds?sort=`). `distance` needs a location.
enum FeedSort {
  latest('최신순'),
  distance('가까운순');

  const FeedSort(this.label);
  final String label;
}

/// Server like state after a toggle (`LikeOut`).
typedef LikeResult = ({bool isLiked, int likeCount});

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
    FeedSort sort = FeedSort.latest,
  });

  /// Single post detail by id.
  Future<FeedItem?> fetchById(String id);

  /// 관심 추가/해제 (`POST` / `DELETE /feeds/{id}/like`).
  Future<LikeResult> toggleLike(String id, {required bool currentlyLiked});

  /// Author only (`PATCH /feeds/{id}`). [imageUrls] are server paths (first
  /// one becomes the thumbnail); `feed_type` cannot change.
  Future<FeedItem> updateFeed(
    String id, {
    required String title,
    required String content,
    required Map<String, dynamic> extraMeta,
    required List<String> imageUrls,
  });

  /// Author only (`PATCH /feeds/{id}/status`).
  Future<FeedItem> updateTradeStatus(String id, TradeStatus status);

  /// Author only soft delete (`DELETE /feeds/{id}`).
  Future<void> deleteFeed(String id);

  /// 내 판매글 (`GET /users/me/feeds`), newest first.
  Future<List<FeedItem>> getMyFeeds({TradeStatus? status, int page = 1});

  /// 관심목록 (`GET /users/me/likes`), most recently liked first.
  Future<List<FeedItem>> getMyLikes({int page = 1});

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
