import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_room.dart';
import '../../domain/repositories/chat_repository.dart';
import '../mappers/chat_mapper.dart';

/// FastAPI chat repository (`/chats/...`).
class DioChatRepository implements ChatRepository {
  DioChatRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<ChatRoom>> getChatRooms() async {
    final response = await _api.get<dynamic>('/chats/rooms');
    return _parseRooms(response.data);
  }

  @override
  Future<ChatRoom?> getChatRoom(String roomId) async {
    try {
      final response = await _api.get<dynamic>('/chats/rooms/$roomId');
      final data = response.data;
      if (data is Map<String, dynamic>) return chatRoomFromJson(data);
      if (data is Map) return chatRoomFromJson(Map<String, dynamic>.from(data));
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<List<ChatMessage>> getMessages(String roomId) async {
    final response =
        await _api.get<dynamic>('/chats/rooms/$roomId/messages');
    return _parseMessages(response.data);
  }

  @override
  Future<ChatMessage> sendMessage(String roomId, String text) async {
    final response = await _api.post<dynamic>(
      '/chats/rooms/$roomId/messages',
      data: chatMessageToJsonBody(text),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return chatMessageFromJson(data);
    if (data is Map) {
      return chatMessageFromJson(Map<String, dynamic>.from(data));
    }
    throw const ApiException(message: '메시지 전송 응답 형식이 올바르지 않습니다.');
  }

  @override
  Future<ChatRoom> createOrGetRoom(FeedItem item) async {
    final response = await _api.post<dynamic>(
      '/chats/rooms',
      data: {
        'feed_item_id': item.id,
        'feed_title': item.title,
        'feed_price': item.priceOrCondition,
        'feed_thumbnail': item.thumbnailUrl,
        'opponent_name': item.authorName,
        'opponent_neighborhood': item.neighborhood,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return chatRoomFromJson(data);
    if (data is Map) return chatRoomFromJson(Map<String, dynamic>.from(data));
    throw const ApiException(message: '채팅방 생성 응답 형식이 올바르지 않습니다.');
  }

  @override
  Future<void> markRoomRead(String roomId) async {
    await _api.post<dynamic>('/chats/rooms/$roomId/read');
  }

  List<ChatRoom> _parseRooms(dynamic data) {
    final raw = switch (data) {
      final List list => list,
      final Map map => map['items'] ?? map['results'] ?? map['data'] ?? const [],
      _ => const [],
    };
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => chatRoomFromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<ChatMessage> _parseMessages(dynamic data) {
    final raw = switch (data) {
      final List list => list,
      final Map map => map['items'] ?? map['results'] ?? map['data'] ?? const [],
      _ => const [],
    };
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => chatMessageFromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
