import '../../../feed/domain/models/feed_item.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import 'chat_socket.dart';

/// Chat API contract (REST history + optional realtime socket).
abstract class ChatRepository {
  Future<List<ChatRoom>> getChatRooms();

  Future<ChatRoom?> getChatRoom(String roomId);

  Future<List<ChatMessage>> getMessages(String roomId);

  Future<ChatMessage> sendMessage(String roomId, String text);

  /// Create a room for [item] or return an existing one for the same feed.
  Future<ChatRoom> createOrGetRoom(FeedItem item);

  Future<void> markRoomRead(String roomId);

  /// Realtime channel for [roomId]; `null` when the backend has none (mock).
  ChatSocket? openSocket(String roomId);
}
