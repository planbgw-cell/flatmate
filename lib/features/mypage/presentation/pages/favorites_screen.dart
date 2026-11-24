import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/my_feeds_provider.dart';
import '../widgets/my_feed_tile.dart';

/// Bottom-tab [관심목록] — liked feeds (`GET /users/me/likes`).
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('관심목록')),
      body: user == null
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  Text(
                    '로그인하면 관심 표시한 글을 모아볼 수 있어요.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: '로그인 / 회원가입',
                    onPressed: () => context.push(RouteNames.login),
                  ),
                ],
              ),
            )
          : const _LikesBody(),
    );
  }
}

class _LikesBody extends ConsumerWidget {
  const _LikesBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likesAsync = ref.watch(myLikesProvider);
    final items = likesAsync.value;
    if (items == null) {
      return likesAsync.hasError
          ? Center(
              child: Text(
                likesAsync.error is ApiException
                    ? (likesAsync.error as ApiException).message
                    : '목록을 불러오지 못했어요.',
                style: AppTypography.bodyMedium,
              ),
            )
          : const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.refresh(myLikesProvider.future),
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Text(
                  '관심 표시한 글이 없어요.\n마음에 드는 글에 하트를 눌러 보세요.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final item = items[index];
                return MyFeedTile(
                  key: ValueKey('my-like-${item.id}'),
                  item: item,
                  onTap: () => context.push(
                    RouteNames.feedDetail,
                    extra: item,
                  ),
                  trailing: IconButton(
                    key: ValueKey('my-like-heart-${item.id}'),
                    tooltip: '관심 해제',
                    icon: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.primary,
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ref.read(myLikesProvider.notifier).unlike(item);
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              e is ApiException
                                  ? e.message
                                  : '관심 해제에 실패했어요.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
