import '../../../../core/auth/token_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../../../feed/domain/repositories/feed_repository.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_room.dart';
import '../../domain/repositories/chat_repository.dart';
import '../mappers/chat_mapper.dart';

/// FastAPI chat repository (`/chats/rooms`, `/chats/rooms/{id}/messages`).
class DioChatRepository implements ChatRepository {
  DioChatRepository(this._api, this._tokens, this._feeds);

  final ApiClient _api;
  final TokenStorage _tokens;
  final FeedRepository _feeds;

  final Map<String, ChatRoom> _rooms = {};

  String? get _me => _tokens.userId;

  @override
  Future<List<ChatRoom>> getChatRooms() async {
    final response = await _api.get<dynamic>('/chats/rooms');
    final raw = response.data is List ? response.data as List : const [];
    final rooms = await Future.wait(
      raw.whereType<Map>().map((e) => _hydrate(Map<String, dynamic>.from(e))),
    );
    rooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
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
    return _parseMessages(response.data);
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
    final sent = chatMessageFromJson(
      Map<String, dynamic>.from(data),
      myUserId: _me,
    );
    final room = _rooms[roomId];
    if (room != null) {
      _rooms[roomId] = room.copyWith(
        lastMessage: sent.message,
        lastMessageTime: sent.createdAt,
      );
    }
    return sent;
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
    return _hydrate(Map<String, dynamic>.from(data), feed: item);
  }

  /// Read receipts are not exposed by the API yet.
  @override
  Future<void> markRoomRead(String roomId) async {}

  Future<ChatRoom> _hydrate(Map<String, dynamic> json, {FeedItem? feed}) async {
    final roomId = json['id']?.toString() ?? '';
    final feedId = json['feed_id']?.toString();
    final results = await Future.wait<Object?>([
      if (feed == null && feedId != null)
        _feeds.fetchById(feedId).catchError((_) => null)
      else
        Future.value(feed),
      _lastMessage(roomId),
    ]);
    final room = chatRoomFromJson(
      json,
      myUserId: _me,
      feed: results[0] as FeedItem?,
      lastMessage: results[1] as ChatMessage?,
    );
    _rooms[room.id] = room;
    return room;
  }

  Future<ChatMessage?> _lastMessage(String roomId) async {
    try {
      final response = await _api.get<dynamic>(
        '/chats/rooms/$roomId/messages',
        queryParameters: {'limit': 1},
      );
      final list = _parseMessages(response.data);
      return list.isEmpty ? null : list.last;
    } on ApiException {
      return null;
    }
  }

  List<ChatMessage> _parseMessages(dynamic data) {
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
}
