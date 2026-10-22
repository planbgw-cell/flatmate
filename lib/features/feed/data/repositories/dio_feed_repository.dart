import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../location/domain/models/location_item.dart';
import '../../domain/models/feed_item.dart';
import '../../domain/repositories/feed_repository.dart';
import '../mappers/feed_item_mapper.dart';

/// FastAPI feed repository (`/feeds`, `/users/me/{feeds,likes}`).
class DioFeedRepository implements FeedRepository {
  DioFeedRepository(this._api);

  final ApiClient _api;

  static const _myListLimit = 50;

  /// Last known server copy per id.
  final Map<String, FeedItem> _cache = {};

  @override
  Future<List<FeedItem>> fetchFeeds({
    required int page,
    int pageSize = 10,
    String category = 'all',
    LocationItem? location,
    double radiusKm = 3,
    FeedSort sort = FeedSort.latest,
  }) async {
    final feedType = feedTypeForCategoryKey(category);
    final response = await _api.get<dynamic>(
      '/feeds',
      queryParameters: {
        'page': page,
        'limit': pageSize,
        'feed_type': ?feedType,
        if (location != null) 'lat': location.latitude,
        if (location != null) 'lng': location.longitude,
        if (location != null) 'radius_m': (radiusKm * 1000).round(),
        // The server rejects `distance` without coordinates.
        'sort': location == null ? FeedSort.latest.name : sort.name,
      },
    );
    return _parseList(response.data);
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
    // Server ids are integers; legacy/mock ids (e.g. `f-101`) cannot exist.
    if (int.tryParse(id) == null) return null;
    try {
      final response = await _api.get<dynamic>('/feeds/$id');
      return _remember(_asMap(response.data));
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Both verbs are idempotent and answer `LikeOut{is_liked, like_count}`.
  @override
  Future<LikeResult> toggleLike(
    String id, {
    required bool currentlyLiked,
  }) async {
    final path = '/feeds/$id/like';
    final response = currentlyLiked
        ? await _api.delete<dynamic>(path)
        : await _api.post<dynamic>(path);
    final data = _asMap(response.data);
    return (
      isLiked: data['is_liked'] as bool? ?? !currentlyLiked,
      likeCount: (data['like_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<FeedItem> updateFeed(
    String id, {
    required String title,
    required String content,
    required Map<String, dynamic> extraMeta,
    required List<String> imageUrls,
  }) async {
    final response = await _api.patch<dynamic>(
      '/feeds/$id',
      data: feedUpdateToJson(
        title: title,
        content: content,
        extraMeta: extraMeta,
        imageUrls: imageUrls,
      ),
    );
    return _remember(_asMap(response.data));
  }

  @override
  Future<FeedItem> updateTradeStatus(String id, TradeStatus status) async {
    final response = await _api.patch<dynamic>(
      '/feeds/$id/status',
      data: {'trade_status': status.code},
    );
    return _remember(_asMap(response.data));
  }

  @override
  Future<void> deleteFeed(String id) async {
    await _api.delete<dynamic>('/feeds/$id');
  }

  @override
  Future<List<FeedItem>> getMyFeeds({TradeStatus? status, int page = 1}) async {
    final response = await _api.get<dynamic>(
      '/users/me/feeds',
      queryParameters: {
        'trade_status': ?status?.code,
        'page': page,
        'limit': _myListLimit,
      },
    );
    return _parseList(response.data);
  }

  @override
  Future<List<FeedItem>> getMyLikes({int page = 1}) async {
    final response = await _api.get<dynamic>(
      '/users/me/likes',
      queryParameters: {'page': page, 'limit': _myListLimit},
    );
    return _parseList(response.data);
  }

  @override
  Future<FeedItem> createPost(FeedItem item, {LocationItem? location}) async {
    final response = await _api.post<dynamic>(
      '/feeds',
      data: feedCreateToJson(item, location: location),
    );
    return _remember(_asMap(response.data));
  }

  FeedItem _remember(Map<String, dynamic> json) {
    final item = feedItemFromJson(json);
    _cache[item.id] = item;
    return item;
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException(message: '게시글 응답 형식이 올바르지 않습니다.');
  }

  List<FeedItem> _parseList(dynamic data) {
    final raw = switch (data) {
      final List list => list,
      final Map map => map['items'] ?? const [],
      _ => const [],
    };
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => _remember(Map<String, dynamic>.from(e)))
        .toList();
  }
}
