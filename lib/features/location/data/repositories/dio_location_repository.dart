import '../../../../core/network/api_client.dart';
import '../../domain/models/location_item.dart';
import '../../domain/repositories/location_repository.dart';
import '../mappers/location_mapper.dart';

/// FastAPI location repository (`/locations`, `/locations/reverse-geo`).
class DioLocationRepository implements LocationRepository {
  DioLocationRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<LocationItem>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final response = await _api.get<dynamic>(
      '/locations',
      queryParameters: {'q': q, 'limit': 30},
    );
    return _parseList(response.data);
  }

  /// `ReverseGeoOut` = `{location: LocationOut, source: db|kakao, …}`.
  @override
  Future<LocationItem?> getReverseGeo(double lat, double lng) async {
    final response = await _api.get<dynamic>(
      '/locations/reverse-geo',
      queryParameters: {'lat': lat, 'lng': lng},
    );
    final data = response.data;
    final location = data is Map ? data['location'] : null;
    if (location is! Map) return null;
    return locationItemFromJson(Map<String, dynamic>.from(location));
  }

  List<LocationItem> _parseList(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => locationItemFromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
