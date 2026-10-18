import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_room.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/chat_socket.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return sl<ChatRepository>();
});

class ChatRoomsNotifier extends AsyncNotifier<List<ChatRoom>> {
  @override
  Future<List<ChatRoom>> build() {
    // Refetch per account (login / logout / token expiry).
    ref.watch(currentUserIdProvider);
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

/// Message thread for one room. Lives while the room screen is open: the
/// WebSocket connects on first watch and disconnects on dispose.
class ChatMessagesNotifier extends AsyncNotifier<List<ChatMessage>> {
  ChatMessagesNotifier(this.roomId);

  final String roomId;

  ChatSocket? _socket;
  final List<ChatMessage> _pending = [];

  /// `null` when the repository has no realtime channel (mock mode).
  ValueListenable<ChatSocketStatus>? get socketStatus => _socket?.status;

  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  @override
  Future<List<ChatMessage>> build() async {
    final socket = _repo.openSocket(roomId);
    _socket = socket;
    if (socket != null) {
      final subscription = socket.events.listen(_onEvent);
      void onStatus() {
        if (socket.status.value == ChatSocketStatus.connected) {
          socket.sendRead();
        }
      }

      socket.status.addListener(onStatus);
      ref.onDispose(() {
        subscription.cancel();
        socket.status.removeListener(onStatus);
        socket.dispose();
      });
      // Outside build: status changes notify listeners synchronously.
      unawaited(Future.microtask(socket.connect));
    } else {
      await _repo.markRoomRead(roomId);
    }

    final history = await _repo.getMessages(roomId);
    ref.invalidate(chatRoomsProvider);
    final merged = _pending.fold(history, _upsert);
    _pending.clear();
    return merged;
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Socket path: the server echoes the stored message back to us.
    if (_socket?.sendMessage(trimmed) ?? false) return;

    final sent = await _repo.sendMessage(roomId, trimmed);
    _apply(sent);
  }

  void _onEvent(ChatSocketEvent event) {
    switch (event) {
      case ChatSocketMessage(:final message):
        _apply(message);
        if (!message.isMine) _socket?.sendRead();
        ref.invalidate(chatRoomsProvider);
      case ChatSocketRead(:final readerId, :final readAt):
        final me = ref.read(currentUserIdProvider);
        if (readerId == me) {
          ref.invalidate(chatRoomsProvider);
          return;
        }
        final current = state.value;
        if (current == null) return;
        state = AsyncData([
          for (final m in current)
            m.isMine && !m.isRead && !m.createdAt.isAfter(readAt)
                ? m.copyWith(isRead: true)
                : m,
        ]);
      case ChatSocketError():
        break;
    }
  }

  void _apply(ChatMessage message) {
    final current = state.value;
    if (current == null) {
      _pending.add(message);
      return;
    }
    state = AsyncData(_upsert(current, message));
  }

  static List<ChatMessage> _upsert(List<ChatMessage> list, ChatMessage m) {
    final index = list.indexWhere((e) => e.id == m.id);
    if (index >= 0) return [...list]..[index] = m;
    return [...list, m]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
}

final chatMessagesProvider = AsyncNotifierProvider.autoDispose
    .family<ChatMessagesNotifier, List<ChatMessage>, String>(
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
