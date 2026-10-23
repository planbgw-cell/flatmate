import '../../../../core/network/media_url.dart';

/// `BlockedUserOut` from `GET /blocks/users`.
class BlockedUser {
  const BlockedUser({
    required this.userId,
    required this.nickname,
    required this.blockedAt,
    this.profileImageUrl,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    final image = resolveMediaUrl(json['profile_image'] as String?);
    return BlockedUser(
      userId: json['user_id'].toString(),
      nickname: (json['nickname'] as String?) ?? '',
      profileImageUrl: image.isEmpty ? null : image,
      blockedAt: DateTime.tryParse(json['blocked_at']?.toString() ?? '')
              ?.toLocal() ??
          DateTime.now(),
    );
  }

  final String userId;
  final String nickname;

  /// Absolute URL (see [resolveMediaUrl]).
  final String? profileImageUrl;
  final DateTime blockedAt;
}
