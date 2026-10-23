import 'models/blocked_user.dart';
import 'models/report_reason.dart';

/// 게시글 신고 (`/reports/feeds`) and 사용자 차단 (`/blocks/users`).
///
/// Ids are the app's string ids; non-numeric (mock / collected) ids are
/// rejected with an `ApiException` before any request.
abstract class BlockReportRepository {
  Future<void> reportFeed(
    String feedId,
    ReportReason reason, {
    String? details,
  });

  /// Idempotent on the server (already blocked → 200).
  Future<BlockedUser> blockUser(String userId);

  /// Idempotent on the server (not blocked → 200).
  Future<void> unblockUser(String userId);

  /// Most recently blocked first.
  Future<List<BlockedUser>> getBlockedUsers();
}
