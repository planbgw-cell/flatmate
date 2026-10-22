import 'dart:async';

import 'package:flatmate_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flatmate_app/features/feed/data/repositories/mock_feed_repository.dart';
import 'package:flatmate_app/features/feed/domain/models/feed_item.dart';
import 'package:flatmate_app/features/feed/domain/repositories/feed_repository.dart';
import 'package:flatmate_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:flatmate_app/features/feed/presentation/widgets/trade_status_badge.dart';
import 'package:flatmate_app/features/location/domain/models/location_item.dart';
import 'package:flatmate_app/features/mypage/presentation/providers/my_feeds_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

FeedItem _item(String id, {bool liked = false, int likes = 0}) => FeedItem(
      id: id,
      title: '글 $id',
      neighborhood: '정자동',
      postedAt: DateTime(2026, 10, 22),
      priceOrCondition: '15,000원',
      thumbnailUrl: '',
      likeCount: likes,
      chatCount: 0,
      category: FeedCategory.market,
      badges: const [],
      isBumped: false,
      isFavorite: liked,
    );

/// Like calls wait on [pending] so tests can observe the optimistic state.
class _ControlledRepo extends MockFeedRepository {
  Completer<LikeResult>? pending;
  final likeCalls = <(String, bool)>[];
  List<FeedItem> likes = const [];

  @override
  Future<List<FeedItem>> fetchFeeds({
    required int page,
    int pageSize = 10,
    String category = 'all',
    LocationItem? location,
    double radiusKm = 3,
    FeedSort sort = FeedSort.latest,
  }) async =>
      const [];

  @override
  Future<LikeResult> toggleLike(String id, {required bool currentlyLiked}) {
    likeCalls.add((id, currentlyLiked));
    pending = Completer<LikeResult>();
    return pending!.future;
  }

  @override
  Future<List<FeedItem>> getMyLikes({int page = 1}) async => likes;
}

void main() {
  late _ControlledRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _ControlledRepo();
    container = ProviderContainer(
      overrides: [
        feedRepositoryProvider.overrideWithValue(repo),
        currentUserIdProvider.overrideWithValue('7'),
      ],
    );
    addTearDown(container.dispose);
  });

  test('like flips optimistically, then adopts the server count', () async {
    final notifier = container.read(favoriteItemProvider('5').notifier);
    notifier.hydrate(_item('5', likes: 2));

    final future = notifier.toggle();
    final optimistic = container.read(favoriteItemProvider('5'));
    expect(optimistic.isFavorite, isTrue);
    expect(optimistic.likeCount, 3);
    expect(repo.likeCalls.single, ('5', false));

    repo.pending!.complete((isLiked: true, likeCount: 7));
    await future;
    final synced = container.read(favoriteItemProvider('5'));
    expect(synced.isFavorite, isTrue);
    expect(synced.likeCount, 7);
    expect(container.read(feedMutationTickProvider), 1);
  });

  test('failed like rolls back to the previous state', () async {
    final notifier = container.read(favoriteItemProvider('5').notifier);
    notifier.hydrate(_item('5', liked: true, likes: 4));

    final future = notifier.toggle();
    expect(container.read(favoriteItemProvider('5')).isFavorite, isFalse);
    expect(container.read(favoriteItemProvider('5')).likeCount, 3);

    repo.pending!.completeError(Exception('offline'));
    await expectLater(future, throwsException);
    final restored = container.read(favoriteItemProvider('5'));
    expect(restored.isFavorite, isTrue);
    expect(restored.likeCount, 4);
  });

  test('관심목록 unlike removes the row immediately', () async {
    repo.likes = [_item('1', liked: true, likes: 1), _item('2', liked: true)];
    expect(
      (await container.read(myLikesProvider.future)).map((e) => e.id),
      ['1', '2'],
    );

    final future = container
        .read(myLikesProvider.notifier)
        .unlike(repo.likes.first);
    expect(container.read(myLikesProvider).value!.map((e) => e.id), ['2']);
    expect(repo.likeCalls.single, ('1', true));

    repo.likes = [repo.likes.last];
    repo.pending!.complete((isLiked: false, likeCount: 0));
    await future;
    expect(container.read(favoriteItemProvider('1')).isFavorite, isFalse);
    expect(
      (await container.read(myLikesProvider.future)).map((e) => e.id),
      ['2'],
    );
  });

  testWidgets('trade badge hides 판매중 and labels the others',
      (tester) async {
    Future<void> pump(TradeStatus status) => tester.pumpWidget(
          MaterialApp(home: TradeStatusBadge(status: status)),
        );

    await pump(TradeStatus.selling);
    expect(find.text('판매중'), findsNothing);
    await pump(TradeStatus.reserved);
    expect(find.text('예약중'), findsOneWidget);
    await pump(TradeStatus.completed);
    expect(find.text('거래완료'), findsOneWidget);
  });
}
