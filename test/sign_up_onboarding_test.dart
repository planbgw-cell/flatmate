import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/features/auth/domain/models/auth_user.dart';
import 'package:flatmate_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:flatmate_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flatmate_app/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:flatmate_app/features/location/data/datasources/location_service.dart';
import 'package:flatmate_app/features/location/domain/models/location_item.dart';
import 'package:flatmate_app/features/location/domain/repositories/location_repository.dart';
import 'package:flatmate_app/features/location/presentation/providers/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _jeongja = LocationItem(
  id: '12',
  cityName: '경기도',
  districtName: '성남시 분당구',
  dongName: '정자동',
  latitude: 37.3656,
  longitude: 127.1083,
  serverFullName: '성남시 분당구 정자동',
);

class _FakeGps extends LocationService {
  @override
  Future<LocationFixResult> currentPosition() async =>
      const LocationFixResult.granted(37.3659, 127.1081);
}

class _FakeLocations implements LocationRepository {
  @override
  Future<LocationItem?> getReverseGeo(double lat, double lng) async => _jeongja;

  @override
  Future<List<LocationItem>> search(String query) async => const [];
}

class _RecordingAuth implements AuthRepository {
  int? signupLocationId;
  bool signedUp = false;

  AuthUser get _user => AuthUser(
        id: '7',
        email: 'qa@example.com',
        nickname: '새이웃',
        primaryLocation: signedUp ? _jeongja : null,
      );

  @override
  Future<AuthUser> signup({
    required String email,
    required String password,
    required String nickname,
    int? locationId,
  }) async {
    signupLocationId = locationId;
    signedUp = true;
    return _user;
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async =>
      AuthSession(
        accessToken: 'jwt',
        expiresIn: const Duration(hours: 1),
        user: _user,
      );

  @override
  Future<AuthUser> getMe() async => _user;

  @override
  Future<AuthUser> updateLocation(int locationId) async => _user;
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('step 1 account → step 2 GPS dong → 가입 완료 with location_id',
      (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final auth = _RecordingAuth();
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(TokenStorage()),
        authRepositoryProvider.overrideWithValue(auth),
        locationServiceProvider.overrideWithValue(_FakeGps()),
        locationRepositoryProvider.overrideWithValue(_FakeLocations()),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/signup',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('메인 피드')),
        ),
        GoRoute(
          path: '/signup',
          builder: (_, _) => const SignUpScreen(redirectTo: '/home'),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Step 1 validation blocks "다음" until the form is valid.
    expect(find.text('1/2'), findsOneWidget);
    await tester.tap(find.text('다음'));
    await tester.pump();
    expect(find.text('이메일을 입력해 주세요.'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'qa@example.com');
    await tester.enterText(fields.at(1), 'Flatmate123!');
    await tester.enterText(fields.at(2), 'Flatmate123!');
    await tester.enterText(fields.at(3), '새이웃');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    // Step 2: 가입 완료 disabled until a dong is chosen.
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('우리 동네를 설정해 주세요'), findsOneWidget);
    final complete = find.widgetWithText(FilledButton, '가입 완료');
    expect(tester.widget<FilledButton>(complete).onPressed, isNull);

    await tester.tap(find.text('현재 위치로 동네 찾기'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('signup-selected-dong'))).data,
      '성남시 분당구 정자동',
    );
    expect(tester.widget<FilledButton>(complete).onPressed, isNotNull);

    await tester.tap(complete);
    await tester.pumpAndSettle();

    expect(auth.signupLocationId, 12);
    expect(container.read(currentLocationProvider).id, '12');
    expect(find.text('메인 피드'), findsOneWidget);
  });
}
