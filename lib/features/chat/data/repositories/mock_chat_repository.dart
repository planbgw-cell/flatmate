import 'dart:math';

import '../../../feed/domain/models/feed_item.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_room.dart';
import '../../domain/repositories/chat_repository.dart';

class MockChatRepository implements ChatRepository {
  MockChatRepository({Random? random}) : _random = random ?? Random() {
    _seed();
  }

  final Random _random;
  final Map<String, ChatRoom> _rooms = {};
  final Map<String, List<ChatMessage>> _messages = {};

  Future<void> _delay() {
    final ms = 200 + _random.nextInt(201);
    return Future<void>.delayed(Duration(milliseconds: ms));
  }

  void _seed() {
    final now = DateTime.now();
    final rooms = [
      ChatRoom(
        id: 'room-101',
        feedItemId: 'f-101',
        feedTitle: '신촌 풀옵션 원룸 · 보증금 협의 가능',
        feedPrice: '보증금 500 / 월세 62',
        feedThumbnail: 'https://picsum.photos/seed/flatmate101/200/200',
        opponentName: '신촌이웃',
        opponentNeighborhood: '신촌동',
        lastMessage: '네, 내일 오전에 가능해요!',
        lastMessageTime: now.subtract(const Duration(minutes: 12)),
        unreadCount: 2,
        dealStatus: '거래가능',
      ),
      ChatRoom(
        id: 'room-103',
        feedItemId: 'f-103',
        feedTitle: '건대 카페 주말 오픈 알바 급구',
        feedPrice: '시급 11,000원',
        feedThumbnail: 'https://picsum.photos/seed/flatmate103/200/200',
        opponentName: '화양카페',
        opponentNeighborhood: '화양동',
        lastMessage: '지원서 확인했습니다. 면접 일정 조율할까요?',
        lastMessageTime: now.subtract(const Duration(hours: 2)),
        unreadCount: 0,
        dealStatus: '모집중',
      ),
      ChatRoom(
        id: 'room-107',
        feedItemId: 'f-107',
        feedTitle: '신촌 책상+의자 세트 처분',
        feedPrice: '40,000원',
        feedThumbnail: 'https://picsum.photos/seed/flatmate107/200/200',
        opponentName: '창천동러',
        opponentNeighborhood: '창천동',
        lastMessage: '직거래만 가능해요 🙏',
        lastMessageTime: now.subtract(const Duration(days: 1)),
        unreadCount: 1,
        dealStatus: '판매중',
      ),
      ChatRoom(
        id: 'room-109',
        feedItemId: 'f-109',
        feedTitle: '정자동 미니 선풍기 나눔합니다',
        feedPrice: '나눔',
        feedThumbnail: 'https://picsum.photos/seed/flatmate109/200/200',
        opponentName: '정자이웃',
        opponentNeighborhood: '정자동',
        lastMessage: '오늘 저녁 7시 이후 가능해요',
        lastMessageTime: now.subtract(const Duration(days: 2)),
        unreadCount: 0,
        dealStatus: '나눔중',
      ),
    ];

    for (final room in rooms) {
      _rooms[room.id] = room;
    }

    _messages['room-101'] = [
      ChatMessage(
        id: 'm-101-1',
        roomId: 'room-101',
        senderId: 'me',
        message: '안녕하세요, 원룸 아직 있나요?',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 20)),
        isMine: true,
      ),
      ChatMessage(
        id: 'm-101-2',
        roomId: 'room-101',
        senderId: 'opponent',
        message: '네 아직 있어요! 언제 보실 수 있으세요?',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 5)),
        isMine: false,
      ),
      ChatMessage(
        id: 'm-101-3',
        roomId: 'room-101',
        senderId: 'me',
        message: '내일 오전 괜찮으실까요?',
        createdAt: now.subtract(const Duration(minutes: 30)),
        isMine: true,
      ),
      ChatMessage(
        id: 'm-101-4',
        roomId: 'room-101',
        senderId: 'opponent',
        message: '네, 내일 오전에 가능해요!',
        createdAt: now.subtract(const Duration(minutes: 12)),
        isMine: false,
      ),
    ];

    _messages['room-103'] = [
      ChatMessage(
        id: 'm-103-1',
        roomId: 'room-103',
        senderId: 'me',
        message: '주말 오픈 알바 지원합니다!',
        createdAt: now.subtract(const Duration(hours: 3)),
        isMine: true,
      ),
      ChatMessage(
        id: 'm-103-2',
        roomId: 'room-103',
        senderId: 'opponent',
        message: '지원서 확인했습니다. 면접 일정 조율할까요?',
        createdAt: now.subtract(const Duration(hours: 2)),
        isMine: false,
      ),
    ];

    _messages['room-107'] = [
      ChatMessage(
        id: 'm-107-1',
        roomId: 'room-107',
        senderId: 'opponent',
        message: '직거래만 가능해요 🙏',
        createdAt: now.subtract(const Duration(days: 1)),
        isMine: false,
      ),
    ];

    _messages['room-109'] = [
      ChatMessage(
        id: 'm-109-1',
        roomId: 'room-109',
        senderId: 'me',
        message: '나눔 받고 싶어요!',
        createdAt: now.subtract(const Duration(days: 2, hours: 1)),
        isMine: true,
      ),
      ChatMessage(
        id: 'm-109-2',
        roomId: 'room-109',
        senderId: 'opponent',
        message: '오늘 저녁 7시 이후 가능해요',
        createdAt: now.subtract(const Duration(days: 2)),
        isMine: false,
      ),
    ];
  }

  @override
  Future<List<ChatRoom>> getChatRooms() async {
    await _delay();
    final list = _rooms.values.toList()
      ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return list;
  }

  @override
  Future<ChatRoom?> getChatRoom(String roomId) async {
    await _delay();
    return _rooms[roomId];
  }

  @override
  Future<List<ChatMessage>> getMessages(String roomId) async {
    await _delay();
    final list = List<ChatMessage>.from(_messages[roomId] ?? const <ChatMessage>[])
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Future<ChatMessage> sendMessage(String roomId, String text) async {
    await _delay();
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('메시지가 비어 있습니다.');
    }
    final room = _rooms[roomId];
    if (room == null) {
      throw StateError('채팅방을 찾을 수 없습니다: $roomId');
    }

    final message = ChatMessage(
      id: 'm-${DateTime.now().millisecondsSinceEpoch}',
      roomId: roomId,
      senderId: 'me',
      message: trimmed,
      createdAt: DateTime.now(),
      isMine: true,
    );
    final bucket = _messages.putIfAbsent(roomId, () => []);
    bucket.add(message);
    _rooms[roomId] = room.copyWith(
      lastMessage: trimmed,
      lastMessageTime: message.createdAt,
      unreadCount: 0,
    );
    return message;
  }

  @override
  Future<ChatRoom> createOrGetRoom(FeedItem item) async {
    await _delay();
    final existing = _rooms.values.where((r) => r.feedItemId == item.id);
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final id = 'room-${item.id}-${DateTime.now().millisecondsSinceEpoch}';
    final greeting = switch (item.category) {
      FeedCategory.job => '안녕하세요, 지원 문의드립니다!',
      FeedCategory.housing => '안녕하세요, 매물 문의드립니다!',
      _ => '안녕하세요!',
    };
    final room = ChatRoom(
      id: id,
      feedItemId: item.id,
      feedTitle: item.title,
      feedPrice: item.priceOrCondition,
      feedThumbnail: item.thumbnailUrl,
      opponentName: item.authorName,
      opponentProfileImage: item.authorAvatarUrl,
      opponentNeighborhood: item.neighborhood,
      lastMessage: greeting,
      lastMessageTime: DateTime.now(),
      unreadCount: 0,
      dealStatus: switch (item.category) {
        FeedCategory.job => '모집중',
        FeedCategory.market => item.priceOrCondition == '나눔' ? '나눔중' : '판매중',
        _ => '거래가능',
      },
    );
    _rooms[id] = room;
    _messages[id] = [
      ChatMessage(
        id: 'm-$id-1',
        roomId: id,
        senderId: 'me',
        message: greeting,
        createdAt: DateTime.now(),
        isMine: true,
      ),
    ];
    return room;
  }

  @override
  Future<void> markRoomRead(String roomId) async {
    await _delay();
    final room = _rooms[roomId];
    if (room == null) return;
    _rooms[roomId] = room.copyWith(unreadCount: 0);
  }
}
