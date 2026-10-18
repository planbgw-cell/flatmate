import '../models/auth_user.dart';

/// Auth API contract (`/auth/signup`, `/auth/login`, `/auth/me`).
abstract class AuthRepository {
  Future<AuthUser> signup({
    required String email,
    required String password,
    required String nickname,
  });

  Future<AuthSession> login({
    required String email,
    required String password,
  });

  /// Current user for the stored JWT.
  Future<AuthUser> getMe();
}
