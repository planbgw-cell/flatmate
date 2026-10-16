import 'package:geolocator/geolocator.dart';

class LocationFix {
  const LocationFix({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// GPS 위치 조회 래퍼. 권한 거부 시 null을 반환합니다.
class LocationService {
  Future<LocationFix?> currentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition();
    return LocationFix(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
