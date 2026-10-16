import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_room.dart';
import '../../domain/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return sl<ChatRepository>();
});

class ChatRoomsNotifier extends AsyncNotifier<List<ChatRoom>> {
  @override
  Future<List<ChatRoom>> build() {
    return ref.read(chatRepositoryProvider).getChatRooms();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(chatRepositoryProvider).getChatRooms(),
    );
  }

  int get totalUnread {
    final rooms = state.value ?? const [];
    return rooms.fold<int>(0, (sum, r) => sum + r.unreadCount);
  }
}

final chatRoomsProvider =
    AsyncNotifierProvider<ChatRoomsNotifier, List<ChatRoom>>(
  ChatRoomsNotifier.new,
);

class ChatMessagesNotifier extends AsyncNotifier<List<ChatMessage>> {
  ChatMessagesNotifier(this.roomId);

  final String roomId;

  @override
  Future<List<ChatMessage>> build() async {
    final repo = ref.read(chatRepositoryProvider);
    await repo.markRoomRead(roomId);
    // Refresh room list unread badges after marking read.
    ref.invalidate(chatRoomsProvider);
    return repo.getMessages(roomId);
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final sent =
        await ref.read(chatRepositoryProvider).sendMessage(roomId, trimmed);
    final current = state.value ?? const <ChatMessage>[];
    state = AsyncData([...current, sent]);
    ref.invalidate(chatRoomsProvider);
  }
}

final chatMessagesProvider =
    AsyncNotifierProvider.family<ChatMessagesNotifier, List<ChatMessage>, String>(
  ChatMessagesNotifier.new,
);

final chatRoomProvider =
    FutureProvider.family<ChatRoom?, String>((ref, roomId) async {
  return ref.read(chatRepositoryProvider).getChatRoom(roomId);
});

/// Opens or creates a chat room for a feed item, then returns the room id.
Future<String> openChatForFeed(WidgetRef ref, FeedItem item) async {
  final room =
      await ref.read(chatRepositoryProvider).createOrGetRoom(item);
  ref.invalidate(chatRoomsProvider);
  return room.id;
}
