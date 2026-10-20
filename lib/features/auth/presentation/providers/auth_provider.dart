import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/token_storage.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_exception.dart';
import '../../../location/data/mappers/location_mapper.dart';
import '../../../location/domain/models/location_item.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return sl<TokenStorage>();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return sl<AuthRepository>();
});

/// Signed-in user (`null` = signed out). JWT lives in [TokenStorage].
///
/// Whenever a user with a 대표 동네 arrives (login, signup, token restore on
/// app start, `PATCH /auth/location`), it becomes the current feed location.
class AuthNotifier extends AsyncNotifier<AuthUser?> {
  TokenStorage get _tokens => ref.read(tokenStorageProvider);
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AuthUser?> build() async {
    final tokens = _tokens;
    void onSessionChanged() {
      if (!tokens.hasSession && state.value != null) {
        state = const AsyncData(null);
      }
    }

    tokens.addListener(onSessionChanged);
    ref.onDispose(() => tokens.removeListener(onSessionChanged));
    listenSelf((_, next) => _bindPrimaryLocation(next.value));

    if (!tokens.hasSession) return null;
    try {
      return await _repo.getMe();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await tokens.clear();
        return null;
      }
      rethrow;
    }
  }

  void _bindPrimaryLocation(AuthUser? user) {
    final primary = user?.primaryLocation;
    if (primary == null) return;
    if (ref.read(currentLocationProvider).id == primary.id) return;
    ref.read(myLocationsProvider.notifier).bindPrimary(primary);
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final session = await _repo.login(email: email.trim(), password: password);
    await _tokens.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      userId: session.user.id,
      expiresIn: session.expiresIn,
      refreshExpiresIn: session.refreshExpiresIn,
    );
    state = AsyncData(session.user);
    return session.user;
  }

  /// Registers (with [location] as 대표 동네) then signs in.
  Future<AuthUser> signup({
    required String email,
    required String password,
    required String nickname,
    LocationItem? location,
  }) async {
    await _repo.signup(
      email: email.trim(),
      password: password,
      nickname: nickname.trim(),
      locationId: location == null ? null : serverLocationId(location),
    );
    final user = await login(email: email, password: password);
    if (location != null && user.primaryLocation == null) {
      // Mock catalog dongs have no server id; keep the choice locally.
      ref.read(myLocationsProvider.notifier).select(location);
    }
    return user;
  }

  /// Mirrors a user-picked feed dong to the server 대표 동네.
  /// Local-only dongs (no server id) and signed-out users are skipped.
  Future<void> syncPrimaryLocation(LocationItem location) async {
    final user = state.value;
    final locationId = serverLocationId(location);
    if (user == null || locationId == null) return;
    if (user.primaryLocation?.id == location.id) return;
    try {
      state = AsyncData(await _repo.updateLocation(locationId));
    } on ApiException {
      // Keep the local choice; the next change retries the sync.
    }
  }

  Future<void> logout() async {
    await _tokens.clear();
    state = const AsyncData(null);
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthUser?>(AuthNotifier.new);

/// Current user id for ownership checks (`isMine`, self-chat guard).
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).value?.id;
});

/// Pushes app-bar dong changes (search / GPS / map) to `PATCH /auth/location`.
/// Kept alive from the app root.
final primaryLocationSyncProvider = Provider<void>((ref) {
  ref.listen<LocationItem>(currentLocationProvider, (previous, next) {
    if (previous?.id == next.id) return;
    ref.read(authProvider.notifier).syncPrimaryLocation(next);
  });
});
