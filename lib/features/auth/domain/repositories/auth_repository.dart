import '../models/auth_user.dart';

/// Auth API contract (`/auth/signup`, `/auth/login`, `/auth/me`,
/// `/auth/location`).
abstract class AuthRepository {
  /// [locationId] becomes the user's 대표 동네 (`locations.id`).
  Future<AuthUser> signup({
    required String email,
    required String password,
    required String nickname,
    int? locationId,
  });

  Future<AuthSession> login({
    required String email,
    required String password,
  });

  /// Current user for the stored JWT (includes `primary_location`).
  Future<AuthUser> getMe();

  /// `PATCH /auth/location` — change the 대표 동네.
  Future<AuthUser> updateLocation(int locationId);
}
