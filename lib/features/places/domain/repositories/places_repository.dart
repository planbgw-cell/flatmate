import '../models/local_place.dart';

abstract class PlacesRepository {
  Future<NearbyPlacesResult> nearby({
    required double lat,
    required double lng,
    required PlaceCategory category,
    int radius = 1000,
    int limit = 20,
  });
}
