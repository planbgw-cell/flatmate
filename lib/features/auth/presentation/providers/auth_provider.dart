import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/token_storage.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return sl<TokenStorage>();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return sl<AuthRepository>();
});

/// Signed-in user (`null` = signed out). JWT lives in [TokenStorage].
class AuthNotifier extends AsyncNotifier<AuthUser?> {
  TokenStorage get _tokens => ref.read(tokenStorageProvider);
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AuthUser?> build() async {
    final tokens = _tokens;
    void onSessionChanged() {
      if (!tokens.hasValidToken && state.value != null) {
        state = const AsyncData(null);
      }
    }

    tokens.addListener(onSessionChanged);
    ref.onDispose(() => tokens.removeListener(onSessionChanged));

    if (!tokens.hasValidToken) return null;
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

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final session = await _repo.login(email: email.trim(), password: password);
    await _tokens.save(
      accessToken: session.accessToken,
      userId: session.user.id,
      expiresIn: session.expiresIn,
    );
    state = AsyncData(session.user);
    return session.user;
  }

  /// Registers then signs in with the same credentials.
  Future<AuthUser> signup({
    required String email,
    required String password,
    required String nickname,
  }) async {
    await _repo.signup(
      email: email.trim(),
      password: password,
      nickname: nickname.trim(),
    );
    return login(email: email, password: password);
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
