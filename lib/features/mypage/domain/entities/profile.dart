class Profile {
  const Profile({
    required this.id,
    required this.nickname,
    this.email,
  });

  final String id;
  final String nickname;
  final String? email;
}
