import '../../domain/models/location_item.dart';

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
    serverFullName: json['full_name']?.toString(),
    regionCode: json['region_code']?.toString(),
  );
}

/// Server `locations.id`; `null` for local catalog entries (e.g. `loc-sinchon`).
int? serverLocationId(LocationItem location) => int.tryParse(location.id);
