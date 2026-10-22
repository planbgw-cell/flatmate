// On-device E2E: 일반(중고) post with a price → author nickname + server
// price_text on feed card / detail → peer inquiry → chat list tile shows
// thumbnail, title and feed_price_text from a single GET /chats/rooms.
//
//   adb shell pm grant com.flatmate.flatmate_app android.permission.ACCESS_FINE_LOCATION
//   flutter test integration_test/general_price_flow_test.dart \
//     -d <device-id> --dart-define=USE_MOCK_API=false
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
import 'package:flatmate_app/features/feed/presentation/widgets/author_profile_card.dart';
import 'package:flatmate_app/features/post_create/data/image_picker_service.dart';
import 'package:flatmate_app/features/post_create/presentation/providers/create_post_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';

const _password = 'Flatmate123!';
const _peerEmail = 'qa.buyer@example.com';
const _priceText = '15,000원';

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
  canvas.drawCircle(const Offset(320, 240), 140, Paint()..color = Colors.white);
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

String _text(WidgetTester tester, Finder finder) =>
    tester.widget<Text>(finder).data!;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실기기 E2E: 일반 글 15,000원 → 닉네임·가격 노출 → 채팅 목록 가격', (tester) async {
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
    final photos = await tester.runAsync(
      () async => [await _renderPng(dir, 'fan', Colors.indigo)],
    );

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final nickname = 'QA중고${stamp % 10000}';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postImagePickerProvider.overrideWithValue(_DevicePngPicker(photos!)),
        ],
        child: FlatmateApp(),
      ),
    );

    // Account A (seller): signup onboarding with GPS dong.
    await _pumpUntil(tester, find.text('회원가입'));
    await _tap(tester, find.text('회원가입'));
    await _pumpUntil(tester, find.text('다음'));
    final form = find.byType(TextFormField);
    await tester.enterText(form.at(0), 'qa.price$stamp@example.com');
    await tester.enterText(form.at(1), _password);
    await tester.enterText(form.at(2), _password);
    await tester.enterText(form.at(3), nickname);
    await _tap(tester, find.text('다음'));
    await _pumpUntil(tester, find.text('현재 위치로 동네 찾기'));
    // Indoors a cold GPS fix can time out once; the user would tap again.
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
    final sellerId = tokens.userId!;
    _step('판매자 A "$nickname" 가입 (id=$sellerId)');

    // 1) 일반 글: 사진 1장 + 가격 15,000원 + 가격 제안 받기.
    final title = '[PRICE $stamp] 미니 선풍기 팝니다';
    await _tap(tester, find.text('글쓰기'));
    await _pumpUntil(tester, find.text('무엇을 올릴까요?'));
    await _tap(tester, find.text('일반글 작성'));
    await _pumpUntil(tester, find.text('완료'));
    await _tap(tester, find.byKey(const ValueKey('image-add')));
    await _pumpUntil(tester, find.textContaining('앨범에서 선택'));
    await _tap(tester, find.textContaining('앨범에서 선택'));
    await _pumpUntil(tester, find.byKey(const ValueKey('image-thumb-0')));
    await _enter(tester, 'post-title', title);
    await _enter(tester, 'post-body', '거의 새 제품이에요. 직거래 선호합니다.');
    await _enter(tester, 'field-price', '15000');
    await _tap(tester, find.byKey(const ValueKey('field-can-negotiate')));
    await _tap(tester, find.text('완료'));
    await _pumpUntil(tester, find.text('게시글이 등록되었습니다.'));
    await _pumpUntil(tester, find.textContaining(title));

    final container =
        ProviderScope.containerOf(tester.element(find.byType(FeedScreen)));
    final post = container.read(feedListProvider).value!.items.first;
    expect(post.title, title);

    final dio = Dio(BaseOptions(baseUrl: AppConfig.devServerBaseUrl));
    final server =
        (await dio.get<Map<String, dynamic>>('/feeds/${post.id}')).data!;
    expect(server['price_text'], _priceText);
    expect(server['author_nickname'], nickname);
    expect(server['extra_meta'], {
      'price': 15000,
      'is_free': false,
      'can_negotiate': true,
    });
    _step('등록 → 피드 ${post.id}: price_text="${server['price_text']}" · '
        'author_nickname="${server['author_nickname']}" · extra_meta=${server['extra_meta']}');

    // 2) Feed card: nickname in the meta line, server price text.
    final meta = find.byKey(ValueKey('feed-meta-${post.id}'));
    final price = find.byKey(ValueKey('feed-price-${post.id}'));
    expect(_text(tester, meta), startsWith('$nickname · '));
    expect(_text(tester, price), _priceText);
    _step('피드 카드: "${_text(tester, meta)}" / "${_text(tester, price)}"');

    // 3) Detail: author card nickname + price card + bottom bar.
    await _tap(tester, find.textContaining(title));
    await _pumpUntil(tester, find.byKey(const ValueKey('detail-card-market')));
    expect(
      find.descendant(
        of: find.byType(AuthorProfileCard),
        matching: find.text(nickname),
      ),
      findsOneWidget,
    );
    expect(
      _text(tester, find.byKey(const ValueKey('detail-card-price'))),
      _priceText,
    );
    expect(find.text(_priceText), findsWidgets);
    _step('상세: 작성자 "$nickname" · 거래 정보 카드/하단 바 "$_priceText"');
    await _tap(tester, find.byIcon(Icons.arrow_back_rounded));
    await _pumpUntil(tester, find.byType(FeedScreen));

    // 4) Peer B inquires.
    final login = await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': _peerEmail, 'password': _password},
    );
    final auth = Options(
      headers: {'Authorization': 'Bearer ${login.data!['access_token']}'},
    );
    final room = (await dio.post<Map<String, dynamic>>(
      '/chats/rooms',
      data: {'peer_id': int.parse(sellerId), 'feed_id': int.parse(post.id)},
      options: auth,
    ))
        .data!;
    final roomId = room['id'].toString();
    await dio.post<dynamic>(
      '/chats/rooms/$roomId/messages',
      data: {'content': '[PRICE $stamp] 선풍기 아직 있나요?'},
      options: auth,
    );
    expect(room['feed_price_text'], _priceText);
    _step('상대 B 문의 → room=$roomId (feed_price_text="${room['feed_price_text']}")');

    // 5) A's chat list: thumbnail · title · price from one GET /chats/rooms.
    requests.clear();
    await _tap(tester, find.text('채팅'));
    final roomPrice = find.byKey(ValueKey('room-price-$roomId'));
    await _pumpUntil(tester, roomPrice);
    expect(_text(tester, roomPrice), _priceText);
    expect(_text(tester, find.byKey(ValueKey('room-title-$roomId'))), title);
    expect(
      tester
          .widget<CachedNetworkImage>(find.byKey(ValueKey('room-thumb-$roomId')))
          .imageUrl,
      post.thumbnailUrl,
    );
    expect(requests, ['GET /chats/rooms']);
    _step('채팅 목록: 썸네일·제목·"$_priceText" 즉시 표시 · 요청=$requests');

    debugPrint('[E2E] ===== SUMMARY =====\n${_log.join('\n')}');
    await dir.delete(recursive: true).catchError((_) => dir);
  });
}
