import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/route_names.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../domain/models/feed_item.dart';
import 'providers/feed_provider.dart';

String _errorText(Object error, String fallback) =>
    error is ApiException ? error.message : fallback;

/// Heart tap: requires login (JWT), then optimistic toggle with rollback.
Future<void> toggleFeedLike(
  BuildContext context,
  WidgetRef ref,
  String feedId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  if (!ref.read(tokenStorageProvider).hasSession) {
    final loggedIn = await context.push<bool>(RouteNames.login);
    if (loggedIn != true) return;
  }
  try {
    await ref.read(favoriteItemProvider(feedId).notifier).toggle();
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(_errorText(e, '관심 등록에 실패했어요.'))),
    );
  }
}

/// 판매중 / 예약중 / 거래완료 picker; `null` when dismissed.
Future<TradeStatus?> showTradeStatusSheet(
  BuildContext context,
  TradeStatus current,
) {
  return showModalBottomSheet<TradeStatus>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('거래 상태 변경', style: AppTypography.header2),
          ),
          for (final status in TradeStatus.values)
            ListTile(
              key: ValueKey('trade-option-${status.code}'),
              title: Text(status.label, style: AppTypography.bodyLarge),
              trailing: status == current
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.pop(context, status),
            ),
        ],
      ),
    ),
  );
}

/// Author action: `PATCH /feeds/{id}/status`, then sync feed / detail lists.
Future<FeedItem?> changeTradeStatus(
  BuildContext context,
  WidgetRef ref,
  FeedItem item,
  TradeStatus status,
) async {
  if (status == item.tradeStatus) return item;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final updated = await ref
        .read(feedRepositoryProvider)
        .updateTradeStatus(item.id, status);
    final merged = item.copyWith(tradeStatus: updated.tradeStatus);
    ref.read(feedOverridesProvider.notifier).update(
          (map) => {...map, item.id: merged},
        );
    ref.read(feedListProvider.notifier).patchItem(merged);
    ref.read(feedMutationTickProvider.notifier).state++;
    messenger.showSnackBar(
      SnackBar(content: Text('거래 상태를 "${status.label}"(으)로 바꿨어요.')),
    );
    return merged;
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(_errorText(e, '거래 상태를 바꾸지 못했어요.'))),
    );
    return null;
  }
}

/// Author action with confirmation: `DELETE /feeds/{id}`. `true` if deleted.
Future<bool> deleteFeedWithConfirm(
  BuildContext context,
  WidgetRef ref,
  FeedItem item,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('게시글을 삭제할까요?'),
      content: const Text('삭제한 글은 피드와 관심목록에서 사라지고 되돌릴 수 없어요.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        TextButton(
          key: const ValueKey('confirm-delete'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('삭제', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(feedRepositoryProvider).deleteFeed(item.id);
    ref.read(feedListProvider.notifier).removeItem(item.id);
    ref.read(feedOverridesProvider.notifier).update(
          (map) => {...map}..remove(item.id),
        );
    ref.read(feedMutationTickProvider.notifier).state++;
    messenger.showSnackBar(const SnackBar(content: Text('게시글을 삭제했어요.')));
    return true;
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(_errorText(e, '게시글을 삭제하지 못했어요.'))),
    );
    return false;
  }
}
