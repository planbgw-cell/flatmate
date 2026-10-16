import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/common_widgets/skeleton_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_room_tile.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(chatRoomsProvider);
    final unread = roomsAsync.maybeWhen(
      data: (rooms) => rooms.fold<int>(0, (s, r) => s + r.unreadCount),
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text('채팅', style: AppTypography.header2),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unread',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: roomsAsync.when(
        loading: () => const SkeletonCardList(count: 6),
        error: (e, _) => Center(child: Text('$e')),
        data: (rooms) {
          if (rooms.isEmpty) {
            return Center(
              child: Text(
                '아직 채팅이 없어요.\n관심 있는 글에서 문의를 시작해 보세요.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(chatRoomsProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: rooms.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final room = rooms[index];
                return ChatRoomTile(
                  room: room,
                  onTap: () => context.push(
                    RouteNames.chatRoomPath(room.id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
