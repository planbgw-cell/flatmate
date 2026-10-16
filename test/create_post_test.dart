import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flatmate_app/features/feed/data/repositories/mock_feed_repository.dart';
import 'package:flatmate_app/features/feed/domain/models/feed_item.dart';
import 'package:flatmate_app/features/location/domain/models/location_item.dart';

void main() {
  test('createPost inserts new item at top of feed', () async {
    final repo = MockFeedRepository(random: Random(1));
    final created = await repo.createPost(
      FeedItem(
        id: 'f-test-create',
        title: '테스트 원룸 등록글',
        neighborhood: kDefaultLocation.dongName,
        postedAt: DateTime.now(),
        priceOrCondition: '보증금 100 / 월세 40',
        thumbnailUrl: 'https://picsum.photos/seed/t/100/100',
        likeCount: 0,
        chatCount: 0,
        category: FeedCategory.housing,
        badges: const [FeedBadge.housing],
        isBumped: false,
        description: '테스트 본문입니다.',
      ),
    );

    expect(created.id, 'f-test-create');

    final page = await repo.fetchFeeds(
      page: 1,
      pageSize: 10,
      category: 'all',
      location: kDefaultLocation,
      radiusKm: 10,
    );

    expect(page, isNotEmpty);
    expect(page.first.id, 'f-test-create');
    expect(page.first.title, '테스트 원룸 등록글');
  });
}
