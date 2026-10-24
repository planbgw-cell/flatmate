// On-device E2E (2 accounts): A (API) posts near B's dong → B (UI) reports
// the post (and once more: duplicate) → blocks A (gone from feed + 중고/나눔
// filter) → 마이페이지 차단 사용자 관리 → 차단 해제 → A's post is back.
//
//   adb install -r -g build\app\outputs\flutter-apk\app-debug.apk
//   flutter test integration_test/block_report_flow_test.dart \
//     -d <device-id> --dart-define=USE_MOCK_API=false
import 'package:dio/dio.dart';
import 'package:flatmate_app/app/app.dart';
import 'package:flatmate_app/app/config/app_config.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/core/di/injection.dart';
import 'package:flatmate_app/features/block_report/presentation/screens/blocked_users_screen.dart';
import 'package:flatmate_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_detail_screen.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_screen.dart';
import 'package:flatmate_app/features/location/presentation/providers/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _password = 'Flatmate123!';

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
  final scaffolds = find.byType(Scaffold);
  if (scaffolds.evaluate().isNotEmpty) {
    ScaffoldMessenger.of(tester.element(scaffolds.last)).clearSnackBars();
    await _pumpFor(tester, const Duration(milliseconds: 300));
  }
  // Soft keyboard shrinks lazy lists; close it and scroll the target in.
  FocusManager.instance.primaryFocus?.unfocus();
  await _pumpFor(tester, const Duration(milliseconds: 400));
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

