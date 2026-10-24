import 'package:flatmate_app/app/routes/route_names.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/core/common_widgets/custom_bottom_navigation_bar.dart';
import 'package:flatmate_app/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:flatmate_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flatmate_app/features/block_report/data/mock_block_report_repository.dart';
import 'package:flatmate_app/features/block_report/presentation/providers/blocked_users_provider.dart';
import 'package:flatmate_app/features/community/presentation/screens/community_screen.dart';
import 'package:flatmate_app/features/feed/data/mappers/feed_item_mapper.dart';
import 'package:flatmate_app/features/feed/data/repositories/mock_feed_repository.dart';
import 'package:flatmate_app/features/feed/domain/models/feed_item.dart';
import 'package:flatmate_app/features/feed/domain/repositories/feed_repository.dart';
import 'package:flatmate_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:flatmate_app/features/location/domain/models/location_item.dart';
import 'package:flatmate_app/features/location/presentation/providers/location_provider.dart';
import 'package:flatmate_app/features/main_navigation/presentation/main_navigation_screen.dart';
import 'package:flatmate_app/features/map_around/domain/map_feed_group.dart';
import 'package:flatmate_app/features/map_around/presentation/providers/map_around_provider.dart';
import 'package:flatmate_app/features/map_around/presentation/screens/map_around_screen.dart';
import 'package:flatmate_app/features/post_create/presentation/providers/create_post_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

FeedItem _item(
  String id, {
  double? lat,
  double? lng,
  String author = '21',
  String neighborhood = '야탑동',
  FeedCategory category = FeedCategory.market,
  String price = '15,000원',
}) =>
    FeedItem(
      id: id,
      title: '글 $id',
      neighborhood: neighborhood,
      postedAt: DateTime(2026, 10, 24),
      priceOrCondition: price,
      thumbnailUrl: '',
      likeCount: 0,
      chatCount: 0,
      category: category,
      badges: const [],
      isBumped: false,
      authorId: author,
      latitude: lat,
      longitude: lng,
    );

/// Records `fetchFeeds` calls; answers per category.
class _Feeds extends MockFeedRepository {
  _Feeds({this.around = const []});

  List<FeedItem> around;
  List<FeedItem> community = const [];
  final calls = <({String category, LocationItem? location, double radiusKm, int pageSize})>[];
  FeedItem? created;

  @override
  Future<List<FeedItem>> fetchFeeds({
    required int page,
    int pageSize = 10,
    String category = 'all',
    LocationItem? location,
    double radiusKm = 3,
    FeedSort sort = FeedSort.latest,
  }) async {
    calls.add((
      category: category,
      location: location,
      radiusKm: radiusKm,
      pageSize: pageSize,
    ));
    if (page > 1) return const [];
    return category == FeedCategory.community.name ? community : around;
  }

  @override
  Future<FeedItem> createPost(FeedItem item, {LocationItem? location}) async {
    created = item;
    return item;
  }
}

const _yatap = LocationItem(
  id: '15',
  cityName: '성남시',
  districtName: '분당구',
  dongName: '야탑1동',
  latitude: 37.41205,
  longitude: 127.13027,
);

