/// Server `PlaceCategory` for `GET /places/nearby`.
enum PlaceCategory {
  food('FOOD', '음식점', '음식점'),
  cafe('CAFE', '카페/빵집', '카페'),
  mart('MART', '편의점/마트', '마트'),
  medical('MEDICAL', '병원/약국', '의료'),
  fitness('FITNESS', '운동/헬스', '운동'),
  life('LIFE', '세탁/생활', '생활'),
  car('CAR', '주유/주차', '주차');

  const PlaceCategory(this.code, this.label, this.shortLabel);
  final String code;
  final String label;
  final String shortLabel;

  static PlaceCategory fromCode(Object? code) => values.firstWhere(
        (e) => e.code == code?.toString().toUpperCase(),
        orElse: () => PlaceCategory.food,
      );
}

/// One row from `NearbyPlacesOut.items` (`LocalPlaceOut`).
class LocalPlace {
  const LocalPlace({
    required this.placeId,
    required this.category,
    required this.subCategory,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.distanceM,
    required this.placeUrl,
    this.phone,
  });

  final String placeId;
  final PlaceCategory category;
  final String subCategory;
  final String name;
  final String address;
  final String? phone;
  final double lat;
  final double lng;
  final int distanceM;
  final String placeUrl;

  String get distanceLabel {
    if (distanceM < 1000) return '${distanceM}m';
    final km = distanceM / 1000;
    return '${km.toStringAsFixed(km >= 10 ? 0 : 1)}km';
  }
}

/// Parsed `NearbyPlacesOut`.
class NearbyPlacesResult {
  const NearbyPlacesResult({required this.items, this.message});

  final List<LocalPlace> items;
  final String? message;
}

LocalPlace localPlaceFromJson(Map<String, dynamic> json) => LocalPlace(
      placeId: json['place_id']?.toString() ?? '',
      category: PlaceCategory.fromCode(json['category']),
      subCategory: json['sub_category']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: () {
        final p = json['phone']?.toString().trim();
        return p == null || p.isEmpty ? null : p;
      }(),
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      distanceM: (json['distance_m'] as num?)?.toInt() ?? 0,
      placeUrl: json['place_url']?.toString() ?? '',
    );

NearbyPlacesResult nearbyPlacesFromJson(Map<String, dynamic> json) {
  final raw = json['items'];
  final items = raw is List
      ? raw
          .whereType<Map>()
          .map((e) => localPlaceFromJson(Map<String, dynamic>.from(e)))
          .toList()
      : const <LocalPlace>[];
  final message = json['message']?.toString().trim();
  return NearbyPlacesResult(
    items: items,
    message: message == null || message.isEmpty ? null : message,
  );
}
