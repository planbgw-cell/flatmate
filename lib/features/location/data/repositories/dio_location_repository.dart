import '../../../../core/network/api_client.dart';
import '../../domain/models/location_item.dart';
import '../../domain/repositories/location_repository.dart';

/// FastAPI location repository (`/locations/...`).
class DioLocationRepository implements LocationRepository {
  DioLocationRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<LocationItem>> search(String query) async {
    final response = await _api.get<dynamic>(
      '/locations/search',
      queryParameters: {'q': query},
    );
    return _parseList(response.data);
  }

  @override
  Future<LocationItem?> reverseGeo({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _api.get<dynamic>(
      '/locations/reverse-geo',
      queryParameters: {
        'lat': latitude,
        'lng': longitude,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return locationItemFromJson(data);
    if (data is Map) {
      return locationItemFromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  List<LocationItem> _parseList(dynamic data) {
    final raw = switch (data) {
      final List list => list,
      final Map map => map['items'] ?? map['results'] ?? map['data'] ?? const [],
      _ => const [],
    };
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => locationItemFromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

LocationItem locationItemFromJson(Map<String, dynamic> json) {
  return LocationItem(
    id: json['id']?.toString() ?? '',
    cityName: json['city_name']?.toString() ??
        json['cityName']?.toString() ??
        '',
    districtName: json['district_name']?.toString() ??
        json['districtName']?.toString() ??
        '',
    dongName: json['dong_name']?.toString() ??
        json['dongName']?.toString() ??
        '',
    latitude: (json['latitude'] as num?)?.toDouble() ??
        (json['lat'] as num?)?.toDouble() ??
        0,
    longitude: (json['longitude'] as num?)?.toDouble() ??
        (json['lng'] as num?)?.toDouble() ??
        0,
  );
}
