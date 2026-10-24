import 'package:flatmate_app/app/routes/route_names.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:flatmate_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flatmate_app/features/mypage/presentation/pages/my_page.dart';
import 'package:flatmate_app/features/notice/domain/notice.dart';
import 'package:flatmate_app/features/notice/domain/notice_repository.dart';
import 'package:flatmate_app/features/notice/presentation/providers/notice_provider.dart';
import 'package:flatmate_app/features/notice/presentation/screens/notice_detail_screen.dart';
import 'package:flatmate_app/features/notice/presentation/screens/notice_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Notice _notice(int id, {bool pinned = false, required DateTime at}) => Notice(
      id: id,
      title: '공지 $id',
      content: '공지 $id 본문입니다.\n두 번째 줄',
      isPinned: pinned,
      createdAt: at,
      updatedAt: at,
    );

class _Notices implements NoticeRepository {
  _Notices(this.notices);

  List<Notice> notices;
  int calls = 0;

  @override
  Future<List<Notice>> getNotices({int limit = 50}) async {
    calls++;
    return notices;
  }
}

GoRouter _router({String initial = RouteNames.notices}) => GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: '/mypage', builder: (_, _) => const MyPage()),
        GoRoute(
          path: RouteNames.notices,
          builder: (_, _) => const NoticeListScreen(),
        ),
        GoRoute(
          path: RouteNames.noticeDetail,
          builder: (_, state) =>
              NoticeDetailScreen(notice: state.extra! as Notice),
        ),
      ],
    );

Future<void> _pump(
  WidgetTester tester,
  _Notices repo, {
  String initial = RouteNames.notices,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        noticeRepositoryProvider.overrideWithValue(repo),
        tokenStorageProvider.overrideWithValue(TokenStorage()),
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
      ],
      child: MaterialApp.router(routerConfig: _router(initial: initial)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('sortNotices: pinned first, then newest', () {
    final sorted = sortNotices([
      _notice(1, at: DateTime(2026, 10, 1)),
      _notice(2, pinned: true, at: DateTime(2026, 9, 1)),
      _notice(3, at: DateTime(2026, 10, 20)),
      _notice(4, pinned: true, at: DateTime(2026, 10, 5)),
    ]);
    expect(sorted.map((n) => n.id), [4, 2, 3, 1]);
  });

  testWidgets('list: 필독 on top with badge · YYYY.MM.DD · tap opens detail',
      (tester) async {
    final repo = _Notices([
      _notice(1, at: DateTime(2026, 10, 23, 9, 5)),
      _notice(2, pinned: true, at: DateTime(2026, 9, 3, 14, 30)),
    ]);
    await _pump(tester, repo);

    expect(find.text('공지사항'), findsOneWidget);
    final pinnedTop = tester.getTopLeft(find.byKey(const ValueKey('notice-tile-2')));
    final normalTop = tester.getTopLeft(find.byKey(const ValueKey('notice-tile-1')));
    expect(pinnedTop.dy, lessThan(normalTop.dy));
    expect(find.byKey(const ValueKey('notice-pinned-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('notice-pinned-1')), findsNothing);
    expect(find.text('필독'), findsOneWidget);
    expect(find.text('2026.09.03'), findsOneWidget);
    expect(find.text('2026.10.23'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('notice-tile-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notice-detail-title')), findsOneWidget);
    expect(find.text('공지 2'), findsOneWidget);
    expect(find.text('2026.09.03 14:30'), findsOneWidget);
    expect(find.text('공지 2 본문입니다.\n두 번째 줄'), findsOneWidget);
    expect(find.text('필독'), findsOneWidget);
  });

  testWidgets('empty list shows a notice; pull-to-refresh reloads',
      (tester) async {
    final repo = _Notices([]);
    await _pump(tester, repo);
    expect(find.text('등록된 공지사항이 없습니다.'), findsOneWidget);
    expect(repo.calls, 1);

    repo.notices = [_notice(7, at: DateTime(2026, 10, 24))];
    await tester.fling(
      find.text('등록된 공지사항이 없습니다.'),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();
    expect(repo.calls, 2);
    expect(find.byKey(const ValueKey('notice-tile-7')), findsOneWidget);
  });

  testWidgets('guest My Page has [공지사항] → notice list', (tester) async {
    final repo = _Notices([_notice(1, pinned: true, at: DateTime(2026, 10, 24))]);
    await _pump(tester, repo, initial: '/mypage');
    expect(find.text('로그인 / 회원가입'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('menu-notices')));
    await tester.pumpAndSettle();
    expect(find.byType(NoticeListScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('notice-tile-1')), findsOneWidget);
  });
}
