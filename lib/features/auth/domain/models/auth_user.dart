class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.nickname,
    this.profileImage,
    this.createdAt,
  });

  final String id;
  final String email;
  final String nickname;
  final String? profileImage;
  final DateTime? createdAt;
}

/// Result of a successful login (`POST /auth/login`).
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.expiresIn,
    required this.user,
    this.refreshToken,
    this.refreshExpiresIn,
  });

  final String accessToken;
  final Duration expiresIn;
  final AuthUser user;

  /// Long-lived token for `POST /auth/refresh` (14 days on the dev server).
  final String? refreshToken;
  final Duration? refreshExpiresIn;
}
