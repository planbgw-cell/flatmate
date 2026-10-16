import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../location/domain/models/location_item.dart';
import '../../domain/models/feed_item.dart';
import '../../domain/repositories/feed_repository.dart';
import '../mappers/feed_item_mapper.dart';

/// FastAPI feed repository (`/feeds`).
class DioFeedRepository implements FeedRepository {
  DioFeedRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<FeedItem>> fetchFeeds({
    required int page,
    int pageSize = 10,
    String category = 'all',
    LocationItem? location,
    double radiusKm = 3,
  }) async {
    final response = await _api.get<dynamic>(
      '/feeds',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        'category': category,
        'radius': radiusKm,
        if (location != null) 'lat': location.latitude,
        if (location != null) 'lng': location.longitude,
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
    try {
      final response = await _api.get<dynamic>('/feeds/$id');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return feedItemFromJson(data);
      }
      if (data is Map) {
        return feedItemFromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<FeedItem> toggleFavorite(String id) async {
    final response = await _api.post<dynamic>('/feeds/$id/favorite');
    final data = response.data;
    if (data is Map<String, dynamic>) return feedItemFromJson(data);
    if (data is Map) return feedItemFromJson(Map<String, dynamic>.from(data));
    throw const ApiException(message: '좋아요 응답 형식이 올바르지 않습니다.');
  }

  @override
  Future<FeedItem> createPost(FeedItem item) async {
    // Prefer JSON; Multipart can be added when local file picks are available.
    final response = await _api.post<dynamic>(
      '/feeds',
      data: feedItemToJson(item),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return feedItemFromJson(data);
    if (data is Map) return feedItemFromJson(Map<String, dynamic>.from(data));
    throw const ApiException(message: '게시글 등록 응답 형식이 올바르지 않습니다.');
  }

  List<FeedItem> _parseList(dynamic data) {
    final raw = switch (data) {
      final List list => list,
      final Map map => map['items'] ?? map['results'] ?? map['data'] ?? const [],
      _ => const [],
    };
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => feedItemFromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
