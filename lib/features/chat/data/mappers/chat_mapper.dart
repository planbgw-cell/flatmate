import '../../../../core/network/media_url.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_room.dart';

/// `ChatRoomOut` → [ChatRoom], including the linked feed's title, thumbnail
/// and `feed_price_text`. [feed] is only a fallback for rooms opened from a
/// detail screen before the server fills those fields.
ChatRoom chatRoomFromJson(Map<String, dynamic> json, {FeedItem? feed}) {
  final createdAt =
      DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now();
  final lastAt = DateTime.tryParse(json['last_message_at']?.toString() ?? '');
  final thumbnail = resolveMediaUrl(json['feed_thumbnail']?.toString());

  return ChatRoom(
    id: json['id']?.toString() ?? '',
    feedItemId: json['feed_id']?.toString() ?? '',
    feedTitle: json['feed_title']?.toString() ?? feed?.title ?? '이웃과의 대화',
    feedPrice: json['feed_price_text']?.toString() ?? feed?.priceOrCondition ?? '',
    feedThumbnail: thumbnail.isNotEmpty ? thumbnail : feed?.thumbnailUrl ?? '',
    opponentName: json['peer_nickname']?.toString() ?? '이웃',
    opponentProfileImage: json['peer_profile_image']?.toString(),
    opponentNeighborhood: feed?.neighborhood ?? '',
    lastMessage: json['last_message']?.toString() ?? '',
    lastMessageTime: (lastAt ?? createdAt).toLocal(),
    unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
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
    isRead: json['is_read'] as bool? ?? json['read_at'] != null,
  );
}

Map<String, dynamic> chatMessageToJsonBody(String text) => {'content': text};
