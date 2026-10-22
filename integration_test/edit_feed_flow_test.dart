// On-device E2E: own 일반 글 (사진 2장 · 15,000원) → 상세 ⋮ → 게시글 수정 →
// prefill (제목·본문·가격·사진) → 제목 변경 + 사진 1장 삭제 → 수정 완료 →
// 상세 / 피드 카드 / 서버 반영.
//
//   adb install -r -g build\app\outputs\flutter-apk\app-debug.apk
//   flutter test integration_test/edit_feed_flow_test.dart \
//     -d <device-id> --dart-define=USE_MOCK_API=false
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flatmate_app/app/app.dart';
import 'package:flatmate_app/app/config/app_config.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/core/di/injection.dart';
import 'package:flatmate_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_detail_screen.dart';
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

String _fieldText(WidgetTester tester, String key) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(EditableText),
      ),
    )
    .controller
    .text;

Finder _inDetail(Finder finder) =>
    find.descendant(of: find.byType(FeedDetailScreen), matching: finder);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실기기 E2E: 게시글 수정 (프리필 → 제목 변경·사진 1장 삭제 → 반영)',
      (tester) async {
    await configureDependencies();
    expect(sl<AppConfig>().useMockApi, isFalse,
        reason: 'Run with --dart-define=USE_MOCK_API=false');
    final tokens = sl<TokenStorage>();
    await tokens.clear();

    final dir = await Directory.systemTemp.createTemp('flatmate_e2e');
    final photos = await tester.runAsync(
      () async => [
        await _renderPng(dir, 'fan_front', Colors.teal),
        await _renderPng(dir, 'fan_side', Colors.orange),
      ],
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

    // Sign up (GPS dong) → 일반 글 · 사진 2장 · 15,000원.
    await _pumpUntil(tester, find.text('회원가입'));
    await _tap(tester, find.text('회원가입'));
    await _pumpUntil(tester, find.text('다음'));
    final form = find.byType(TextFormField);
    await tester.enterText(form.at(0), 'qa.edit$stamp@example.com');
    await tester.enterText(form.at(1), _password);
    await tester.enterText(form.at(2), _password);
    await tester.enterText(form.at(3), 'QA수정${stamp % 10000}');
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

    final title = '[EDIT $stamp] 선풍기 팝니다';
    final newTitle = '[EDIT $stamp] 선풍기 가격 내려요';
    const body = '여름 한 철 사용했어요.';
    await _tap(tester, find.text('글쓰기'));
    await _pumpUntil(tester, find.text('무엇을 올릴까요?'));
    await _tap(tester, find.text('일반글 작성'));
    await _pumpUntil(tester, find.text('완료'));
    await _tap(tester, find.byKey(const ValueKey('image-add')));
    await _pumpUntil(tester, find.textContaining('앨범에서 선택'));
    await _tap(tester, find.textContaining('앨범에서 선택'));
    await _pumpUntil(tester, find.byKey(const ValueKey('image-thumb-1')));
    await _enter(tester, 'post-title', title);
    await _enter(tester, 'post-body', body);
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
    final before = await serverFeed();
    final originalUrls = List<String>.from(before['image_urls'] as List);
    expect(originalUrls, hasLength(2));
    _step('글 등록: 피드 ${post.id} · 사진 2장 · 15,000원');

    // 1) Detail ⋮ → 게시글 수정 → prefilled form.
    await _tap(tester, find.textContaining(title));
    await _pumpUntil(tester, find.byKey(const ValueKey('detail-more')));
    expect(_inDetail(find.text('1 / 2')), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('detail-more')));
    await _pumpUntil(tester, find.byKey(const ValueKey('menu-edit')));
    await _tap(tester, find.byKey(const ValueKey('menu-edit')));
    await _pumpUntil(tester, find.text('글 수정하기'));
    expect(find.text('수정 완료'), findsOneWidget);
    expect(_fieldText(tester, 'post-title'), title);
    expect(_fieldText(tester, 'post-body'), body);
    expect(_fieldText(tester, 'field-price'), '15000');
    expect(find.byKey(const ValueKey('image-thumb-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('image-thumb-1')), findsOneWidget);
    expect(find.text('2/10'), findsOneWidget);
    _step('[게시글 수정] 진입: 제목·본문·가격 15000·사진 2장 프리필');

    // 2) Change title + delete the cover photo → 수정 완료.
    await _enter(tester, 'post-title', newTitle);
    await _tap(tester, find.byKey(const ValueKey('image-remove-0')));
    await _pumpUntil(tester, find.text('1/10'));
    await _tap(tester, find.text('수정 완료'));
    await _pumpUntil(tester, find.text('게시글을 수정했어요.'));
    await _pumpUntil(tester, _inDetail(find.textContaining(newTitle)));
    await _pumpUntil(tester, _inDetail(find.text('1 / 1')));
    expect(_inDetail(find.textContaining(title)), findsNothing);
    _step('수정 완료 → 상세 제목 변경 · 사진 1 / 1');

    final after = await serverFeed();
    expect(after['title'], newTitle);
    expect(after['content'], body);
    expect(after['image_urls'], [originalUrls[1]]);
    expect(after['thumbnail_url'], originalUrls[1]);
    expect((after['extra_meta'] as Map)['price'], 15000);
    _step('서버 GET /feeds/${post.id}: title 변경 · image_urls 1장 '
        '(${originalUrls[1]}) · price 15000 유지');

    // 3) Feed card shows the new title.
    await _tap(tester, find.byIcon(Icons.arrow_back_rounded));
    await _pumpUntil(tester, find.byType(FeedScreen));
    await _pumpUntil(tester, find.textContaining(newTitle));
    expect(find.textContaining(title), findsNothing);
    _step('피드 카드 제목 반영');

    await dio.delete<dynamic>('/feeds/${post.id}', options: auth());
    debugPrint('[E2E] ===== SUMMARY =====\n${_log.join('\n')}');
    await dir.delete(recursive: true).catchError((_) => dir);
  });
}
