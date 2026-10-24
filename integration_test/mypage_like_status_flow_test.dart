// On-device E2E: like (optimistic) → 관심목록 → 거래 상태 예약중 → 거래완료
// (feed card / 내 판매글 badges, filter) → delete (gone from feed, 관심목록,
// 내 판매글; server 404).
//
//   adb install -r -g build\app\outputs\flutter-apk\app-debug.apk
//   flutter test integration_test/mypage_like_status_flow_test.dart \
//     -d <device-id> --dart-define=USE_MOCK_API=false
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flatmate_app/app/app.dart';
import 'package:flatmate_app/app/config/app_config.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/core/di/injection.dart';
import 'package:flatmate_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_screen.dart';
import 'package:flatmate_app/features/post_create/data/image_picker_service.dart';
import 'package:flatmate_app/features/post_create/presentation/providers/create_post_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';

const _password = 'Flatmate123!';

final _log = <String>[];

void _step(String message) {
  _log.add(message);
  debugPrint('[E2E] $message');
}

class _DevicePngPicker extends PostImagePicker {
  _DevicePngPicker(this.files);

  final List<XFile> files;

  @override
  Future<List<XFile>> pickFromGallery({required int limit}) async =>
      files.take(limit).toList();

  @override
  Future<XFile?> pickFromCamera() async => files.first;
}

Future<XFile> _renderPng(Directory dir, String name, Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 640, 480), Paint()..color = color);
  final image = await recorder.endRecording().toImage(640, 480);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('${dir.path}/$name.png')
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
  return XFile(file.path);
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

