import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../../../feed/presentation/feed_actions.dart';
import '../providers/my_feeds_provider.dart';
import '../widgets/my_feed_tile.dart';

/// 내 정보: profile + [내 판매글] / [관심목록] tabs when signed in.
class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);
    final user = authAsync.value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('내 정보')),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryContainer,
                    child: Icon(Icons.person, color: AppColors.primary),
                  ),
                  title: Text(
                    authAsync.isLoading ? '불러오는 중…' : '게스트',
                    style: AppTypography.titleMedium,
                  ),
                  subtitle: Text(
                    '로그인하고 동네 이웃과 거래해 보세요.',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: '로그인 / 회원가입',
                onPressed: () => context.push(RouteNames.login),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('내 정보')),
        body: Column(
          children: [
            _ProfileHeader(user: user),
            ListTile(
              key: const ValueKey('menu-blocked-users'),
              dense: true,
              leading: const Icon(
                Icons.block,
                color: AppColors.textSecondary,
              ),
              title: Text('차단 사용자 관리', style: AppTypography.bodyLarge),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
              ),
              onTap: () => context.push(RouteNames.blockedUsers),
            ),
            const Divider(height: 1),
            const TabBar(
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textHint,
              indicatorColor: AppColors.textPrimary,
              tabs: [
                Tab(key: ValueKey('tab-my-feeds'), text: '내 판매글'),
                Tab(key: ValueKey('tab-my-likes'), text: '관심목록'),
              ],
            ),
            const Divider(height: 1),
            const Expanded(
              child: TabBarView(children: [_MyFeedsTab(), _MyLikesTab()]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = user.profileImage;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage:
                avatar == null ? null : CachedNetworkImageProvider(avatar),
            child: avatar == null
                ? const Icon(Icons.person, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nickname,
                  key: const ValueKey('profile-nickname'),
                  style: AppTypography.header2,
                ),
                const SizedBox(height: 2),
                Text(
                  user.primaryLocation == null
                      ? '대표 동네를 설정해 주세요'
                      : '대표 동네 · ${user.primaryLocation!.fullName}',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('로그아웃되었습니다.')),
              );
            },
            child: Text(
              '로그아웃',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _openDetail(BuildContext context, FeedItem item) =>
    context.push(RouteNames.feedDetail, extra: item);

class _MyFeedsTab extends ConsumerWidget {
  const _MyFeedsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(myFeedsFilterProvider);
    final feedsAsync = ref.watch(myFeedsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              for (final option in MyFeedsFilter.values) ...[
                ChoiceChip(
                  key: ValueKey('my-filter-${option.name}'),
                  label: Text(option.label),
                  selected: option == filter,
                  showCheckmark: false,
                  selectedColor: AppColors.textPrimary,
                  labelStyle: AppTypography.badgeText.copyWith(
                    color: option == filter
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                  onSelected: (_) =>
                      ref.read(myFeedsFilterProvider.notifier).state = option,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ),
        Expanded(
          child: _AsyncList(
            value: feedsAsync,
            emptyText: '아직 작성한 글이 없어요.\n동네 이웃에게 첫 글을 올려 보세요.',
            onRefresh: () => ref.refresh(myFeedsProvider.future),
            itemBuilder: (item) => MyFeedTile(
              key: ValueKey('my-feed-${item.id}'),
              item: item,
              onTap: () => _openDetail(context, item),
              trailing: PopupMenuButton<TradeStatus>(
                key: ValueKey('my-status-${item.id}'),
                tooltip: '상태 변경',
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                onSelected: (status) =>
                    changeTradeStatus(context, ref, item, status),
                itemBuilder: (_) => [
                  for (final status in TradeStatus.values)
                    CheckedPopupMenuItem(
                      key: ValueKey('my-status-option-${status.code}'),
                      value: status,
                      checked: status == item.tradeStatus,
                      child: Text(status.label),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MyLikesTab extends ConsumerWidget {
  const _MyLikesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likesAsync = ref.watch(myLikesProvider);
    return _AsyncList(
      value: likesAsync,
      emptyText: '관심 표시한 글이 없어요.\n마음에 드는 글에 하트를 눌러 보세요.',
      onRefresh: () => ref.refresh(myLikesProvider.future),
      itemBuilder: (item) => MyFeedTile(
        key: ValueKey('my-like-${item.id}'),
        item: item,
        onTap: () => _openDetail(context, item),
        trailing: IconButton(
          key: ValueKey('my-like-heart-${item.id}'),
          tooltip: '관심 해제',
          icon: const Icon(Icons.favorite_rounded, color: AppColors.primary),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              await ref.read(myLikesProvider.notifier).unlike(item);
            } catch (e) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    e is ApiException ? e.message : '관심 해제에 실패했어요.',
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class _AsyncList extends StatelessWidget {
  const _AsyncList({
    required this.value,
    required this.emptyText,
    required this.onRefresh,
    required this.itemBuilder,
  });

  final AsyncValue<List<FeedItem>> value;
  final String emptyText;
  final Future<void> Function() onRefresh;
  final Widget Function(FeedItem item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final items = value.value;
    if (items == null) {
      return value.hasError
          ? Center(
              child: Text(
                value.error is ApiException
                    ? (value.error as ApiException).message
                    : '목록을 불러오지 못했어요.',
                style: AppTypography.bodyMedium,
              ),
            )
          : const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Text(
                  emptyText,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, index) => itemBuilder(items[index]),
            ),
    );
  }
}
