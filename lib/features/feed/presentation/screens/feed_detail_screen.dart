import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/external_url.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../map_around/presentation/providers/map_around_provider.dart';
import '../../domain/models/feed_extra_meta.dart';
import '../../domain/models/feed_item.dart';
import '../feed_actions.dart';
import '../providers/feed_provider.dart';
import '../widgets/author_profile_card.dart';
import '../widgets/category_detail_card.dart';
import '../widgets/detail_bottom_bar.dart';
import '../widgets/detail_image_carousel.dart';
import '../widgets/feed_thumbnail.dart';
import '../widgets/festival_badge.dart';
import '../widgets/public_housing_badge.dart';
import '../widgets/public_housing_notice_card.dart';
import '../widgets/trade_status_badge.dart';

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

  /// Structured form for the post's `feed_type` (community posts have none).
  static String? _editRoute(FeedCategory category) => switch (category) {
        FeedCategory.housing => RouteNames.postCreateRealEstate,
        FeedCategory.job => RouteNames.postCreateJob,
        FeedCategory.market => RouteNames.postCreateGeneral,
        FeedCategory.community => RouteNames.postCreateCommunity,
        FeedCategory.all => null,
      };

  /// [⋮]: author gets 게시글 수정 / 거래 상태 변경 / 게시글 삭제; others a
  /// report stub.
  Future<void> _onMore(FeedItem item) async {
    final me = ref.read(currentUserIdProvider);
    final isAuthor = me != null && item.authorId == me;
    final editRoute = _editRoute(item.category);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: isAuthor
              ? [
                  if (editRoute != null)
                    ListTile(
                      key: const ValueKey('menu-edit'),
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('게시글 수정'),
                      onTap: () => Navigator.pop(context, 'edit'),
                    ),
                  ListTile(
                    key: const ValueKey('menu-trade-status'),
                    leading: const Icon(Icons.swap_horiz),
                    title: const Text('거래 상태 변경'),
                    onTap: () => Navigator.pop(context, 'status'),
                  ),
                  ListTile(
                    key: const ValueKey('menu-delete'),
                    leading: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                    title: const Text(
                      '게시글 삭제',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: () => Navigator.pop(context, 'delete'),
                  ),
                ]
              : [
                  ListTile(
                    key: const ValueKey('menu-report'),
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text('게시글 신고하기'),
                    onTap: () => Navigator.pop(context, 'report'),
                  ),
                  // Public data (LH 마이홈, 한국관광공사) has no user to block.
                  if (item.authorId != null && !item.isPublicData)
                    ListTile(
                      key: const ValueKey('menu-block'),
                      leading: const Icon(Icons.block, color: AppColors.error),
                      title: const Text(
                        '이 유저 차단하기',
                        style: TextStyle(color: AppColors.error),
                      ),
                      onTap: () => Navigator.pop(context, 'block'),
                    ),
                ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'edit':
        final updated = await context.push<FeedItem>(editRoute!, extra: item);
        if (updated != null && mounted) setState(() => _galleryIndex = 0);
      case 'status':
        final status = await showTradeStatusSheet(context, item.tradeStatus);
        if (status == null || !mounted) return;
        await changeTradeStatus(context, ref, item, status);
      case 'delete':
        final deleted = await deleteFeedWithConfirm(context, ref, item);
        if (deleted && mounted) context.go(RouteNames.home);
      case 'report':
        if (!await ensureSession(context, ref) || !mounted) return;
        await reportFeedWithSheet(context, ref, item);
      case 'block':
        if (!await ensureSession(context, ref) || !mounted) return;
        if (item.authorId == ref.read(currentUserIdProvider)) return;
        final blocked = await blockAuthorWithConfirm(context, ref, item);
        if (!blocked || !mounted) return;
        context.canPop() ? context.pop() : context.go(RouteNames.home);
    }
  }

  /// No 1:1 chat with an institution: [공고 사이트 이동] (apply URL) and
  /// [지도에서 보기] (when located).
  Widget _publicHousingBar(
    FeedItem item,
    PublicHousingNotice notice,
    bool liked,
  ) {
    final url = notice.applyUrl;
    final located = item.latitude != null && item.longitude != null;
    final onApply = url == null ? null : () => _openApplySite(url);
    final onMap = located ? () => _openOnMap(item) : null;
    return DetailBottomBar(
      priceOrCondition: notice.rentSummary,
      liked: liked,
      onLikeToggle: () => toggleFeedLike(context, ref, item.id),
      ctaLabel: onApply != null ? '공고 사이트 이동' : '지도에서 보기',
      ctaKey: ValueKey(onApply != null ? 'detail-apply-cta' : 'detail-map-cta'),
      onCtaPressed: onApply ?? onMap,
      secondaryLabel: onApply != null && onMap != null ? '지도에서 보기' : null,
      secondaryKey: const ValueKey('detail-map-cta'),
      onSecondaryPressed: onApply != null ? onMap : null,
    );
  }

  /// 공공 주거 공고: the notice / 청약 site in the external browser.
  Future<void> _openApplySite(String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    final opened = uri != null &&
        await ref.read(externalUrlLauncherProvider)(uri);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('브라우저를 열 수 없어요.')),
      );
    }
  }

  /// Public data (축제, 공공 주거): 내주변 tab centered on the post, with it
  /// selected.
  void _openOnMap(FeedItem item) {
    if (item.latitude == null || item.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치 정보가 없는 글이에요.')),
      );
      return;
    }
    ref.read(mapFocusProvider.notifier).state = item;
    context.go(RouteNames.around);
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
    final notice = item.publicNotice;
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
                  key: const ValueKey('detail-more'),
                  icon: Icon(Icons.more_vert_rounded, color: iconColor),
                  onPressed: () => _onMore(item),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.fadeTitle,
                ],
                background: DetailImageCarousel(
                  key: ValueKey(item.gallery.join('|')),
                  images: item.gallery,
                  index: _galleryIndex,
                  onPageChanged: (i) => setState(() => _galleryIndex = i),
                  placeholder: FeedPlaceholder(item: item, large: true),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: item.isPublicData
                  ? SourceInfoCard(
                      key: const ValueKey('detail-source-card'),
                      item: item,
                    )
                  : AuthorProfileCard(item: item),
            ),
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
                    if (item.isPublicHousing) ...[
                      PublicHousingBadges(
                        key: const ValueKey('detail-housing-badges'),
                        item: item,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.isFestival) ...[
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: FestivalBadge(
                              key: ValueKey('detail-festival-badge'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Expanded(
                          child: Text(
                            item.displayTitle,
                            key: const ValueKey('detail-title'),
                            style: AppTypography.header1,
                          ),
                        ),
                        if (item.tradeStatus != TradeStatus.selling) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: TradeStatusBadge(
                              key: const ValueKey('detail-trade-badge'),
                              status: item.tradeStatus,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // The notice card carries every line of a 공공 주거 body.
                    if (notice != null)
                      PublicHousingNoticeCard(
                        notice: notice,
                        onOpenUrl: _openApplySite,
                      )
                    else
                      Text(
                        item.description.isEmpty
                            ? '상세 설명이 곧 등록됩니다.'
                            : item.description,
                        style: AppTypography.bodyLarge.copyWith(height: 1.55),
                      ),
                    if (notice == null &&
                        (item.detailMeta.isNotEmpty ||
                            item.extraMeta.isNotEmpty)) ...[
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
                          key: const ValueKey('detail-like-count'),
                          style: AppTypography.caption,
                        ),
                        if (!item.isPublicData) ...[
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
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: notice != null
            ? _publicHousingBar(item, notice, fav.isFavorite)
            : item.isPublicData
            ? DetailBottomBar(
                priceOrCondition: FeedExtraMeta(item.category, item.extraMeta)
                    .eventPeriodLabel,
                ctaLabel: '지도에서 보기',
                ctaKey: const ValueKey('detail-map-cta'),
                liked: fav.isFavorite,
                onLikeToggle: () => toggleFeedLike(context, ref, item.id),
                onCtaPressed: () => _openOnMap(item),
              )
            : DetailBottomBar(
                priceOrCondition: item.priceOrCondition,
                ctaLabel: item.ctaButtonLabel,
                liked: fav.isFavorite,
                onLikeToggle: () => toggleFeedLike(context, ref, item.id),
                onCtaPressed: () => _onCta(item),
              ),
      ),
    );
  }
}
