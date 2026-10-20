import '../models/location_item.dart';

abstract class LocationRepository {
  Future<List<LocationItem>> search(String query);

  /// GPS / map-center coordinate → administrative dong.
  Future<LocationItem?> getReverseGeo(double lat, double lng);
}
