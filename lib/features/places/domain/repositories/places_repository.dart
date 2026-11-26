import '../models/local_place.dart';

abstract class PlacesRepository {
  /// Nearby places by [category] and/or keyword [q].
  /// Keyword search omits [category]; category browse omits [q].
  Future<NearbyPlacesResult> nearby({
    required double lat,
    required double lng,
    PlaceCategory? category,
    String? q,
    int radius = 1000,
    int limit = 20,
  });
}
