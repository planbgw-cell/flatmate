class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.message,
    required this.createdAt,
    required this.isMine,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String message;
  final DateTime createdAt;
  final bool isMine;

  ChatMessage copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? message,
    DateTime? createdAt,
    bool? isMine,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isMine: isMine ?? this.isMine,
    );
  }
}
