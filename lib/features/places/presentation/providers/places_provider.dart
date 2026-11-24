import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../domain/repositories/places_repository.dart';

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  return sl<PlacesRepository>();
});
