import '../models/location_item.dart';

abstract class LocationRepository {
  Future<List<LocationItem>> search(String query);

  Future<LocationItem?> reverseGeo({
    required double latitude,
    required double longitude,
  });
}
