import '../../../../core/network/api_client.dart';
import '../../domain/models/local_place.dart';
import '../../domain/repositories/places_repository.dart';

class DioPlacesRepository implements PlacesRepository {
  DioPlacesRepository(this._api);

  final ApiClient _api;

  @override
  Future<NearbyPlacesResult> nearby({
    required double lat,
    required double lng,
    PlaceCategory? category,
    String? q,
    int radius = 1000,
    int limit = 20,
  }) async {
    final query = q?.trim();
    final response = await _api.get<dynamic>(
      '/places/nearby',
      queryParameters: {
        'lat': lat,
        'lng': lng,
        if (query != null && query.isNotEmpty) 'q': query,
        if ((query == null || query.isEmpty) && category != null)
          'category': category.code,
        'radius': radius,
        'limit': limit,
      },
    );
    final data = response.data;
    if (data is! Map) return const NearbyPlacesResult(items: []);
    return nearbyPlacesFromJson(Map<String, dynamic>.from(data));
  }
}
