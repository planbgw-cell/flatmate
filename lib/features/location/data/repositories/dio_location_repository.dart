import '../../../../core/network/api_client.dart';
import '../../domain/models/location_item.dart';
import '../../domain/repositories/location_repository.dart';

/// FastAPI location repository (`/locations`, `/locations/nearest`).
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

  @override
  Future<LocationItem?> reverseGeo({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _api.get<dynamic>(
      '/locations/nearest',
      queryParameters: {'lat': latitude, 'lng': longitude, 'limit': 1},
    );
    final list = _parseList(response.data);
    return list.isEmpty ? null : list.first;
  }

  List<LocationItem> _parseList(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => locationItemFromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

/// `LocationOut` → [LocationItem].
LocationItem locationItemFromJson(Map<String, dynamic> json) {
  final name = json['name']?.toString() ?? '';
  return LocationItem(
    id: json['id']?.toString() ?? '',
    cityName: json['sido']?.toString() ?? '',
    districtName: json['sigungu']?.toString() ?? '',
    dongName: json['dong']?.toString() ?? name,
    latitude: (json['lat'] as num?)?.toDouble() ?? 0,
    longitude: (json['lng'] as num?)?.toDouble() ?? 0,
  );
}
