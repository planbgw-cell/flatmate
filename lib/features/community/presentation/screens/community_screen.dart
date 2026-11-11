import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/common_widgets/skeleton_card.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../feed/domain/models/region.dart';
import '../../../feed/domain/repositories/feed_repository.dart';
import '../../../feed/presentation/feed_actions.dart';
import '../../../feed/presentation/widgets/feed_card_item.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../providers/community_feed_provider.dart';

/// Tab 1 — 동네소식: [우리 동네] (같은 시·군·구) / [우리 권역 축제] (권역 전체).
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  static String _errorText(Object? error) => switch (error) {
        ApiException(:final message) => message,
        StateError(:final message) => message,
        _ => '동네소식을 불러오지 못했어요.',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dong = ref.watch(currentLocationProvider).dongName;
    final scope = ref.watch(communityScopeProvider);
    final isZone = scope == PublicScope.zone;
    final zone = zoneOf(ref.watch(serverDongProvider).value?.cityName);
    final feedAsync = ref.watch(communityFeedProvider);
    final data = feedAsync.value;

    final Widget list;
    if (data == null) {
      list = feedAsync.hasError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  _errorText(feedAsync.error),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
              ),
            )
          : const SkeletonCardList(count: 5);
    } else {
      final items = data.items;
      final showLoader = data.hasMore || data.isLoadingMore;
      list = RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(communityFeedProvider.notifier).refresh(),
        child: items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Text(
                    isZone
                        ? '진행 중인 권역 축제가 없어요.'
                        : '아직 우리 동네 소식이 없어요.\n첫 소식을 올려 보세요.',
                    key: const ValueKey('community-empty'),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium,
                  ),
                ],
              )
            : NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  final metrics = notification.metrics;
                  if (metrics.pixels >= metrics.maxScrollExtent - 240) {
                    ref.read(communityFeedProvider.notifier).loadMore();
                  }
                  return false;
                },
                child: ListView.separated(
                  key: const ValueKey('community-list'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: items.length + (showLoader ? 1 : 0),
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index >= items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final item = items[index];
                    return FeedCardItem(
                      item: item,
                      showRegion: isZone,
                      onTap: () =>
                          context.push(RouteNames.feedDetail, extra: item),
                      onFavoriteToggle: () =>
                          toggleFeedLike(context, ref, item.id),
                    );
                  },
                ),
              ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('동네소식 · $dong', style: AppTypography.header2),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                _ScopeChip(
                  key: const ValueKey('community-scope-sigungu'),
                  label: '우리 동네',
                  selected: !isZone,
                  onSelected: () => ref
                      .read(communityScopeProvider.notifier)
                      .state = PublicScope.sigungu,
                ),
                const SizedBox(width: AppSpacing.xs),
                _ScopeChip(
                  key: const ValueKey('community-scope-zone'),
                  label: '우리 권역 축제',
                  selected: isZone,
                  onSelected: () => ref
                      .read(communityScopeProvider.notifier)
                      .state = PublicScope.zone,
                ),
              ],
            ),
          ),
          if (isZone && zone != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Text(
                '${zoneDescription(zone)} 축제를 모아 보여드려요',
                key: const ValueKey('community-zone-caption'),
                style: AppTypography.caption,
              ),
            ),
          const Divider(height: 1),
          Expanded(child: list),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.textPrimary,
      labelStyle: AppTypography.badgeText.copyWith(
        color: selected ? Colors.white : AppColors.textSecondary,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}