List<Override> _overrides(_Feeds feeds, {String? userId}) => [
      feedRepositoryProvider.overrideWithValue(feeds),
      currentUserIdProvider.overrideWithValue(userId),
      mapTilesEnabledProvider.overrideWithValue(false),
    ];

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('map grouping', () {
    test('FeedOut lat / lng map onto FeedItem', () {
      final item = feedItemFromJson({
        'id': 9,
        'feed_type': 'GENERAL',
        'title': '책상',
        'lat': 37.41205313694714,
        'lng': 127.13027133504737,
        'published_at': '2026-10-24T00:00:00Z',
      });
      expect(item.latitude, closeTo(37.41205, 1e-5));
      expect(item.longitude, closeTo(127.13027, 1e-5));
      expect(feedItemFromJson({'id': 1, 'title': 'x'}).latitude, isNull);
    });

    test('same position → one group; mock posts fall back to the dong', () {
      final groups = groupFeedsByPosition([
        _item('1', lat: 37.412053, lng: 127.130271),
        _item('2', lat: 37.4120531, lng: 127.1302712),
        _item('3', lat: 37.4150, lng: 127.1330),
        _item('4', neighborhood: '정자동'),
        _item('5', neighborhood: '어딘가동'),
      ]);
      expect(groups.map((g) => g.id), ['1', '3', '4']);
      expect(groups.first.items.map((e) => e.id), ['1', '2']);
      final jeongja = locationForNeighborhood('정자동')!;
      expect(groups.last.latitude, jeongja.latitude);
    });

    test('marker label: short price or the category name', () {
      expect(markerLabel(_item('1')), '15,000원');
      expect(markerLabel(_item('1', price: '보증금 1,000 / 월세 50')), '보증금 1,00…');
      expect(
        markerLabel(_item('1', price: '', category: FeedCategory.community)),
        '동네 소식',
      );
    });
  });

  group('mapAroundProvider', () {
    test('loads 3 km around the dong; searchAt / select / blocked', () async {
      final feeds = _Feeds(around: [
        _item('1', lat: 37.41205, lng: 127.13027),
        _item('2', lat: 37.41205, lng: 127.13027),
        _item('3', lat: 37.415, lng: 127.133, author: '99'),
        _item('4', lat: 37.410, lng: 127.128),
      ]);
      final blocks = MockBlockReportRepository();
      await blocks.blockUser('99');
      final container = ProviderContainer(
        overrides: [
          ..._overrides(feeds, userId: '7'),
          blockReportRepositoryProvider.overrideWithValue(blocks),
        ],
      );
      addTearDown(container.dispose);
      container.read(currentLocationProvider.notifier).state = _yatap;

      var state = await container.read(mapAroundProvider.future);
      final call = feeds.calls.single;
      expect(call.location?.latitude, _yatap.latitude);
      expect(call.location?.longitude, _yatap.longitude);
      expect(call.radiusKm, 3);
      expect(call.pageSize, 100);
      expect(call.category, 'all');
      expect(state.items.map((e) => e.id), ['1', '2', '4'], reason: '99 blocked');
      expect(state.groups.map((g) => g.id), ['1', '4']);
      expect(state.selectedId, '1');

      final notifier = container.read(mapAroundProvider.notifier);
      notifier.select(state.groups.last);
      state = container.read(mapAroundProvider).value!;
      expect(state.items.map((e) => e.id), ['4', '1', '2']);
      expect(state.selectedId, '4');
      expect(state.selectedGroup?.id, '4');

      notifier.selectFeed('2');
      expect(container.read(mapAroundProvider).value!.selectedGroup?.id, '1');

      await notifier.searchAt(37.40, 127.12);
      state = container.read(mapAroundProvider).value!;
      expect(feeds.calls.last.location?.latitude, 37.40);
      expect(feeds.calls.last.location?.longitude, 127.12);
      expect(state.centerLat, 37.40);
    });
  });

  test('동네소식 post: LOCAL_NEWS with an empty extra_meta', () async {
    final feeds = _Feeds();
    final container = ProviderContainer(
      overrides: [
        ..._overrides(feeds),
        tokenStorageProvider.overrideWithValue(TokenStorage()),
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(createPostProvider.notifier).submit(
          const CreatePostDraft(
            kind: CreatePostKind.community,
            title: '야탑역 앞 붕어빵 트럭',
            description: '오늘부터 저녁 6시에 와요.',
          ),
        );
    final item = feeds.created!;
    expect(item.category, FeedCategory.community);
    final body = feedCreateToJson(item, location: _yatap);
    expect(body['feed_type'], 'LOCAL_NEWS');
    expect(body['extra_meta'], isEmpty);
    expect(container.read(feedMutationTickProvider), 1);
  });

  testWidgets('bottom tabs: 5 labels; FAB only on 홈 / 동네소식', (tester) async {
    String? pushed;
    Widget page(String name) => Scaffold(body: Text('page-$name'));
    final router = GoRouter(
      initialLocation: RouteNames.home,
      routes: [
        GoRoute(
          path: RouteNames.postCreateCommunity,
          builder: (_, _) {
            pushed = RouteNames.postCreateCommunity;
            return page('community-form');
          },
        ),
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => MainNavigationScreen(navigationShell: shell),
          branches: [
            for (final path in [
              RouteNames.home,
              RouteNames.community,
              RouteNames.around,
              RouteNames.chat,
              RouteNames.myPage,
            ])
              StatefulShellBranch(
                routes: [GoRoute(path: path, builder: (_, _) => page(path))],
              ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(
      CustomBottomNavigationBar.items.map((e) => e.label),
      ['홈', '동네소식', '내주변', '채팅', '마이플랫'],
    );
    for (final label in ['홈', '동네소식', '내주변', '채팅', '마이플랫']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('write-fab')), findsOneWidget);

    final expectations = {
      'tab-around': (RouteNames.around, false),
      'tab-chat': (RouteNames.chat, false),
      'tab-my': (RouteNames.myPage, false),
      'tab-community': (RouteNames.community, true),
    };
    for (final MapEntry(key: key, value: (path, fab)) in expectations.entries) {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
      expect(find.text('page-$path'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('write-fab')),
        fab ? findsOneWidget : findsNothing,
        reason: key,
      );
    }

    // 동네소식 FAB opens the 동네소식 form directly (no compose sheet).
    await tester.tap(find.byKey(const ValueKey('write-fab')));
    await tester.pumpAndSettle();
    expect(pushed, RouteNames.postCreateCommunity);
    expect(find.text('page-community-form'), findsOneWidget);
  });

  Future<void> pumpMap(WidgetTester tester, _Feeds feeds) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: RouteNames.around,
      routes: [
        GoRoute(
          path: RouteNames.around,
          builder: (_, _) => const MapAroundScreen(),
        ),
        GoRoute(
          path: RouteNames.feedDetail,
          builder: (_, state) =>
              Scaffold(body: Text('detail ${(state.extra! as FeedItem).id}')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._overrides(feeds),
          currentLocationProvider.overrideWith((ref) => _yatap),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('map: marker tap puts its card first (selected) → detail',
      (tester) async {
    await pumpMap(
      tester,
      _Feeds(around: [
        _item('1', lat: 37.41205, lng: 127.13027),
        _item('2', lat: 37.41205, lng: 127.13027),
        _item('3', lat: 37.4135, lng: 127.1320, price: '9,000원'),
      ]),
    );

    expect(find.text('내주변 · 야탑1동'), findsOneWidget);
    expect(find.byKey(const ValueKey('map-marker-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-marker-3')), findsOneWidget);
    expect(find.text('2건'), findsOneWidget);
    expect(find.text('9,000원'), findsWidgets);
    expect(find.byKey(const ValueKey('map-card-1')), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('map-marker-3')),
        matching: find.text('9,000원'),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MapAroundScreen)),
    );
    final state = container.read(mapAroundProvider).value!;
    expect(state.items.first.id, '3');
    expect(state.selectedId, '3');
    final card = find.byKey(const ValueKey('map-card-3'));
    expect(card, findsOneWidget);
    expect(
      tester.getCenter(card).dx,
      closeTo(tester.getCenter(find.byType(MapAroundScreen)).dx, 40),
    );

    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.text('detail 3'), findsOneWidget);
  });

  testWidgets('map: no posts → empty card', (tester) async {
    await pumpMap(tester, _Feeds());
    expect(find.text('주변 3km 안에 게시글이 없어요.'), findsOneWidget);
    expect(find.byKey(const ValueKey('map-recenter')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-research')), findsNothing);
  });

  testWidgets('동네소식 list: empty notice, then cards', (tester) async {
    final feeds = _Feeds();
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(feeds),
        child: const MaterialApp(home: CommunityScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(feeds.calls.single.category, 'community');
    expect(find.byKey(const ValueKey('community-empty')), findsOneWidget);

    feeds.community = [
      _item('8', category: FeedCategory.community, price: ''),
    ];
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CommunityScreen)),
    );
    container.read(feedMutationTickProvider.notifier).state++;
    await tester.pumpAndSettle();
    expect(find.text('글 8'), findsOneWidget);
    expect(find.byKey(const ValueKey('feed-price-8')), findsNothing);
  });
}
