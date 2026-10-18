import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/location_service.dart';
import '../../domain/models/location_item.dart';
import '../../domain/repositories/location_repository.dart';

/// Discrete radius steps used by the Daangn-style slider (km).
const kLocationRadiusSteps = <double>[1, 3, 5, 10];

String radiusLabel(double km) {
  return switch (km) {
    1 => '1km · 모두',
    3 => '3km · 가까운 동네',
    5 => '5km',
    10 => '10km · 먼 동네',
    _ => '${km.toStringAsFixed(0)}km',
  };
}

/// Currently selected neighborhood.
final currentLocationProvider = StateProvider<LocationItem>((ref) {
  return kDefaultLocation;
});

/// Search radius in kilometers (1 / 3 / 5 / 10).
final locationRadiusProvider = StateProvider<double>((ref) {
  return 3;
});

/// Saved "내 동네" slots (max 2), Daangn-style.
class MyLocationsNotifier extends Notifier<List<LocationItem>> {
  static const maxSlots = 2;

  @override
  List<LocationItem> build() {
    return const [kDefaultLocation];
  }

  void select(LocationItem location) {
    final next = [...state];
    final index = next.indexWhere((e) => e.id == location.id);
    if (index >= 0) {
      ref.read(currentLocationProvider.notifier).state = next[index];
      return;
    }
    if (next.length < maxSlots) {
      next.add(location);
    } else {
      // Replace inactive slot when full.
      final current = ref.read(currentLocationProvider);
      final replaceAt = next.indexWhere((e) => e.id != current.id);
      if (replaceAt >= 0) {
        next[replaceAt] = location;
      } else {
        next[0] = location;
      }
    }
    state = next;
    ref.read(currentLocationProvider.notifier).state = location;
  }

  void setActive(LocationItem location) {
    if (!state.any((e) => e.id == location.id)) return;
    ref.read(currentLocationProvider.notifier).state = location;
  }
}

final myLocationsProvider =
    NotifierProvider<MyLocationsNotifier, List<LocationItem>>(
  MyLocationsNotifier.new,
);

final locationCatalogProvider = Provider<List<LocationItem>>((ref) {
  return buildMockLocations();
});

/// Neighborhoods within [locationRadiusProvider] of current location.
final nearbyLocationCountProvider = Provider<int>((ref) {
  final current = ref.watch(currentLocationProvider);
  final radius = ref.watch(locationRadiusProvider);
  final catalog = ref.watch(locationCatalogProvider);
  return catalog
      .where((loc) => current.distanceKmTo(loc) <= radius)
      .length;
});

final locationSearchQueryProvider = StateProvider<String>((ref) => '');

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return sl<LocationRepository>();
});

/// Dong search via [LocationRepository] (Mock catalog or `GET /locations?q=`).
final locationSearchResultsProvider =
    FutureProvider<List<LocationItem>>((ref) async {
  final query = ref.watch(locationSearchQueryProvider).trim();
  if (query.isEmpty) return const [];
  // Debounce keystrokes; a newer query disposes this one.
  await Future<void>.delayed(const Duration(milliseconds: 250));
  return ref.read(locationRepositoryProvider).search(query);
});

/// Nearest dong for device GPS (falls back to 신촌동).
Future<LocationItem> resolveLocationFromGps() async {
  final fix = await sl<LocationService>().currentPosition();
  if (fix == null) return kDefaultLocation;
  final nearest = await sl<LocationRepository>().reverseGeo(
    latitude: fix.latitude,
    longitude: fix.longitude,
  );
  return nearest ?? kDefaultLocation;
}
