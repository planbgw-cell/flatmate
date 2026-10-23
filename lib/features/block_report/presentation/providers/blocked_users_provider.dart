import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../../../feed/presentation/providers/feed_provider.dart';
import '../../domain/block_report_repository.dart';
import '../../domain/models/blocked_user.dart';

final blockReportRepositoryProvider = Provider<BlockReportRepository>((ref) {
  return sl<BlockReportRepository>();
});

/// 차단한 사용자 (per account; empty for guests).
class BlockedUsersNotifier extends AsyncNotifier<List<BlockedUser>> {
  BlockReportRepository get _repo => ref.read(blockReportRepositoryProvider);

  @override
  Future<List<BlockedUser>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const [];
    return _repo.getBlockedUsers();
  }

  /// Blocks the author of [item]; their posts leave the feed immediately.
  Future<BlockedUser> block(FeedItem item) async {
    final authorId = item.authorId;
    if (authorId == null) {
      throw StateError('Feed ${item.id} has no author');
    }
    final user = await _repo.blockUser(authorId);
    final current = state.value ?? const <BlockedUser>[];
    state = AsyncData([
      user,
      ...current.where((u) => u.userId != user.userId),
    ]);
    ref.read(feedListProvider.notifier).removeByAuthor(authorId);
    _refreshDependents();
    return user;
  }

  /// Optimistic: the row disappears first and comes back if the call fails.
  Future<void> unblock(String userId) async {
    final before = state.value ?? const <BlockedUser>[];
    state = AsyncData(before.where((u) => u.userId != userId).toList());
    try {
      await _repo.unblockUser(userId);
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
    _refreshDependents();
  }

  void _refreshDependents() {
    ref.invalidate(feedListProvider);
    ref.invalidate(chatRoomsProvider);
    ref.read(feedMutationTickProvider.notifier).state++;
  }
}

final blockedUsersProvider =
    AsyncNotifierProvider<BlockedUsersNotifier, List<BlockedUser>>(
  BlockedUsersNotifier.new,
);

final blockedUserIdsProvider = Provider<Set<String>>((ref) {
  final users = ref.watch(blockedUsersProvider).value ?? const [];
  return {for (final user in users) user.userId};
});

/// Waits for the block list; empty when it cannot be loaded. The server may
/// not filter blocked authors out of `GET /feeds`.
Future<Set<String>> readBlockedAuthorIds(Ref ref) async {
  try {
    final users = await ref.read(blockedUsersProvider.future);
    return {for (final user in users) user.userId};
  } catch (_) {
    return const {};
  }
}

List<FeedItem> withoutBlockedAuthors(
  List<FeedItem> items,
  Set<String> blocked,
) =>
    blocked.isEmpty
        ? items
        : items.where((e) => !blocked.contains(e.authorId)).toList();
