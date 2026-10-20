import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/features/auth/domain/models/auth_user.dart';
import 'package:flatmate_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:flatmate_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flatmate_app/features/location/domain/models/location_item.dart';
import 'package:flatmate_app/features/location/presentation/providers/location_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const _jeongja = LocationItem(
  id: '12',
  cityName: '경기도',
  districtName: '성남시 분당구',
  dongName: '정자동',
  latitude: 37.3656,
  longitude: 127.1083,
  serverFullName: '성남시 분당구 정자동',
);

const _cheongnyong = LocationItem(
  id: '10',
  cityName: '서울특별시',
  districtName: '관악구',
  dongName: '청룡동',
  latitude: 37.4812,
  longitude: 126.9527,
  serverFullName: '관악구 청룡동',
);

/// Server-like fake: keeps the 대표 동네 per account.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.catalog);

  final Map<int, LocationItem> catalog;
  LocationItem? primary;
  int? signupLocationId;
  final updates = <int>[];

  AuthUser get _user => AuthUser(
        id: '7',
        email: 'qa@example.com',
        nickname: 'QA',
        primaryLocation: primary,
      );

  @override
  Future<AuthUser> signup({
    required String email,
    required String password,
    required String nickname,
    int? locationId,
  }) async {
    signupLocationId = locationId;
    primary = locationId == null ? null : catalog[locationId];
    return _user;
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    return AuthSession(
      accessToken: 'jwt',
      refreshToken: 'refresh',
      expiresIn: const Duration(hours: 1),
      refreshExpiresIn: const Duration(days: 14),
      user: _user,
    );
  }

  @override
  Future<AuthUser> getMe() async => _user;

  @override
  Future<AuthUser> updateLocation(int locationId) async {
    updates.add(locationId);
    primary = catalog[locationId];
    return _user;
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeAuthRepository repo;
  late TokenStorage tokens;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    repo = _FakeAuthRepository({12: _jeongja, 10: _cheongnyong});
    tokens = TokenStorage();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokens),
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    // Same keep-alive as FlatmateApp.
    container.listen(primaryLocationSyncProvider, (_, _) {});
    return container;
  }

  test('signup sends location_id and binds the 대표 동네 to the feed',
      () async {
    final container = makeContainer();
    await container.read(authProvider.future);
    expect(container.read(currentLocationProvider).id, kDefaultLocation.id);

    await container.read(authProvider.notifier).signup(
          email: 'qa@example.com',
          password: 'Flatmate123!',
          nickname: 'QA',
          location: _jeongja,
        );

    expect(repo.signupLocationId, 12);
    expect(container.read(currentLocationProvider).fullName, '성남시 분당구 정자동');
    expect(container.read(myLocationsProvider).first.id, '12');
    expect(repo.updates, isEmpty, reason: 'binding must not echo a PATCH');
  });

  test('login binds primary_location immediately', () async {
    repo.primary = _jeongja;
    final container = makeContainer();
    await container.read(authProvider.future);

    await container
        .read(authProvider.notifier)
        .login(email: 'qa@example.com', password: 'Flatmate123!');

    expect(container.read(currentLocationProvider).id, '12');
    expect(repo.updates, isEmpty);
  });

  test('app-bar dong change → PATCH /auth/location; restart restores it',
      () async {
    repo.primary = _jeongja;
    final container = makeContainer();
    await container
        .read(authProvider.notifier)
        .login(email: 'qa@example.com', password: 'Flatmate123!');

    container.read(myLocationsProvider.notifier).select(_cheongnyong);
    await _settle();
    expect(repo.updates, [10]);
    expect(container.read(authProvider).value?.primaryLocation?.id, '10');

    // Local-only dong (no server id) is never synced.
    container.read(myLocationsProvider.notifier).select(kDefaultLocation);
    await _settle();
    expect(repo.updates, [10]);

    // "Restart": fresh container, stored session → getMe → 청룡동.
    final restarted = makeContainer();
    await restarted.read(authProvider.future);
    await _settle();
    expect(restarted.read(currentLocationProvider).fullName, '관악구 청룡동');
  });

  test('signed-out dong changes are not synced', () async {
    final container = makeContainer();
    await container.read(authProvider.future);
    container.read(myLocationsProvider.notifier).select(_cheongnyong);
    await _settle();
    expect(repo.updates, isEmpty);
  });
}
