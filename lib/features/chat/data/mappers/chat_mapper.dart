import '../../../feed/domain/models/feed_item.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_room.dart';

/// `ChatRoomOut` (+ feed / last message lookups) → [ChatRoom].
///
/// The API only returns participant ids, so the product header comes from the
/// linked feed and the opponent nickname from the feed author when it matches.
ChatRoom chatRoomFromJson(
  Map<String, dynamic> json, {
  String? myUserId,
  FeedItem? feed,
  ChatMessage? lastMessage,
}) {
  final userA = json['user_a_id']?.toString() ?? '';
  final userB = json['user_b_id']?.toString() ?? '';
  final peerId = userA == myUserId ? userB : userA;
  final createdAt =
      DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now();
  final lastAt = DateTime.tryParse(json['last_message_at']?.toString() ?? '');

  return ChatRoom(
    id: json['id']?.toString() ?? '',
    feedItemId: json['feed_id']?.toString() ?? '',
    feedTitle: feed?.title ?? '이웃과의 대화',
    feedPrice: feed?.priceOrCondition ?? '',
    feedThumbnail: feed?.thumbnailUrl ?? '',
    opponentName: feed != null && feed.authorId == peerId
        ? feed.authorName
        : '이웃 $peerId',
    opponentNeighborhood: feed?.neighborhood ?? '',
    lastMessage: lastMessage?.message ?? '',
    lastMessageTime: (lastMessage?.createdAt ?? lastAt ?? createdAt).toLocal(),
    dealStatus: switch (feed?.category) {
      FeedCategory.job => '모집중',
      FeedCategory.market => '판매중',
      _ => '거래가능',
    },
  );
}

/// `ChatMessageOut` → [ChatMessage]; `isMine` compares against the JWT user.
ChatMessage chatMessageFromJson(
  Map<String, dynamic> json, {
  String? myUserId,
}) {
  final senderId = json['sender_id']?.toString() ?? '';
  return ChatMessage(
    id: json['id']?.toString() ?? '',
    roomId: json['room_id']?.toString() ?? '',
    senderId: senderId,
    message: json['content']?.toString() ?? '',
    createdAt:
        (DateTime.tryParse(json['created_at']?.toString() ?? '') ??
                DateTime.now())
            .toLocal(),
    isMine: myUserId != null && senderId == myUserId,
  );
}

Map<String, dynamic> chatMessageToJsonBody(String text) => {'content': text};
