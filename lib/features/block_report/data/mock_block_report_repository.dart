import '../../../core/network/api_exception.dart';
import '../domain/block_report_repository.dart';
import '../domain/models/blocked_user.dart';
import '../domain/models/report_reason.dart';

/// In-memory stand-in for offline / mock runs.
class MockBlockReportRepository implements BlockReportRepository {
  final Set<String> _reported = {};
  final List<BlockedUser> _blocked = [];

  @override
  Future<void> reportFeed(
    String feedId,
    ReportReason reason, {
    String? details,
  }) async {
    if (!_reported.add(feedId)) {
      throw const ApiException(
        message: '이미 신고한 게시글입니다.',
        statusCode: 400,
      );
    }
  }

  @override
  Future<BlockedUser> blockUser(String userId) async {
    final existing = _blocked.where((u) => u.userId == userId).firstOrNull;
    if (existing != null) return existing;
    final user = BlockedUser(
      userId: userId,
      nickname: '이웃 $userId',
      blockedAt: DateTime.now(),
    );
    _blocked.insert(0, user);
    return user;
  }

  @override
  Future<void> unblockUser(String userId) async {
    _blocked.removeWhere((u) => u.userId == userId);
  }

  @override
  Future<List<BlockedUser>> getBlockedUsers() async => List.of(_blocked);
}
