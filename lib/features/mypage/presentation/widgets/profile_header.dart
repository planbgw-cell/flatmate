import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.nickname,
    this.email,
  });

  final String nickname;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(nickname),
      subtitle: email == null ? null : Text(email!),
    );
  }
}
