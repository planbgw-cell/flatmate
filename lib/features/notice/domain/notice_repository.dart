import 'notice.dart';

/// 공지사항 (public; no login needed).
abstract class NoticeRepository {
  Future<List<Notice>> getNotices({int limit = 50});
}
