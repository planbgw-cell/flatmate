import 'dart:math' as math;

/// Neighborhood / dong location used for feed geo filtering.
class LocationItem {
  const LocationItem({
    required this.id,
    required this.cityName,
    required this.districtName,
    required this.dongName,
    required this.latitude,
    required this.longitude,
    this.serverFullName,
    this.regionCode,
  });

  final String id;
  final String cityName;
  final String districtName;
  final String dongName;
  final double latitude;
  final double longitude;

  /// Server display name (`full_name`, e.g. "성남시 분당구 정자동"). Preferred
  /// over composing sido/sigungu, whose split differs between data sources.
  final String? serverFullName;

  /// 행정동 코드 (`region_code`) when resolved via reverse-geo.
  final String? regionCode;

  String get displayName => dongName;

  String get fullName {
    final server = serverFullName;
    if (server != null && server.isNotEmpty) return server;
    return [cityName, districtName, dongName]
        .where((part) => part.isNotEmpty)
        .join(' ');
  }

  /// Haversine distance in kilometers.
  double distanceKmTo(LocationItem other) {
    return distanceKmBetween(
      latitude,
      longitude,
      other.latitude,
      other.longitude,
    );
  }

  double distanceKmToCoords(double lat, double lng) {
    return distanceKmBetween(latitude, longitude, lat, lng);
  }

  static double distanceKmBetween(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRad(double deg) => deg * math.pi / 180;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LocationItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Default hub — 서울 서대문구 신촌동.
const kDefaultLocation = LocationItem(
  id: 'loc-sinchon',
  cityName: '서울',
  districtName: '서대문구',
  dongName: '신촌동',
  latitude: 37.5595,
  longitude: 126.9436,
);

/// Mock catalog for search / GPS nearest matching.
List<LocationItem> buildMockLocations() {
  return const [
    kDefaultLocation,
    LocationItem(
      id: 'loc-changcheon',
      cityName: '서울',
      districtName: '서대문구',
      dongName: '창천동',
      latitude: 37.5582,
      longitude: 126.9371,
    ),
    LocationItem(
      id: 'loc-daeheon',
      cityName: '서울',
      districtName: '서대문구',
      dongName: '대현동',
      latitude: 37.5588,
      longitude: 126.9458,
    ),
    LocationItem(
      id: 'loc-seogyo',
      cityName: '서울',
      districtName: '마포구',
      dongName: '서교동',
      latitude: 37.5551,
      longitude: 126.9229,
    ),
    LocationItem(
      id: 'loc-yeonnam',
      cityName: '서울',
      districtName: '마포구',
      dongName: '연남동',
      latitude: 37.5662,
      longitude: 126.9254,
    ),
    LocationItem(
      id: 'loc-hapjeong',
      cityName: '서울',
      districtName: '마포구',
      dongName: '합정동',
      latitude: 37.5495,
      longitude: 126.9139,
    ),
    LocationItem(
      id: 'loc-gongdeok',
      cityName: '서울',
      districtName: '마포구',
      dongName: '공덕동',
      latitude: 37.5444,
      longitude: 126.9511,
    ),
    LocationItem(
      id: 'loc-yeonhui',
      cityName: '서울',
      districtName: '서대문구',
      dongName: '연희동',
      latitude: 37.5684,
      longitude: 126.9301,
    ),
    LocationItem(
      id: 'loc-hwayang',
      cityName: '서울',
      districtName: '광진구',
      dongName: '화양동',
      latitude: 37.5412,
      longitude: 127.0695,
    ),
    LocationItem(
      id: 'loc-cheongnyong',
      cityName: '서울',
      districtName: '관악구',
      dongName: '청룡동',
      latitude: 37.4812,
      longitude: 126.9527,
    ),
    LocationItem(
      id: 'loc-bongcheon',
      cityName: '서울',
      districtName: '관악구',
      dongName: '봉천동',
      latitude: 37.4823,
      longitude: 126.9418,
    ),
    LocationItem(
      id: 'loc-jeongja',
      cityName: '성남시',
      districtName: '분당구',
      dongName: '정자동',
      latitude: 37.3656,
      longitude: 127.1083,
    ),
    LocationItem(
      id: 'loc-pangyo',
      cityName: '성남시',
      districtName: '분당구',
      dongName: '판교동',
      latitude: 37.3947,
      longitude: 127.1112,
    ),
    LocationItem(
      id: 'loc-sampyeong',
      cityName: '성남시',
      districtName: '분당구',
      dongName: '삼평동',
      latitude: 37.3995,
      longitude: 127.1089,
    ),
  ];
}

/// Resolve neighborhood label → coords for feed geo filter.
LocationItem? locationForNeighborhood(String neighborhood) {
  final catalog = buildMockLocations();
  for (final loc in catalog) {
    if (loc.dongName == neighborhood) return loc;
  }
  return null;
}