Future<void> _openMenu(WidgetTester tester, String key) async {
  await _pumpUntil(tester, find.byKey(const ValueKey('detail-more')));
  await _tap(tester, find.byKey(const ValueKey('detail-more')));
  await _pumpUntil(tester, find.byKey(ValueKey(key)));
  await _tap(tester, find.byKey(ValueKey(key)));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실기기 E2E: 게시글 신고 → 유저 차단 → 차단 해제', (tester) async {
    await configureDependencies();
    expect(sl<AppConfig>().useMockApi, isFalse,
        reason: 'Run with --dart-define=USE_MOCK_API=false');
    final tokens = sl<TokenStorage>();
    await tokens.clear();

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final dio = Dio(BaseOptions(baseUrl: AppConfig.devServerBaseUrl));
    Options bearer(String token) =>
        Options(headers: {'Authorization': 'Bearer $token'});

    // Account A (seller) via API.
    final sellerEmail = 'qa.blocked$stamp@example.com';
    final sellerName = 'QA차단${stamp % 10000}';
    await dio.post<dynamic>('/auth/signup', data: {
      'email': sellerEmail,
      'password': _password,
      'nickname': sellerName,
    });
    final sellerLogin = await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': sellerEmail, 'password': _password},
    );
    final sellerToken = sellerLogin.data!['access_token'] as String;
    final sellerId = (sellerLogin.data!['user'] as Map)['id'].toString();
    _step('계정 A(API) 가입: $sellerName (id $sellerId)');

    await tester.pumpWidget(ProviderScope(child: FlatmateApp()));

    // Account B (UI) with GPS dong.
    await _pumpUntil(tester, find.text('회원가입'));
    await _tap(tester, find.text('회원가입'));
    await _pumpUntil(tester, find.text('다음'));
    final form = find.byType(TextFormField);
    await tester.enterText(form.at(0), 'qa.blocker$stamp@example.com');
    await tester.enterText(form.at(1), _password);
    await tester.enterText(form.at(2), _password);
    await tester.enterText(form.at(3), 'QA신고${stamp % 10000}');
    await _tap(tester, find.text('다음'));
    await _pumpUntil(tester, find.text('현재 위치로 동네 찾기'));
    for (var attempt = 0; attempt < 2; attempt++) {
      await _tap(tester, find.text('현재 위치로 동네 찾기'));
      try {
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('signup-selected-dong')),
        );
        break;
      } on TestFailure {
        if (attempt == 1) rethrow;
      }
    }
    await _tap(tester, find.text('가입 완료'));
    await _pumpUntil(tester, find.byType(FeedScreen));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(FeedScreen)));
    final here = container.read(currentLocationProvider);

    // A posts at B's dong, then B's feed refreshes.
    final title = '[BLOCK $stamp] 전자레인지 팝니다';
    final created = await dio.post<Map<String, dynamic>>(
      '/feeds',
      options: bearer(sellerToken),
      data: {
        'feed_type': 'GENERAL',
        'title': title,
        'content': '작동 잘 돼요.',
        'lat': here.latitude,
        'lng': here.longitude,
        'address': here.fullName,
        'image_urls': const <String>[],
        'extra_meta': {'price': 9000, 'is_free': false, 'can_negotiate': false},
      },
    );
    final feedId = created.data!['id'].toString();
    await container.read(feedListProvider.notifier).refresh();
    await _pumpUntil(tester, find.textContaining(title));
    _step('계정 B(UI) 가입 · A의 글 $feedId 이 B 피드에 노출');

    // 1) Report (FRAUD + details).
    await _tap(tester, find.textContaining(title));
    await _openMenu(tester, 'menu-report');
    await _pumpUntil(tester, find.byKey(const ValueKey('report-reason-FRAUD')));
    await _tap(tester, find.byKey(const ValueKey('report-reason-FRAUD')));
    await tester.enterText(
      find.byKey(const ValueKey('report-details')),
      '선입금을 요구해요. (E2E $stamp)',
    );
    await _tap(tester, find.byKey(const ValueKey('report-submit')));
    await _pumpUntil(tester, find.text('신고가 접수되었어요.'));
    _step('[게시글 신고하기] 사기 의심 + 상세 내용 → "신고가 접수되었어요."');

    // 2) Same post again: record how the server treats duplicates.
    await _openMenu(tester, 'menu-report');
    await _pumpUntil(tester, find.byKey(const ValueKey('report-reason-SPAM')));
    await _tap(tester, find.byKey(const ValueKey('report-reason-SPAM')));
    await _tap(tester, find.byKey(const ValueKey('report-submit')));
    final duplicate = find.text('이미 신고한 게시글입니다.');
    final accepted = find.text('신고가 접수되었어요.');
    await _pumpUntil(tester, find.byWidgetPredicate(
      (w) => w is Text && (w.data == '이미 신고한 게시글입니다.' || w.data == '신고가 접수되었어요.'),
    ));
    if (duplicate.evaluate().isNotEmpty) {
      _step('중복 신고 → "이미 신고한 게시글입니다." (서버 400/409)');
    } else {
      expect(accepted, findsOneWidget);
      _step('중복 신고 → 서버가 다시 접수함 (201, 중복 차단 없음)');
    }

    // 3) Block A → detail closes, post leaves the feed and the 중고/나눔 filter.
    await _openMenu(tester, 'menu-block');
    await _pumpUntil(tester, find.text('해당 유저의 글과 채팅이 더 이상 보이지 않습니다.'));
    await _tap(tester, find.byKey(const ValueKey('confirm-block')));
    await _pumpUntil(tester, find.text('$sellerName님을 차단했어요.'));
    await _pumpUntilGone(tester, find.byType(FeedDetailScreen));
    await _pumpUntil(tester, find.byType(FeedScreen));
    await _pumpFor(tester, const Duration(seconds: 2));
    expect(find.textContaining(title), findsNothing);
    final blockedOnServer = await dio.get<List<dynamic>>(
      '/blocks/users',
      options: bearer(tokens.accessToken!),
    );
    expect(
      blockedOnServer.data!.map((u) => (u as Map)['user_id'].toString()),
      contains(sellerId),
    );
    final serverFeed = await dio.get<Map<String, dynamic>>(
      '/feeds',
      queryParameters: {
        'lat': here.latitude,
        'lng': here.longitude,
        'radius_m': 3000,
        'limit': 50,
      },
      options: bearer(tokens.accessToken!),
    );
    final serverFilters = !(serverFeed.data!['items'] as List)
        .any((e) => (e as Map)['id'].toString() == feedId);
    _step('[이 유저 차단하기] → 상세 닫힘 · 피드에서 제거 · 서버 GET /blocks/users 에 A 포함 '
        '(서버 GET /feeds 차단 필터: ${serverFilters ? '있음' : '없음 → 앱에서 거름'})');

    await _tap(tester, find.text('중고/나눔').first);
    await _pumpFor(tester, const Duration(seconds: 2));
    expect(container.read(selectedCategoryProvider), 'market');
    expect(find.textContaining(title), findsNothing);
    await _tap(tester, find.text('전체').first);
    await _pumpFor(tester, const Duration(seconds: 1));
    _step('카테고리 [중고/나눔] 필터에서도 미노출');

    // 4) 마이페이지 → 차단 사용자 관리 → 차단 해제 → post is back.
    await _tap(tester, find.text('마이플랫'));
    await _pumpUntil(tester, find.byKey(const ValueKey('menu-blocked-users')));
    await _tap(tester, find.byKey(const ValueKey('menu-blocked-users')));
    await _pumpUntil(tester, find.byType(BlockedUsersScreen));
    await _pumpUntil(tester, find.byKey(ValueKey('blocked-user-$sellerId')));
    expect(find.text(sellerName), findsOneWidget);
    await _tap(tester, find.byKey(ValueKey('unblock-$sellerId')));
    await _pumpUntilGone(tester, find.byKey(ValueKey('blocked-user-$sellerId')));
    await _pumpUntil(tester, find.text('차단한 사용자가 없어요.'));
    final afterUnblock = await dio.get<List<dynamic>>(
      '/blocks/users',
      options: bearer(tokens.accessToken!),
    );
    expect(afterUnblock.data, isEmpty);
    _step('[차단 사용자 관리] A 타일 → [차단 해제] → 타일 제거 · 서버 목록 비어 있음');

    await _tap(tester, find.byType(BackButton));
    await _pumpUntilGone(tester, find.byType(BlockedUsersScreen));
    await _tap(tester, find.text('홈'));
    await _pumpUntil(tester, find.textContaining(title));
    _step('메인 피드로 돌아오면 A의 글 다시 노출');

    await dio.delete<dynamic>('/feeds/$feedId', options: bearer(sellerToken));
    debugPrint('[E2E] ===== SUMMARY =====\n${_log.join('\n')}');
  });
}
