// On-device E2E: photo upload → 부동산 post (typed extra_meta) → detail
// carousel + info card → peer inquiry → chat list shows the listing title /
// thumbnail straight from ChatRoomOut (no extra /feeds calls).
//
//   adb shell pm grant com.flatmate.flatmate_app android.permission.ACCESS_FINE_LOCATION
//   flutter test integration_test/image_post_chat_flow_test.dart \
//     -d <device-id> --dart-define=USE_MOCK_API=false
//
// The system gallery cannot be driven from a Flutter test, so the picker is
// replaced with one returning PNGs rendered on the device; the upload itself
// hits the real server.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flatmate_app/app/app.dart';
import 'package:flatmate_app/app/config/app_config.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/core/di/injection.dart';
import 'package:flatmate_app/core/network/api_client.dart';
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
const _peerEmail = 'qa.buyer@example.com';

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
  canvas.drawCircle(const Offset(320, 240), 120, Paint()..color = Colors.white);
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

String _imageUrlOf(WidgetTester tester, Finder finder) =>
    tester.widget<CachedNetworkImage>(finder).imageUrl;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실기기 E2E: 사진 2장 업로드 → 부동산 등록 → 상세 → 문의 → 채팅 목록 썸네일',
      (tester) async {
    await configureDependencies();
    expect(sl<AppConfig>().useMockApi, isFalse,
        reason: 'Run with --dart-define=USE_MOCK_API=false');
    final tokens = sl<TokenStorage>();
    await tokens.clear();

    final requests = <String>[];
    sl<ApiClient>().dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add('${options.method} ${options.path}');
              handler.next(options);
            },
          ),
        );

    final dir = await Directory.systemTemp.createTemp('flatmate_e2e');
    final photos = await tester.runAsync(() async => [
          await _renderPng(dir, 'room_living', Colors.orange),
          await _renderPng(dir, 'room_kitchen', Colors.teal),
        ]);

    final stamp = DateTime.now().millisecondsSinceEpoch;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postImagePickerProvider.overrideWithValue(_DevicePngPicker(photos!)),
        ],
        child: FlatmateApp(),
      ),
    );

    // Account A (author): signup onboarding with GPS dong.
    await _pumpUntil(tester, find.text('회원가입'));
    await _tap(tester, find.text('회원가입'));
    await _pumpUntil(tester, find.text('다음'));
    final form = find.byType(TextFormField);
    await tester.enterText(form.at(0), 'qa.img$stamp@example.com');
    await tester.enterText(form.at(1), _password);
    await tester.enterText(form.at(2), _password);
    await tester.enterText(form.at(3), 'QA사진${stamp % 10000}');
    await _tap(tester, find.text('다음'));
    await _pumpUntil(tester, find.text('현재 위치로 동네 찾기'));
    await _tap(tester, find.text('현재 위치로 동네 찾기'));
    await _pumpUntil(tester, find.byKey(const ValueKey('signup-selected-dong')));
    await _tap(tester, find.text('가입 완료'));
    await _pumpUntil(tester, find.byType(FeedScreen));
    final authorId = tokens.userId!;
    _step('작성자 A 가입 (id=$authorId)');

    // 1) 부동산 글: 사진 2장 + 원룸 + 보증금 500 / 월세 50.
    final title = '[IMG $stamp] 정자동 채광 좋은 원룸';
    await _tap(tester, find.text('글쓰기'));
    await _pumpUntil(tester, find.text('무엇을 올릴까요?'));
    await _tap(tester, find.text('부동산 / 주거 등록'));
    await _pumpUntil(tester, find.text('완료'));
    await _tap(tester, find.byKey(const ValueKey('image-add')));
    await _pumpUntil(tester, find.textContaining('앨범에서 선택'));
    await _tap(tester, find.textContaining('앨범에서 선택'));
    await _pumpUntil(tester, find.byKey(const ValueKey('image-thumb-1')));
    expect(find.text('2/10'), findsOneWidget);
    expect(find.text('대표'), findsOneWidget);
    await _enter(tester, 'post-title', title);
    await _enter(tester, 'post-body', '남향 원룸, 사진 2장 첨부 테스트입니다.');
    await _enter(tester, 'field-deposit', '500');
    await _enter(tester, 'field-monthly-rent', '50');
    await _tap(tester, find.text('완료'));
    await _pumpUntil(tester, find.text('게시글이 등록되었습니다.'));
    await _pumpUntil(tester, find.textContaining(title));
    expect(requests, contains('POST /uploads/images'));
    expect(
      requests.indexOf('POST /uploads/images'),
      lessThan(requests.lastIndexOf('POST /feeds')),
    );

    final container =
        ProviderScope.containerOf(tester.element(find.byType(FeedScreen)));
    final post = container.read(feedListProvider).value!.items.first;
    expect(post.title, title);

    final dio = Dio(BaseOptions(baseUrl: AppConfig.devServerBaseUrl));
    final server =
        (await dio.get<Map<String, dynamic>>('/feeds/${post.id}')).data!;
    final serverImages = (server['image_urls'] as List).cast<String>();
    expect(serverImages, hasLength(2));
    expect(serverImages.every((u) => u.startsWith('/static/images/')), isTrue);
    expect(server['thumbnail_url'], serverImages.first);
    final meta = server['extra_meta'] as Map<String, dynamic>;
    expect(meta['room_type'], 'ONE_ROOM');
    expect(meta['deposit'], 500);
    expect(meta['monthly_rent'], 50);
    final media = Dio();
    for (final url in post.imageUrls) {
      final res = await media.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      expect(res.statusCode, 200);
      expect(res.headers.value('content-type'), contains('image/png'));
    }
    _step('업로드 → 피드 ${post.id} 등록: image_urls=$serverImages · '
        'extra_meta=$meta · 이미지 GET 200');

    // 2) Detail: carousel (2 absolute URLs) + 부동산 info card.
    await _tap(tester, find.textContaining(title));
    await _pumpUntil(tester, find.byKey(const ValueKey('detail-card-housing')));
    final first = find.byKey(const ValueKey('detail-image-0'));
    expect(_imageUrlOf(tester, first), post.imageUrls[0]);
    expect(_imageUrlOf(tester, first), startsWith('http://121.133.47.161:8000/static/images/'));
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1500);
    await _pumpUntil(tester, find.text('2 / 2'));
    expect(
      _imageUrlOf(tester, find.byKey(const ValueKey('detail-image-1'))),
      post.imageUrls[1],
    );
    final card = find.byKey(const ValueKey('detail-card-housing'));
    expect(
      find.descendant(of: card, matching: find.text('보증금 500 / 월세 50')),
      findsOneWidget,
    );
    expect(find.descendant(of: card, matching: find.text('원룸')), findsWidgets);
    expect(find.descendant(of: card, matching: find.text('500만원')), findsOneWidget);
    _step('상세: 캐러셀 1/2→2/2 (절대 URL) · 부동산 카드(원룸, 보증금 500 / 월세 50)');
    await _tap(tester, find.byIcon(Icons.arrow_back_rounded));
    await _pumpUntil(tester, find.byType(FeedScreen));

    // 3) Peer B asks about the listing.
    final login = await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': _peerEmail, 'password': _password},
    );
    final auth = Options(
      headers: {'Authorization': 'Bearer ${login.data!['access_token']}'},
    );
    final room = (await dio.post<Map<String, dynamic>>(
      '/chats/rooms',
      data: {'peer_id': int.parse(authorId), 'feed_id': int.parse(post.id)},
      options: auth,
    ))
        .data!;
    final roomId = room['id'].toString();
    await dio.post<dynamic>(
      '/chats/rooms/$roomId/messages',
      data: {'content': '[IMG $stamp] 원룸 사진 잘 봤어요. 방문 가능할까요?'},
      options: auth,
    );
    _step('상대 B 문의 → room=$roomId (feed_title="${room['feed_title']}")');

    // 4) A's chat list: title + thumbnail from ChatRoomOut, no /feeds calls.
    requests.clear();
    await _tap(tester, find.text('채팅'));
    final roomTitle = find.byKey(ValueKey('room-title-$roomId'));
    await _pumpUntil(tester, roomTitle);
    expect(tester.widget<Text>(roomTitle).data, title);
    final thumb = find.byKey(ValueKey('room-thumb-$roomId'));
    expect(_imageUrlOf(tester, thumb), post.imageUrls.first);
    expect(requests, contains('GET /chats/rooms'));
    expect(requests.where((r) => r.startsWith('GET /feeds')), isEmpty);
    _step('채팅 목록: 제목·썸네일 즉시 표시 · 요청=$requests (피드 추가 호출 0)');

    debugPrint('[E2E] ===== SUMMARY =====\n${_log.join('\n')}');
    await dir.delete(recursive: true).catchError((_) => dir);
  });
}
