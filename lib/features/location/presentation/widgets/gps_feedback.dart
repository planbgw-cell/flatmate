import 'package:flutter/material.dart';

import '../../data/datasources/location_service.dart';

/// Guidance when "현재 위치로 동 찾기" yields no dong.
SnackBar gpsFailureSnackBar(LocationFixStatus status, LocationService service) {
  return switch (status) {
    LocationFixStatus.denied => const SnackBar(
        content: Text('위치 권한이 필요해요. 권한을 허용하면 내 동네를 바로 찾아드려요.'),
      ),
    LocationFixStatus.deniedForever => SnackBar(
        content: const Text('위치 권한이 꺼져 있어요. 설정에서 허용해 주세요.'),
        action: SnackBarAction(
          label: '설정 열기',
          onPressed: service.openAppSettings,
        ),
      ),
    LocationFixStatus.serviceDisabled => SnackBar(
        content: const Text('기기의 위치(GPS)가 꺼져 있어요.'),
        action: SnackBarAction(
          label: '켜기',
          onPressed: service.openLocationSettings,
        ),
      ),
    LocationFixStatus.timeout => const SnackBar(
        content: Text('현재 위치를 확인하지 못했어요. 잠시 후 다시 시도해 주세요.'),
      ),
    LocationFixStatus.granted => const SnackBar(
        content: Text('현재 위치의 동네 정보를 찾지 못했어요.'),
      ),
  };
}