Future<void> _enter(WidgetTester tester, String key, String text) async {
  final field = find.byKey(ValueKey(key));
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

String _text(WidgetTester tester, Finder finder) =>
    tester.widget<Text>(finder).data!;

Finder _badgeText(String key, String label) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: find.text(label));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실기기 E2E: 좋아요 → 관심목록 → 예약중/거래완료 → 삭제', (tester) async {
    await configureDependencies();
    expect(sl<AppConfig>().useMockApi, isFalse,
        reason: 'Run with --dart-define=USE_MOCK_API=false');
    final tokens = sl<TokenStorage>();
    await tokens.clear();

    final dir = await Directory.systemTemp.createTemp('flatmate_e2e');
    final photos = await tester.runAsync(
      () async => [await _renderPng(dir, 'desk', Colors.brown)],
    );

    final stamp = DateTime.now().millisecondsSinceEpoch;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postImagePickerProvider.overrideWithValue(_DevicePngPicker(photos!)),
        ],
        child: FlatmateApp(),
      ),
    );

    // Sign up (GPS dong) → 일반 글 15,000원.
    await _pumpUntil(tester, find.text('회원가입'));
    await _tap(tester, find.text('회원가입'));
    await _pumpUntil(tester, find.text('다음'));
    final form = find.byType(TextFormField);
    await tester.enterText(form.at(0), 'qa.my$stamp@example.com');
    await tester.enterText(form.at(1), _password);
    await tester.enterText(form.at(2), _password);
    await tester.enterText(form.at(3), 'QA마이${stamp % 10000}');
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

    final title = '[MY $stamp] 원목 책상 팝니다';
    await _tap(tester, find.text('글쓰기'));
    await _pumpUntil(tester, find.text('무엇을 올릴까요?'));
    await _tap(tester, find.text('일반글 작성'));
    await _pumpUntil(tester, find.text('완료'));
    await _tap(tester, find.byKey(const ValueKey('image-add')));
    await _pumpUntil(tester, find.textContaining('앨범에서 선택'));
    await _tap(tester, find.textContaining('앨범에서 선택'));
    await _pumpUntil(tester, find.byKey(const ValueKey('image-thumb-0')));
    await _enter(tester, 'post-title', title);
    await _enter(tester, 'post-body', '1년 사용, 상태 좋아요.');
    await _enter(tester, 'field-price', '15000');
    await _tap(tester, find.text('완료'));
    await _pumpUntil(tester, find.text('게시글이 등록되었습니다.'));
    await _pumpUntil(tester, find.textContaining(title));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(FeedScreen)));
    final post = container.read(feedListProvider).value!.items.first;
    expect(post.title, title);

    final dio = Dio(BaseOptions(baseUrl: AppConfig.devServerBaseUrl));
    Options auth() =>
        Options(headers: {'Authorization': 'Bearer ${tokens.accessToken}'});
    Future<Map<String, dynamic>> serverFeed() async => (await dio
            .get<Map<String, dynamic>>('/feeds/${post.id}', options: auth()))
        .data!;
    _step('글 등록: 피드 ${post.id}');

    // 1) Detail heart: filled + count 1 (server agrees).
    await _tap(tester, find.textContaining(title));
    await _pumpUntil(tester, find.byKey(const ValueKey('detail-like')));
    expect(_text(tester, find.byKey(const ValueKey('detail-like-count'))), '관심 0');
    await _tap(tester, find.byKey(const ValueKey('detail-like')));
    await _pumpUntil(
      tester,
      find.descendant(
        of: find.byKey(const ValueKey('detail-like')),
        matching: find.byIcon(Icons.favorite_rounded),
      ),
    );
    expect(_text(tester, find.byKey(const ValueKey('detail-like-count'))), '관심 1');
    var server = await serverFeed();
    expect(server['is_liked'], isTrue);
    expect(server['like_count'], 1);
    _step('상세 하트: 채워짐 · 관심 1 · 서버 is_liked=true, like_count=1');

    // 2) 마이페이지 관심목록 shows it.
    await _tap(tester, find.byIcon(Icons.arrow_back_rounded));
    await _pumpUntil(tester, find.byType(FeedScreen));
    await _tap(tester, find.text('마이플랫'));
    await _pumpUntil(tester, find.byKey(const ValueKey('tab-my-likes')));
    await _tap(tester, find.byKey(const ValueKey('tab-my-likes')));
    await _pumpUntil(tester, find.byKey(ValueKey('my-like-${post.id}')));
    _step('마이페이지 [관심목록]에 노출');

    // 3) Author menu: 예약중 → 거래완료.
    await _tap(tester, find.text('홈'));
    await _pumpUntil(tester, find.textContaining(title));
    await _tap(tester, find.textContaining(title));
    for (final (code, label) in [('RESERVED', '예약중'), ('COMPLETED', '거래완료')]) {
      await _pumpUntil(tester, find.byKey(const ValueKey('detail-more')));
      await _tap(tester, find.byKey(const ValueKey('detail-more')));
      await _pumpUntil(tester, find.byKey(const ValueKey('menu-trade-status')));
      await _tap(tester, find.byKey(const ValueKey('menu-trade-status')));
      await _pumpUntil(tester, find.byKey(ValueKey('trade-option-$code')));
      await _tap(tester, find.byKey(ValueKey('trade-option-$code')));
      await _pumpUntil(tester, _badgeText('detail-trade-badge', label));
      server = await serverFeed();
      expect(server['trade_status'], code);
      _step('작성자 메뉴 → $label (서버 trade_status=$code)');
    }
    await _tap(tester, find.byIcon(Icons.arrow_back_rounded));
    await _pumpUntil(tester, find.byType(FeedScreen));
    await _pumpUntil(tester, _badgeText('trade-badge-${post.id}', '거래완료'));
    _step('피드 카드 뱃지 [거래완료]');

    await _tap(tester, find.text('마이플랫'));
    await _tap(tester, find.byKey(const ValueKey('tab-my-feeds')));
    await _pumpUntil(tester, _badgeText('my-badge-${post.id}', '거래완료'));
    await _tap(tester, find.byKey(const ValueKey('my-filter-selling')));
    await _pumpUntilGone(tester, find.byKey(ValueKey('my-feed-${post.id}')));
    await _tap(tester, find.byKey(const ValueKey('my-filter-completed')));
    await _pumpUntil(tester, find.byKey(ValueKey('my-feed-${post.id}')));
    await _tap(tester, find.byKey(const ValueKey('my-filter-all')));
    await _pumpUntil(tester, find.byKey(ValueKey('my-feed-${post.id}')));
    _step('[내 판매글] 뱃지 거래완료 · 판매중 필터 제외 · 거래완료 필터 포함');

    // 4) Delete → gone everywhere, server 404.
    await _tap(tester, find.text('홈'));
    await _pumpUntil(tester, find.textContaining(title));
    await _tap(tester, find.textContaining(title));
    await _pumpUntil(tester, find.byKey(const ValueKey('detail-more')));
    await _tap(tester, find.byKey(const ValueKey('detail-more')));
    await _pumpUntil(tester, find.byKey(const ValueKey('menu-delete')));
    await _tap(tester, find.byKey(const ValueKey('menu-delete')));
    await _pumpUntil(tester, find.byKey(const ValueKey('confirm-delete')));
    await _tap(tester, find.byKey(const ValueKey('confirm-delete')));
    await _pumpUntil(tester, find.byType(FeedScreen));
    await _pumpUntilGone(tester, find.textContaining(title));

    await _tap(tester, find.text('마이플랫'));
    await _tap(tester, find.byKey(const ValueKey('tab-my-feeds')));
    await _pumpFor(tester, const Duration(seconds: 2));
    expect(find.byKey(ValueKey('my-feed-${post.id}')), findsNothing);
    await _tap(tester, find.byKey(const ValueKey('tab-my-likes')));
    await _pumpFor(tester, const Duration(seconds: 2));
    expect(find.byKey(ValueKey('my-like-${post.id}')), findsNothing);

    final gone = await dio.get<dynamic>(
      '/feeds/${post.id}',
      options: Options(validateStatus: (_) => true),
    );
    expect(gone.statusCode, 404);
    _step('삭제 → 피드·내 판매글·관심목록에서 제외 · 서버 GET /feeds/${post.id} = 404');

    debugPrint('[E2E] ===== SUMMARY =====\n${_log.join('\n')}');
    await dir.delete(recursive: true).catchError((_) => dir);
  });
}
