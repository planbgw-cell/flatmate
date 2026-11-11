import '../../../location/domain/models/location_item.dart';
import '../models/feed_item.dart';

/// Feed ordering (`GET /feeds?sort=`). `distance` needs a location.
enum FeedSort {
  latest('최신순'),
  distance('가까운순');

  const FeedSort(this.label);
  final String label;
}

/// How far public-data (축제) 동네소식 reach from a dong (`public_scope`):
/// same 시·군·구, 시·도, or 권역 (e.g. 수도권 = 서울·인천·경기).
enum PublicScope { sigungu, sido, zone }

/// Server like state after a toggle (`LikeOut`).
typedef LikeResult = ({bool isLiked, int likeCount});

/// Feed API contract (`DioFeedRepository` / `MockFeedRepository`).
abstract class FeedRepository {
  /// Paginated feed with category + geo filter (`GET /feeds`).
  Future<List<FeedItem>> fetchFeeds({
    required int page,
    int pageSize = 10,
    String category = 'all',
    LocationItem? location,
    double radiusKm = 3,
    FeedSort sort = FeedSort.latest,
  });

  /// 동네소식 by server dong (`GET /feeds?feed_type=LOCAL_NEWS&location_id=`):
  /// posts of that dong plus public-data posts within [scope]. No lat/lng —
  /// the server ignores `public_scope` when coordinates are sent.
  Future<List<FeedItem>> fetchLocalNews({
    required int locationId,
    PublicScope scope = PublicScope.sigungu,
    int page = 1,
    int pageSize = 20,
  });

  /// Single post detail by id.
  Future<FeedItem?> fetchById(String id);

  /// 관심 추가/해제 (`POST` / `DELETE /feeds/{id}/like`).
  Future<LikeResult> toggleLike(String id, {required bool currentlyLiked});

  /// `GET /feeds?q=`: title or body contains [query] (case-insensitive),
  /// newest first within [radiusKm] of [location].
  Future<List<FeedItem>> searchFeeds({
    required String query,
    int page = 1,
    int pageSize = 20,
    LocationItem? location,
    double radiusKm = 3,
  });

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
}
