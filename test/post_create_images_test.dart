import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/core/network/media_url.dart';
import 'package:flatmate_app/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:flatmate_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flatmate_app/features/feed/data/repositories/mock_feed_repository.dart';
import 'package:flatmate_app/features/feed/domain/models/feed_item.dart';
import 'package:flatmate_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:flatmate_app/features/location/domain/models/location_item.dart';
import 'package:flatmate_app/features/post_create/data/image_picker_service.dart';
import 'package:flatmate_app/features/post_create/data/image_upload_service.dart';
import 'package:flatmate_app/features/post_create/domain/post_image.dart';
import 'package:flatmate_app/features/post_create/presentation/providers/create_post_provider.dart';
import 'package:flatmate_app/features/post_create/presentation/screens/general_create_screen.dart';
import 'package:flatmate_app/features/post_create/presentation/screens/real_estate_create_screen.dart';
import 'package:flatmate_app/features/post_create/presentation/widgets/image_picker_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class _FakePicker extends PostImagePicker {
  _FakePicker(this.galleryCount);

  final int galleryCount;
  int? lastLimit;

  @override
  Future<List<XFile>> pickFromGallery({required int limit}) async {
    lastLimit = limit;
    return [for (var i = 0; i < galleryCount; i++) XFile('/fake/photo$i.png')];
  }

  @override
  Future<XFile?> pickFromCamera() async => XFile('/fake/camera.jpg');
}

class _RecordingUpload implements ImageUploadService {
  List<XFile>? uploaded;

  @override
  Future<List<String>> upload(List<XFile> images) async {
    uploaded = images;
    return [for (var i = 0; i < images.length; i++) '/static/images/u$i.png'];
  }
}

class _RecordingFeeds extends MockFeedRepository {
  FeedItem? created;
  Map<String, dynamic>? patched;

  @override
  Future<FeedItem> createPost(FeedItem item, {LocationItem? location}) async {
    created = item;
    return item;
  }

  @override
  Future<FeedItem> updateFeed(
    String id, {
    required String title,
    required String content,
    required Map<String, dynamic> extraMeta,
    required List<String> imageUrls,
  }) async {
    patched = {
      'id': id,
      'title': title,
      'content': content,
      'extra_meta': extraMeta,
      'image_urls': imageUrls,
    };
    return _editTarget.copyWith(
      title: title,
      description: content,
      extraMeta: extraMeta,
      imageUrls: [for (final url in imageUrls) resolveMediaUrl(url)],
      priceOrCondition: '12,000원',
    );
  }
}

