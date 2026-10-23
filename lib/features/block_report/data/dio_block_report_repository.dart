import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/block_report_repository.dart';
import '../domain/models/blocked_user.dart';
import '../domain/models/report_reason.dart';

class DioBlockReportRepository implements BlockReportRepository {
  DioBlockReportRepository(this._api);

  final ApiClient _api;

  @override
  Future<void> reportFeed(
    String feedId,
    ReportReason reason, {
    String? details,
  }) async {
    final text = details?.trim() ?? '';
    await _api.post<dynamic>(
      '/reports/feeds',
      data: {
        'feed_id': _serverId(feedId, '게시글'),
        'reason': reason.code,
        if (text.isNotEmpty) 'details': text,
      },
    );
  }

  @override
  Future<BlockedUser> blockUser(String userId) async {
    final response = await _api.post<dynamic>(
      '/blocks/users',
      data: {'blocked_user_id': _serverId(userId, '사용자')},
    );
    return BlockedUser.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<void> unblockUser(String userId) async {
    await _api.delete<dynamic>('/blocks/users/${_serverId(userId, '사용자')}');
  }

  @override
  Future<List<BlockedUser>> getBlockedUsers() async {
    final response = await _api.get<dynamic>('/blocks/users');
    final data = response.data;
    if (data is! List) return const [];
    return [
      for (final row in data)
        if (row is Map) BlockedUser.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  static int _serverId(String id, String what) {
    final value = int.tryParse(id);
    if (value == null) {
      throw ApiException(message: '이 $what에는 사용할 수 없는 기능입니다.');
    }
    return value;
  }
}
