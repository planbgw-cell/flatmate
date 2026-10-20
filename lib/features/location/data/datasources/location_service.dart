import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum LocationFixStatus { granted, denied, deniedForever, serviceDisabled, timeout }

/// Outcome of a GPS request; coordinates are set only when [isGranted].
class LocationFixResult {
  const LocationFixResult._(this.status, [this.latitude, this.longitude]);

  const LocationFixResult.granted(double latitude, double longitude)
      : this._(LocationFixStatus.granted, latitude, longitude);

  const LocationFixResult.failed(LocationFixStatus status) : this._(status);

  final LocationFixStatus status;
  final double? latitude;
  final double? longitude;

  bool get isGranted => status == LocationFixStatus.granted;
}

/// Device GPS via geolocator (permission prompt → current fix).
class LocationService {
  static const _fixTimeout = Duration(seconds: 10);
  static const _cachedFixMaxAge = Duration(minutes: 5);

  Future<LocationFixResult> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationFixResult.failed(LocationFixStatus.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    switch (permission) {
      case LocationPermission.denied:
        return const LocationFixResult.failed(LocationFixStatus.denied);
      case LocationPermission.deniedForever:
        return const LocationFixResult.failed(LocationFixStatus.deniedForever);
      case LocationPermission.whileInUse:
      case LocationPermission.always:
      case LocationPermission.unableToDetermine:
        break;
    }

    // Dong-level lookup: a recent cached fix is accurate enough and instant.
    final cached = await Geolocator.getLastKnownPosition();
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _cachedFixMaxAge) {
      return LocationFixResult.granted(cached.latitude, cached.longitude);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          // Network-assisted fix: seconds indoors vs. minutes for GPS-high.
          accuracy: LocationAccuracy.medium,
          timeLimit: _fixTimeout,
        ),
      );
      return LocationFixResult.granted(position.latitude, position.longitude);
    } on TimeoutException {
      // Indoors a fresh fix can take long; the last known one is good enough
      // to resolve a dong.
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) {
        return const LocationFixResult.failed(LocationFixStatus.timeout);
      }
      return LocationFixResult.granted(last.latitude, last.longitude);
    }
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
