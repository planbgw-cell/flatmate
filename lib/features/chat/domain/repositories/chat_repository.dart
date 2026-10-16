import '../../../feed/domain/models/feed_item.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';

/// Chat API contract — swap mock for WebSocket/FastAPI later.
abstract class ChatRepository {
  Future<List<ChatRoom>> getChatRooms();

  Future<ChatRoom?> getChatRoom(String roomId);

  Future<List<ChatMessage>> getMessages(String roomId);

  Future<ChatMessage> sendMessage(String roomId, String text);

  /// Create a room for [item] or return an existing one for the same feed.
  Future<ChatRoom> createOrGetRoom(FeedItem item);

  Future<void> markRoomRead(String roomId);
}
