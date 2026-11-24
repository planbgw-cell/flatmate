import '../../domain/models/local_place.dart';
import '../../domain/repositories/places_repository.dart';

class MockPlacesRepository implements PlacesRepository {
  @override
  Future<NearbyPlacesResult> nearby({
    required double lat,
    required double lng,
    required PlaceCategory category,
    int radius = 1000,
    int limit = 20,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return NearbyPlacesResult(
      items: [
        LocalPlace(
          placeId: 'mock-${category.code}-1',
          category: category,
          subCategory: category.shortLabel,
          name: '모의 ${category.label}',
          address: '서울 중구 세종대로 110',
          phone: '02-1234-5678',
          lat: lat + 0.001,
          lng: lng + 0.001,
          distanceM: 120,
          placeUrl: 'http://place.map.kakao.com/21301719',
        ),
      ],
    );
  }
}
