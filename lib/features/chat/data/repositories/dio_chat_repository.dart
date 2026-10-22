import '../../../../core/auth/token_refresher.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_room.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/chat_socket.dart';
import '../datasources/chat_websocket_client.dart';
import '../mappers/chat_mapper.dart';

/// FastAPI chat repository (`/chats/rooms…`, `/chats/ws/{room_id}`).
class DioChatRepository implements ChatRepository {
  DioChatRepository(this._api, this._tokens, this._refresher);

  final ApiClient _api;
  final TokenStorage _tokens;
  final TokenRefresher _refresher;

  final Map<String, ChatRoom> _rooms = {};

  String? get _me => _tokens.userId;

  /// One request: `ChatRoomOut` already carries peer, last message, unread
  /// count and the linked feed's title / thumbnail.
  @override
  Future<List<ChatRoom>> getChatRooms() async {
    final response = await _api.get<dynamic>('/chats/rooms');
    final raw = response.data is List ? response.data as List : const [];
    final rooms = raw
        .whereType<Map>()
        .map((e) => _toRoom(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return rooms;
  }

  @override
  Future<ChatRoom?> getChatRoom(String roomId) async {
    final cached = _rooms[roomId];
    if (cached != null) return cached;
    final rooms = await getChatRooms();
    return rooms.where((r) => r.id == roomId).firstOrNull;
  }

  @override
  Future<List<ChatMessage>> getMessages(String roomId) async {
    final response = await _api.get<dynamic>(
      '/chats/rooms/$roomId/messages',
      queryParameters: {'limit': 200},
    );
    final data = response.data;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map(
          (e) => chatMessageFromJson(
            Map<String, dynamic>.from(e),
            myUserId: _me,
          ),
        )
        .toList();
  }

  @override
  Future<ChatMessage> sendMessage(String roomId, String text) async {
    final response = await _api.post<dynamic>(
      '/chats/rooms/$roomId/messages',
      data: chatMessageToJsonBody(text),
    );
    final data = response.data;
    if (data is! Map) {
      throw const ApiException(message: '메시지 전송 응답 형식이 올바르지 않습니다.');
    }
    return chatMessageFromJson(Map<String, dynamic>.from(data), myUserId: _me);
  }

  @override
  Future<ChatRoom> createOrGetRoom(FeedItem item) async {
    final peerId = int.tryParse(item.authorId ?? '');
    if (peerId == null) {
      throw const ApiException(
        message: '작성자 정보가 없는 게시글이라 채팅을 시작할 수 없어요.',
      );
    }
    if (item.authorId == _me) {
      throw const ApiException(message: '내가 쓴 글에는 채팅을 시작할 수 없어요.');
    }
    final feedId = int.tryParse(item.id);
    final response = await _api.post<dynamic>(
      '/chats/rooms',
      data: {'peer_id': peerId, 'feed_id': ?feedId},
    );
    final data = response.data;
    if (data is! Map) {
      throw const ApiException(message: '채팅방 생성 응답 형식이 올바르지 않습니다.');
    }
    // The detail screen already has the price (not part of ChatRoomOut).
    return _toRoom(Map<String, dynamic>.from(data), feed: item);
  }

  @override
  Future<void> markRoomRead(String roomId) async {
    await _api.post<dynamic>('/chats/rooms/$roomId/read');
  }

  @override
  ChatSocket openSocket(String roomId) {
    return ChatWebSocketClient(
      roomId: roomId,
      apiBaseUrl: _api.config.apiBaseUrl,
      tokens: _tokens,
      refresher: _refresher,
    );
  }

  ChatRoom _toRoom(Map<String, dynamic> json, {FeedItem? feed}) {
    final room = chatRoomFromJson(json, feed: feed);
    _rooms[room.id] = room;
    return room;
  }
}
