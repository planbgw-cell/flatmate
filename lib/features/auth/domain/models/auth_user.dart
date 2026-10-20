import '../../../location/domain/models/location_item.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.nickname,
    this.profileImage,
    this.createdAt,
    this.primaryLocation,
    this.locationVerifiedAt,
  });

  final String id;
  final String email;
  final String nickname;
  final String? profileImage;
  final DateTime? createdAt;

  /// 대표 동네 (`primary_location`); bound to the feed on login / app start.
  final LocationItem? primaryLocation;

  /// When the primary dong was last set (GPS / map / signup).
  final DateTime? locationVerifiedAt;

  AuthUser copyWith({LocationItem? primaryLocation}) {
    return AuthUser(
      id: id,
      email: email,
      nickname: nickname,
      profileImage: profileImage,
      createdAt: createdAt,
      primaryLocation: primaryLocation ?? this.primaryLocation,
      locationVerifiedAt: locationVerifiedAt,
    );
  }
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
