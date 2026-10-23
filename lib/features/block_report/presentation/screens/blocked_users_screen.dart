import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/blocked_user.dart';
import '../providers/blocked_users_provider.dart';

/// 마이페이지 → 차단 사용자 관리 (`GET /blocks/users`, 차단 해제).
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  Future<void> _unblock(
    BuildContext context,
    WidgetRef ref,
    BlockedUser user,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(blockedUsersProvider.notifier).unblock(user.userId);
      messenger.showSnackBar(
        SnackBar(content: Text('${user.nickname}님의 차단을 해제했어요.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e is ApiException ? e.message : '차단을 해제하지 못했어요.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(blockedUsersProvider);
    final users = usersAsync.value;

    final Widget body;
    if (users == null) {
      body = usersAsync.hasError
          ? Center(
              child: Text(
                usersAsync.error is ApiException
                    ? (usersAsync.error as ApiException).message
                    : '목록을 불러오지 못했어요.',
                style: AppTypography.bodyMedium,
              ),
            )
          : const Center(child: CircularProgressIndicator());
    } else {
      body = RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.refresh(blockedUsersProvider.future),
        child: users.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  Text(
                    '차단한 사용자가 없어요.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium,
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: users.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) => _BlockedUserTile(
                  user: users[index],
                  onUnblock: () => _unblock(context, ref, users[index]),
                ),
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('차단 사용자 관리')),
      body: body,
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  const _BlockedUserTile({required this.user, required this.onUnblock});

  final BlockedUser user;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final avatar = user.profileImageUrl;
    final at = user.blockedAt;
    return ListTile(
      key: ValueKey('blocked-user-${user.userId}'),
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryContainer,
        backgroundImage:
            avatar == null ? null : CachedNetworkImageProvider(avatar),
        child: avatar == null
            ? const Icon(Icons.person, color: AppColors.primary)
            : null,
      ),
      title: Text(user.nickname, style: AppTypography.titleMedium),
      subtitle: Text(
        '${at.year}.${at.month}.${at.day} 차단',
        style: AppTypography.caption,
      ),
      trailing: OutlinedButton(
        key: ValueKey('unblock-${user.userId}'),
        onPressed: onUnblock,
        child: const Text('차단 해제'),
      ),
    );
  }
}
