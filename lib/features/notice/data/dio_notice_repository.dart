import '../../../core/network/api_client.dart';
import '../domain/notice.dart';
import '../domain/notice_repository.dart';

class DioNoticeRepository implements NoticeRepository {
  DioNoticeRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Notice>> getNotices({int limit = 50}) async {
    final response = await _api.get<dynamic>(
      '/notices',
      queryParameters: {'limit': limit},
    );
    final data = response.data;
    if (data is! List) return const [];
    return [
      for (final row in data)
        if (row is Map) Notice.fromJson(Map<String, dynamic>.from(row)),
    ];
  }
}
