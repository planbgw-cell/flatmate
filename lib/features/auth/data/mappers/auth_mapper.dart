import '../../domain/models/auth_user.dart';

AuthUser authUserFromJson(Map<String, dynamic> json) {
  return AuthUser(
    id: json['id']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    nickname: json['nickname']?.toString() ?? '',
    profileImage: json['profile_image']?.toString(),
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
  );
}

AuthSession authSessionFromJson(Map<String, dynamic> json) {
  final user = json['user'];
  final refreshSeconds = (json['refresh_expires_in'] as num?)?.toInt();
  return AuthSession(
    accessToken: json['access_token']?.toString() ?? '',
    expiresIn: Duration(
      seconds: (json['expires_in'] as num?)?.toInt() ?? 3600,
    ),
    refreshToken: json['refresh_token']?.toString(),
    refreshExpiresIn:
        refreshSeconds == null ? null : Duration(seconds: refreshSeconds),
    user: authUserFromJson(
      user is Map ? Map<String, dynamic>.from(user) : const {},
    ),
  );
}
