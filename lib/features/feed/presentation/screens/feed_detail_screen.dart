import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../domain/models/feed_item.dart';
import '../providers/feed_provider.dart';
import '../widgets/author_profile_card.dart';
import '../widgets/category_detail_card.dart';
import '../widgets/detail_bottom_bar.dart';
import '../widgets/detail_image_carousel.dart';

/// Feed item detail — parallax gallery, trust profile, sticky CTA.
class FeedDetailScreen extends ConsumerStatefulWidget {
  const FeedDetailScreen({super.key, required this.item});

  final FeedItem item;

  @override
  ConsumerState<FeedDetailScreen> createState() => _FeedDetailScreenState();
}

class _FeedDetailScreenState extends ConsumerState<FeedDetailScreen> {
  final _scrollController = ScrollController();
  int _galleryIndex = 0;
  double _scrollOffset = 0;

  static const _expandedHeight = 340.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(favoriteItemProvider(widget.item.id).notifier)
          .hydrate(widget.item);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double get _collapseT {
    final range = _expandedHeight - kToolbarHeight;
    if (range <= 0) return 0;
    return (_scrollOffset / range).clamp(0.0, 1.0);
  }

  Future<void> _onCta(FeedItem item) async {
    if (!ref.read(tokenStorageProvider).hasSession) {
      final loggedIn = await context.push<bool>(RouteNames.login);
      if (loggedIn != true || !mounted) return;
    }
    try {
      final roomId = await openChatForFeed(ref, item);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item.category == FeedCategory.job
                ? '채팅방이 열렸습니다. 지원 문의를 이어서 진행하세요.'
                : '채팅방이 생성되었습니다.',
          ),
        ),
      );
      context.push(RouteNames.chatRoomPath(roomId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException ? e.message : '채팅방 연결에 실패했습니다.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = ref.watch(feedItemProvider(widget.item));
    final fav = ref.watch(favoriteItemProvider(item.id));
    final collapsed = _collapseT;
    final iconColor =
        Color.lerp(Colors.white, AppColors.textPrimary, collapsed)!;
    final appBarBg = Color.lerp(
      Colors.transparent,
      AppColors.background,
      collapsed,
    )!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: collapsed > 0.5
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: _expandedHeight,
              pinned: true,
              stretch: true,
              backgroundColor: appBarBg,
              foregroundColor: iconColor,
              elevation: collapsed > 0.9 ? 0.5 : 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: iconColor),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.ios_share_rounded, color: iconColor),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('공유 기능은 곧 추가됩니다.')),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.more_vert_rounded, color: iconColor),
                  onPressed: () {},
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.fadeTitle,
                ],
                background: DetailImageCarousel(
                  images: item.gallery,
                  index: _galleryIndex,
                  onPageChanged: (i) => setState(() => _galleryIndex = i),
                ),
              ),
            ),
            SliverToBoxAdapter(child: AuthorProfileCard(item: item)),
            const SliverToBoxAdapter(child: Divider(height: 1)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.category.label} · ${DateFormatter.relative(item.postedAt)}'
                      '${item.isBumped ? ' · 끌올' : ''}',
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(item.title, style: AppTypography.header1),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      item.description.isEmpty
                          ? '상세 설명이 곧 등록됩니다.'
                          : item.description,
                      style: AppTypography.bodyLarge.copyWith(height: 1.55),
                    ),
                    if (item.detailMeta.isNotEmpty ||
                        item.extraMeta.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      CategoryDetailCard(item: item),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Icon(
                          fav.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color: fav.isFavorite
                              ? AppColors.primary
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '관심 ${fav.likeCount > 0 || fav.isFavorite ? fav.likeCount : item.likeCount}',
                          style: AppTypography.caption,
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '채팅 ${item.chatCount}',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: DetailBottomBar(
          priceOrCondition: item.priceOrCondition,
          ctaLabel: item.ctaButtonLabel,
          liked: fav.isFavorite,
          onLikeToggle: () =>
              ref.read(favoriteItemProvider(item.id).notifier).toggle(),
          onCtaPressed: () => _onCta(item),
        ),
      ),
    );
  }
}
