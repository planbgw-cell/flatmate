import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  String _timeLabel(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? '오전' : '오후';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$period $h12:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.68,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: mine ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(mine ? 16 : 4),
          bottomRight: Radius.circular(mine ? 4 : 16),
        ),
        border: mine ? null : Border.all(color: AppColors.border),
      ),
      child: Text(
        message.message,
        style: AppTypography.bodyLarge.copyWith(
          color: mine ? Colors.white : AppColors.textPrimary,
          height: 1.35,
        ),
      ),
    );

    final time = Text(
      _timeLabel(message.createdAt),
      style: AppTypography.caption,
    );

    if (mine) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            time,
            const SizedBox(width: 6),
            bubble,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primaryContainer,
            child: Icon(Icons.person, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          bubble,
          const SizedBox(width: 6),
          time,
        ],
      ),
    );
  }
}
