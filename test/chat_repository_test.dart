import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flatmate_app/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:flatmate_app/features/feed/domain/models/feed_item.dart';

void main() {
  test('createOrGetRoom and sendMessage update room list', () async {
    final repo = MockChatRepository(random: Random(1));
    final roomsBefore = await repo.getChatRooms();
    expect(roomsBefore.length, greaterThanOrEqualTo(3));

    final created = await repo.createOrGetRoom(
      FeedItem(
        id: 'f-chat-new',
        title: '채팅 테스트 매물',
        neighborhood: '신촌동',
        postedAt: DateTime.now(),
        priceOrCondition: '보증금 100 / 월세 40',
        thumbnailUrl: 'https://picsum.photos/seed/c/100/100',
        likeCount: 0,
        chatCount: 0,
        category: FeedCategory.housing,
        badges: const [FeedBadge.housing],
        isBumped: false,
        authorName: '테스트이웃',
      ),
    );

    expect(created.feedItemId, 'f-chat-new');
    final again = await repo.createOrGetRoom(
      FeedItem(
        id: 'f-chat-new',
        title: '채팅 테스트 매물',
        neighborhood: '신촌동',
        postedAt: DateTime.now(),
        priceOrCondition: '보증금 100 / 월세 40',
        thumbnailUrl: 'https://picsum.photos/seed/c/100/100',
        likeCount: 0,
        chatCount: 0,
        category: FeedCategory.housing,
        badges: const [FeedBadge.housing],
        isBumped: false,
        authorName: '테스트이웃',
      ),
    );
    expect(again.id, created.id);

    final sent = await repo.sendMessage(created.id, '안녕하세요 문의드립니다');
    expect(sent.isMine, isTrue);
    expect(sent.message, '안녕하세요 문의드립니다');

    final messages = await repo.getMessages(created.id);
    expect(messages.last.message, '안녕하세요 문의드립니다');

    final rooms = await repo.getChatRooms();
    expect(rooms.first.id, created.id);
    expect(rooms.first.lastMessage, '안녕하세요 문의드립니다');
  });
}