final _editTarget = FeedItem(
  id: '77',
  title: '선풍기 판매',
  neighborhood: '청룡동',
  postedAt: DateTime(2026, 10, 18),
  priceOrCondition: '15,000원',
  thumbnailUrl: resolveMediaUrl('/static/images/a.png'),
  imageUrls: [
    resolveMediaUrl('/static/images/a.png'),
    resolveMediaUrl('/static/images/b.png'),
  ],
  likeCount: 3,
  chatCount: 1,
  category: FeedCategory.market,
  badges: const [FeedBadge.market],
  isBumped: false,
  description: '상태 좋아요',
  authorName: '판매자',
  authorId: '1',
  isFavorite: true,
  extraMeta: const {'price': 15000, 'is_free': false, 'can_negotiate': false},
);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('grid: gallery pick · 대표 badge · delete · make cover · max 10',
      (tester) async {
    final picker = _FakePicker(3);
    var images = <PostImage>[];
    Iterable<String> paths() =>
        images.map((e) => (e as LocalPostImage).file.path);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [postImagePickerProvider.overrideWithValue(picker)],
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => ImagePickerGrid(
                images: images,
                onChanged: (next) => setState(() => images = next),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('0/10'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('image-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('앨범에서 선택'));
    await tester.pumpAndSettle();

    expect(picker.lastLimit, 10);
    expect(paths(), [
      '/fake/photo0.png',
      '/fake/photo1.png',
      '/fake/photo2.png',
    ]);
    expect(find.text('3/10'), findsOneWidget);
    expect(find.text('대표'), findsOneWidget);

    // X on the first photo → next one becomes 대표.
    await tester.tap(find.byKey(const ValueKey('image-remove-0')));
    await tester.pumpAndSettle();
    expect(paths(), ['/fake/photo1.png', '/fake/photo2.png']);

    // Tap → "대표 사진으로 설정" moves it to the front.
    await tester.tap(find.byKey(const ValueKey('image-thumb-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('대표 사진으로 설정'));
    await tester.pumpAndSettle();
    expect(paths(), ['/fake/photo2.png', '/fake/photo1.png']);

    // Over-pick is clamped to 10.
    images = [
      for (var i = 0; i < 8; i++) LocalPostImage(XFile('/fake/x$i.png')),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [postImagePickerProvider.overrideWithValue(_FakePicker(5))],
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => ImagePickerGrid(
                images: images,
                onChanged: (next) => setState(() => images = next),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('image-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('앨범에서 선택'));
    await tester.pumpAndSettle();
    expect(images, hasLength(10));
  });

  testWidgets('real-estate form uploads photos then posts typed extra_meta',
      (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final upload = _RecordingUpload();
    final feeds = _RecordingFeeds();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('홈'))),
        GoRoute(
          path: '/create',
          builder: (_, _) => const RealEstateCreateScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postImagePickerProvider.overrideWithValue(_FakePicker(2)),
          imageUploadServiceProvider.overrideWithValue(upload),
          feedRepositoryProvider.overrideWithValue(feeds),
          tokenStorageProvider.overrideWithValue(TokenStorage()),
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/create');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('image-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('앨범에서 선택'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('post-title')), '정자동 원룸');
    await tester.enterText(find.byKey(const ValueKey('post-body')), '역세권');
    await tester.tap(find.text('투룸'));
    await tester.enterText(find.byKey(const ValueKey('field-deposit')), '500');
    await tester.enterText(
      find.byKey(const ValueKey('field-monthly-rent')),
      '50',
    );
    await tester.tap(find.byKey(const ValueKey('field-short-term')));
    await tester.pump();

    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    expect(upload.uploaded?.map((e) => e.path),
        ['/fake/photo0.png', '/fake/photo1.png']);
    final item = feeds.created!;
    expect(item.category, FeedCategory.housing);
    expect(item.imageUrls, ['/static/images/u0.png', '/static/images/u1.png']);
    expect(item.extraMeta, {
      'room_type': 'TWO_ROOM',
      'deposit': 500,
      'monthly_rent': 50,
      'is_short_term': true,
    });
    expect(item.priceOrCondition, '보증금 500 / 월세 50');
    expect(find.text('홈'), findsOneWidget);
  });

  testWidgets('general form: price → extra_meta; 나눔 sends price 0',
      (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    Future<_RecordingFeeds> submit({required bool free}) async {
      final feeds = _RecordingFeeds();
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('홈'))),
          GoRoute(
            path: '/create',
            builder: (_, _) => const GeneralCreateScreen(),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            imageUploadServiceProvider.overrideWithValue(_RecordingUpload()),
            feedRepositoryProvider.overrideWithValue(feeds),
            tokenStorageProvider.overrideWithValue(TokenStorage()),
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      router.push('/create');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('post-title')), '선풍기 판매');
      await tester.enterText(find.byKey(const ValueKey('post-body')), '상태 좋아요');
      if (free) {
        await tester.tap(find.byKey(const ValueKey('field-is-free')));
      } else {
        await tester.enterText(find.byKey(const ValueKey('field-price')), '15000');
        await tester.tap(find.byKey(const ValueKey('field-can-negotiate')));
      }
      await tester.pump();
      await tester.tap(find.text('완료'));
      await tester.pumpAndSettle();
      return feeds;
    }

    final paid = await submit(free: false);
    expect(paid.created!.extraMeta, {
      'price': 15000,
      'is_free': false,
      'can_negotiate': true,
    });
    expect(paid.created!.priceOrCondition, '15,000원');

    final free = await submit(free: true);
    expect(free.created!.extraMeta, {
      'price': 0,
      'is_free': true,
      'can_negotiate': false,
    });
    expect(free.created!.priceOrCondition, '나눔');
  });

  testWidgets('edit mode: prefill → keep/delete/add photos → PATCH → pop(item)',
      (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final upload = _RecordingUpload();
    final feeds = _RecordingFeeds();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('홈'))),
        GoRoute(
          path: '/edit',
          builder: (_, state) =>
              GeneralCreateScreen(targetFeed: state.extra as FeedItem?),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postImagePickerProvider.overrideWithValue(_FakePicker(1)),
          imageUploadServiceProvider.overrideWithValue(upload),
          feedRepositoryProvider.overrideWithValue(feeds),
          tokenStorageProvider.overrideWithValue(TokenStorage()),
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    final result = router.push<FeedItem>('/edit', extra: _editTarget);
    await tester.pumpAndSettle();

    expect(find.text('글 수정하기'), findsOneWidget);
    expect(find.text('수정 완료'), findsOneWidget);
    expect(find.text('선풍기 판매'), findsOneWidget);
    expect(find.text('상태 좋아요'), findsOneWidget);
    expect(find.text('15000'), findsOneWidget);
    expect(find.text('2/10'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('image-remove-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('image-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('앨범에서 선택'));
    await tester.pumpAndSettle();
    expect(find.text('2/10'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('post-title')),
      '선풍기 (가격 인하)',
    );
    await tester.enterText(find.byKey(const ValueKey('field-price')), '12000');
    await tester.tap(find.text('수정 완료'));
    await tester.pumpAndSettle();

    expect(upload.uploaded?.map((e) => e.path), ['/fake/photo0.png']);
    expect(feeds.created, isNull);
    expect(feeds.patched, {
      'id': '77',
      'title': '선풍기 (가격 인하)',
      'content': '상태 좋아요',
      'extra_meta': {'price': 12000, 'is_free': false, 'can_negotiate': false},
      'image_urls': ['/static/images/b.png', '/static/images/u0.png'],
    });
    final updated = await result;
    expect(updated?.title, '선풍기 (가격 인하)');
    expect(updated?.isFavorite, isTrue);
    expect(updated?.likeCount, 3);
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('게시글을 수정했어요.'), findsOneWidget);
  });

  test('edit submit refreshes the detail copy without uploading', () async {
    final upload = _RecordingUpload();
    final container = ProviderContainer(
      overrides: [
        imageUploadServiceProvider.overrideWithValue(upload),
        feedRepositoryProvider.overrideWithValue(_RecordingFeeds()),
        tokenStorageProvider.overrideWithValue(TokenStorage()),
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(createPostProvider.notifier).submit(
          CreatePostDraft(
            kind: CreatePostKind.general,
            title: '선풍기 (수정)',
            description: '상태 좋아요',
            images: [RemotePostImage(_editTarget.imageUrls.last)],
            extraMeta: const {'price': 12000, 'is_free': false},
          ),
          editing: _editTarget,
        );

    expect(upload.uploaded, isNull);
    final detail = container.read(feedItemProvider(_editTarget));
    expect(detail.title, '선풍기 (수정)');
    expect(detail.gallery, [_editTarget.imageUrls.last]);
    expect(container.read(feedMutationTickProvider), 1);
  });

  test('general without price (and not 나눔) is rejected', () {
    expect(
      validateExtraMeta(CreatePostKind.general, {'is_free': false}),
      contains('가격을 입력해 주세요'),
    );
    expect(
      validateExtraMeta(CreatePostKind.general, {'price': 0, 'is_free': true}),
      isNull,
    );
  });

  testWidgets('missing rent is rejected before any upload', (tester) async {
    final upload = _RecordingUpload();
    final router = GoRouter(
      initialLocation: '/create',
      routes: [
        GoRoute(
          path: '/create',
          builder: (_, _) => const RealEstateCreateScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          imageUploadServiceProvider.overrideWithValue(upload),
          feedRepositoryProvider.overrideWithValue(_RecordingFeeds()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('post-title')), '정자동 원룸');
    await tester.enterText(find.byKey(const ValueKey('post-body')), '역세권');
    await tester.enterText(find.byKey(const ValueKey('field-deposit')), '500');
    await tester.tap(find.text('완료'));
    await tester.pump();
    expect(find.text('월세를 입력해 주세요.'), findsOneWidget);
    expect(upload.uploaded, isNull);
  });
}
