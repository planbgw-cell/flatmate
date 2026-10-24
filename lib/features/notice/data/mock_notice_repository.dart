import '../domain/notice.dart';
import '../domain/notice_repository.dart';

/// Offline samples for mock runs.
class MockNoticeRepository implements NoticeRepository {
  @override
  Future<List<Notice>> getNotices({int limit = 50}) async {
    final now = DateTime.now();
    final notices = [
      Notice(
        id: 1,
        title: '안전한 직거래를 위한 이용 수칙',
        content: '거래 전 상대방의 매너온도와 거래 후기를 확인해 주세요.\n'
            '선입금 요구나 외부 메신저 유도는 사기일 수 있어요.',
        isPinned: true,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
      Notice(
        id: 2,
        title: '검색 기능이 추가되었어요',
        content: '홈 상단 돋보기를 눌러 우리 동네 글을 검색해 보세요.',
        isPinned: false,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Notice(
        id: 3,
        title: 'Flatmate 서비스 오픈 안내',
        content: '우리 동네 자취·알바·생활정보, Flatmate를 시작합니다.',
        isPinned: false,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),
    ];
    return sortNotices(notices).take(limit).toList();
  }
}
