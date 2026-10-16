import '../../domain/models/location_item.dart';
import '../../domain/repositories/location_repository.dart';

class MockLocationRepository implements LocationRepository {
  @override
  Future<List<LocationItem>> search(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return buildMockLocations()
        .where(
          (loc) =>
              loc.dongName.toLowerCase().contains(q) ||
              loc.districtName.toLowerCase().contains(q) ||
              loc.cityName.toLowerCase().contains(q) ||
              loc.fullName.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Future<LocationItem?> reverseGeo({
    required double latitude,
    required double longitude,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final catalog = buildMockLocations();
    LocationItem nearest = catalog.first;
    var best = double.infinity;
    for (final loc in catalog) {
      final d = loc.distanceKmToCoords(latitude, longitude);
      if (d < best) {
        best = d;
        nearest = loc;
      }
    }
    return nearest;
  }
}
