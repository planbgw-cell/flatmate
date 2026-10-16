import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_room.dart';

ChatRoom chatRoomFromJson(Map<String, dynamic> json) {
  return ChatRoom(
    id: json['id']?.toString() ?? '',
    feedItemId: json['feed_item_id']?.toString() ??
        json['feedItemId']?.toString() ??
        '',
    feedTitle: json['feed_title']?.toString() ??
        json['feedTitle']?.toString() ??
        '',
    feedPrice: json['feed_price']?.toString() ??
        json['feedPrice']?.toString() ??
        '',
    feedThumbnail: json['feed_thumbnail']?.toString() ??
        json['feedThumbnail']?.toString() ??
        '',
    opponentName: json['opponent_name']?.toString() ??
        json['opponentName']?.toString() ??
        '',
    opponentProfileImage: json['opponent_profile_image']?.toString() ??
        json['opponentProfileImage']?.toString(),
    opponentNeighborhood: json['opponent_neighborhood']?.toString() ??
        json['opponentNeighborhood']?.toString() ??
        '',
    lastMessage: json['last_message']?.toString() ??
        json['lastMessage']?.toString() ??
        '',
    lastMessageTime: DateTime.tryParse(
          json['last_message_time']?.toString() ??
              json['lastMessageTime']?.toString() ??
              '',
        ) ??
        DateTime.now(),
    unreadCount: (json['unread_count'] as num?)?.toInt() ??
        (json['unreadCount'] as num?)?.toInt() ??
        0,
    dealStatus: json['deal_status']?.toString() ??
        json['dealStatus']?.toString() ??
        '거래가능',
  );
}

ChatMessage chatMessageFromJson(Map<String, dynamic> json) {
  return ChatMessage(
    id: json['id']?.toString() ?? '',
    roomId: json['room_id']?.toString() ?? json['roomId']?.toString() ?? '',
    senderId:
        json['sender_id']?.toString() ?? json['senderId']?.toString() ?? '',
    message: json['message']?.toString() ?? json['text']?.toString() ?? '',
    createdAt: DateTime.tryParse(
          json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '',
        ) ??
        DateTime.now(),
    isMine: json['is_mine'] as bool? ?? json['isMine'] as bool? ?? false,
  );
}

Map<String, dynamic> chatMessageToJsonBody(String text) => {'message': text};
