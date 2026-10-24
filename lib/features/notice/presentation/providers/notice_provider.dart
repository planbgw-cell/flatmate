import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../domain/notice.dart';
import '../../domain/notice_repository.dart';

final noticeRepositoryProvider = Provider<NoticeRepository>((ref) {
  return sl<NoticeRepository>();
});

class NoticesNotifier extends AsyncNotifier<List<Notice>> {
  Future<List<Notice>> _load() async =>
      sortNotices(await ref.read(noticeRepositoryProvider).getNotices());

  @override
  Future<List<Notice>> build() => _load();

  /// Pull-to-refresh: keeps the current list visible until the reload lands.
  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }
}

final noticesProvider =
    AsyncNotifierProvider.autoDispose<NoticesNotifier, List<Notice>>(
  NoticesNotifier.new,
);
