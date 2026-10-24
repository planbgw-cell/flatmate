// On-device E2E (guest, no token): 내정보 → 공지사항 → list matches the server
// (필독 first with badge) → pinned / regular detail shows title · date · body.
// Needs ≥1 pinned and ≥1 regular notice registered in flatmate_admin.
//
//   adb install -r -g build\app\outputs\flutter-apk\app-debug.apk
//   flutter test integration_test/notice_flow_test.dart \
//     -d <device-id> --dart-define=USE_MOCK_API=false
import 'package:dio/dio.dart';
import 'package:flatmate_app/app/app.dart';
import 'package:flatmate_app/app/config/app_config.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/core/di/injection.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_screen.dart';
import 'package:flatmate_app/features/notice/domain/notice.dart';
import 'package:flatmate_app/features/notice/presentation/providers/notice_provider.dart';
import 'package:flatmate_app/features/notice/presentation/screens/notice_detail_screen.dart';
import 'package:flatmate_app/features/notice/presentation/screens/notice_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

final _log = <String>[];

void _step(String message) {
  _log.add(message);
  debugPrint('[E2E] $message');
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      // Let route transitions finish; taps are ignored mid-animation.
      await _pumpFor(tester, const Duration(milliseconds: 800));
      return;
    }
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> _pumpUntilGone(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isEmpty) return;
  }
  throw TestFailure('Still showing $finder');
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).hitTestable().first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
}

String _text(WidgetTester tester, String key) {
  final widget = tester.widget(find.byKey(ValueKey(key)));
  return switch (widget) {
    Text(:final data) => data!,
    SelectableText(:final data) => data!,
    _ => throw TestFailure('No text in $key'),
  };
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실기기 E2E: 마이페이지 → 공지사항 목록 → 필독 · 상세', (tester) async {
    await configureDependencies();
    expect(sl<AppConfig>().useMockApi, isFalse,
        reason: 'Run with --dart-define=USE_MOCK_API=false');
    await sl<TokenStorage>().clear();

    final dio = Dio(BaseOptions(baseUrl: AppConfig.devServerBaseUrl));
    final response = await dio.get<List<dynamic>>('/notices');
    final server = [
      for (final row in response.data!)
        Notice.fromJson(Map<String, dynamic>.from(row as Map)),
    ];
    final pinned = server.where((n) => n.isPinned).toList();
    final regular = server.where((n) => !n.isPinned).toList();
    expect(pinned, isNotEmpty, reason: 'Register a pinned notice in admin');
    expect(regular, isNotEmpty, reason: 'Register a regular notice in admin');
    _step('서버 GET /notices (토큰 없음): ${server.length}건 · 고정 ${pinned.length}건');

    await tester.pumpWidget(ProviderScope(child: FlatmateApp()));

    // Guest → 내정보 → 공지사항.
    await _pumpUntil(tester, find.text('로그인 없이 둘러보기'));
    await _tap(tester, find.text('로그인 없이 둘러보기'));
    await _pumpUntil(tester, find.byType(FeedScreen));
    await _tap(tester, find.text('마이플랫'));
    await _pumpUntil(tester, find.byKey(const ValueKey('menu-notices')));
    await _tap(tester, find.byKey(const ValueKey('menu-notices')));
    await _pumpUntil(tester, find.byType(NoticeListScreen));
    await _pumpUntil(tester, find.byKey(ValueKey('notice-tile-${server.first.id}')));
    _step('게스트 → 내정보 → [공지사항] 진입');

    // Same order as the server; 필독 badges only on pinned, all on top.
    final container =
        ProviderScope.containerOf(tester.element(find.byType(NoticeListScreen)));
    final appIds = container.read(noticesProvider).value!.map((n) => n.id);
    expect(appIds, server.map((n) => n.id));
    expect(appIds, sortNotices(server).map((n) => n.id));
    for (final notice in server) {
      final tile = find.byKey(ValueKey('notice-tile-${notice.id}'));
      if (tile.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          tile,
          200,
          scrollable: find.byType(Scrollable).hitTestable().first,
        );
      }
      expect(
        find.byKey(ValueKey('notice-pinned-${notice.id}')),
        notice.isPinned ? findsOneWidget : findsNothing,
      );
    }
    final lastPinned = server.lastIndexWhere((n) => n.isPinned);
    final firstRegular = server.indexWhere((n) => !n.isPinned);
    expect(lastPinned, lessThan(firstRegular));
    _step('목록 ${server.length}건이 서버와 같은 순서 · 고정 ${pinned.length}건 [필독] 뱃지 · 모두 상단');

    // Detail: one pinned, one regular.
    for (final notice in [pinned.first, regular.first]) {
      tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byKey(const ValueKey('notice-list')),
              matching: find.byType(Scrollable),
            ),
          )
          .position
          .jumpTo(0);
      await tester.pump(const Duration(milliseconds: 300));
      await _tap(tester, find.byKey(ValueKey('notice-tile-${notice.id}')));
      await _pumpUntil(tester, find.byType(NoticeDetailScreen));
      expect(_text(tester, 'notice-detail-title'), notice.title);
      expect(
        _text(tester, 'notice-detail-date'),
        NoticeDetailScreen.formatDateTime(notice.createdAt),
      );
      expect(_text(tester, 'notice-detail-content'), notice.content);
      expect(find.text('필독'), notice.isPinned ? findsOneWidget : findsNothing);
      _step('${notice.isPinned ? '고정' : '일반'} 공지 ${notice.id} 상세: 제목·작성일 '
          '${NoticeDetailScreen.formatDateTime(notice.createdAt)}·본문 서버와 일치');
      await _tap(tester, find.byType(BackButton));
      await _pumpUntilGone(tester, find.byType(NoticeDetailScreen));
    }

    debugPrint('[E2E] ===== SUMMARY =====\n${_log.join('\n')}');
  });
}
