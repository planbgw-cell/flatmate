import 'package:flatmate_app/features/location/domain/models/location_item.dart';
import 'package:flatmate_app/features/location/domain/repositories/location_repository.dart';
import 'package:flatmate_app/features/location/presentation/providers/location_provider.dart';
import 'package:flatmate_app/features/location/presentation/screens/location_map_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// North of the start point resolves to a different dong.
class _FakeLocationRepository implements LocationRepository {
  final calls = <(double, double)>[];

  @override
  Future<LocationItem?> getReverseGeo(double lat, double lng) async {
    calls.add((lat, lng));
    final north = lat > kDefaultLocation.latitude + 0.002;
    return LocationItem(
      id: north ? '201' : '200',
      cityName: '서울',
      districtName: '서대문구',
      dongName: north ? '연희동' : '신촌동',
      latitude: lat,
      longitude: lng,
      serverFullName: north ? '서울특별시 서대문구 연희동' : '서울특별시 서대문구 신촌동',
    );
  }

  @override
  Future<List<LocationItem>> search(String query) async => const [];
}

void main() {
  late _FakeLocationRepository repo;
  late GoRouter router;
  late ProviderContainer container;

  Future<void> pumpPicker(WidgetTester tester) async {
    repo = _FakeLocationRepository();
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('메인 피드')),
        ),
        GoRoute(
          path: '/picker',
          builder: (_, _) => const LocationMapPickerScreen(
            showTiles: false,
            idleDebounce: Duration(milliseconds: 50),
          ),
        ),
      ],
    );
    container = ProviderContainer(
      overrides: [locationRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/picker');
    await tester.pumpAndSettle();
  }

  testWidgets('center pin + card resolve the initial map center',
      (tester) async {
    await pumpPicker(tester);

    expect(find.text('내 동네 위치 선택'), findsOneWidget);
    expect(find.byKey(const ValueKey('map-picker-pin')), findsOneWidget);
    expect(find.text('현재 선택된 동'), findsOneWidget);
    expect(find.text('서울특별시 서대문구 신촌동'), findsOneWidget);
    expect(repo.calls.single.$1, closeTo(kDefaultLocation.latitude, 1e-6));
  });

  testWidgets('dragging the map re-resolves the center after idle; '
      'CTA stores the dong and pops', (tester) async {
    await pumpPicker(tester);
    final callsBefore = repo.calls.length;

    // Drag content down → camera center moves north.
    await tester.drag(find.byType(FlutterMap), const Offset(0, 300));
    await tester.pump();
    expect(find.text('위치 확인 중…'), findsOneWidget);
    final cta = find.widgetWithText(FilledButton, '이 위치로 동 설정하기');
    expect(tester.widget<FilledButton>(cta).onPressed, isNull);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(repo.calls.length, greaterThan(callsBefore));
    expect(repo.calls.last.$1, greaterThan(kDefaultLocation.latitude));
    expect(find.text('서울특별시 서대문구 연희동'), findsOneWidget);
    expect(tester.widget<FilledButton>(cta).onPressed, isNotNull);

    await tester.tap(cta);
    await tester.pumpAndSettle();

    final current = container.read(currentLocationProvider);
    expect(current.dongName, '연희동');
    expect(current.fullName, '서울특별시 서대문구 연희동');
    expect(container.read(myLocationsProvider).map((e) => e.dongName),
        contains('연희동'));
    expect(find.text('메인 피드'), findsOneWidget);
  });
}
