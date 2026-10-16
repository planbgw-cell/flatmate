class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.feedItemId,
    required this.feedTitle,
    required this.feedPrice,
    required this.feedThumbnail,
    required this.opponentName,
    this.opponentProfileImage,
    this.opponentNeighborhood = '',
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.dealStatus = '거래가능',
  });

  final String id;
  final String feedItemId;
  final String feedTitle;
  final String feedPrice;
  final String feedThumbnail;
  final String opponentName;
  final String? opponentProfileImage;
  final String opponentNeighborhood;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String dealStatus;

  ChatRoom copyWith({
    String? id,
    String? feedItemId,
    String? feedTitle,
    String? feedPrice,
    String? feedThumbnail,
    String? opponentName,
    String? opponentProfileImage,
    String? opponentNeighborhood,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    String? dealStatus,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      feedItemId: feedItemId ?? this.feedItemId,
      feedTitle: feedTitle ?? this.feedTitle,
      feedPrice: feedPrice ?? this.feedPrice,
      feedThumbnail: feedThumbnail ?? this.feedThumbnail,
      opponentName: opponentName ?? this.opponentName,
      opponentProfileImage: opponentProfileImage ?? this.opponentProfileImage,
      opponentNeighborhood: opponentNeighborhood ?? this.opponentNeighborhood,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      dealStatus: dealStatus ?? this.dealStatus,
    );
  }
}
