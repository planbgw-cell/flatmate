import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';

enum ChatSocketStatus { disconnected, connecting, connected }

sealed class ChatSocketEvent {
  const ChatSocketEvent();
}

/// New message in the room (including the echo of our own sends).
class ChatSocketMessage extends ChatSocketEvent {
  const ChatSocketMessage(this.message);
  final ChatMessage message;
}

/// [readerId] read every message the other participant sent up to [readAt].
class ChatSocketRead extends ChatSocketEvent {
  const ChatSocketRead({
    required this.readerId,
    required this.readAt,
    required this.updated,
  });

  final String readerId;
  final DateTime readAt;
  final int updated;
}

class ChatSocketError extends ChatSocketEvent {
  const ChatSocketError(this.detail);
  final String detail;
}

/// Realtime channel for one chat room.
abstract class ChatSocket {
  ValueListenable<ChatSocketStatus> get status;
  Stream<ChatSocketEvent> get events;

  Future<void> connect();

  /// `false` when not connected (caller falls back to REST).
  bool sendMessage(String text);
  bool sendRead();

  Future<void> disconnect();
  void dispose();
}
