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

  /// Last known server copy per id (detail/favorite fallbacks).
  final Map<String, FeedItem> _cache = {};

  /// Favorites are device-local until the server exposes a favorite API.
  final Set<String> _favorites = {};

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

  @override
  Future<FeedItem> toggleFavorite(String id) async {
    final item = _cache[id] ?? await fetchById(id);
    if (item == null) {
      throw const ApiException(message: '게시글을 찾을 수 없습니다.', statusCode: 404);
    }
    final nowFavorite = !_favorites.contains(id);
    nowFavorite ? _favorites.add(id) : _favorites.remove(id);
    final updated = item.copyWith(
      isFavorite: nowFavorite,
      likeCount: (item.likeCount + (nowFavorite ? 1 : -1)).clamp(0, 1 << 31),
    );
    _cache[id] = updated;
    return updated;
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
    final parsed = feedItemFromJson(json);
    final item = _favorites.contains(parsed.id)
        ? parsed.copyWith(isFavorite: true, likeCount: parsed.likeCount + 1)
        : parsed;
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
