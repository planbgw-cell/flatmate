import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../feed/presentation/widgets/author_profile_row.dart';
import '../../../feed/presentation/widgets/sticky_cta_bar.dart';
import '../../domain/entities/property.dart';
import '../bloc/property_bloc.dart';

class PropertyDetailPage extends StatefulWidget {
  const PropertyDetailPage({super.key, required this.propertyId});

  final String propertyId;

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  final _scrollController = ScrollController();
  bool _liked = false;
  double _scrollOffset = 0;
  int _galleryIndex = 0;

  static const _expandedHeight = 320.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double get _collapseT =>
      (_scrollOffset / (_expandedHeight - kToolbarHeight)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PropertyBloc>().state;
    final property = state is PropertyLoaded
        ? state.items.where((item) => item.id == widget.propertyId).firstOrNull
        : null;

    if (property == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('매물 상세'),
        ),
        body: Center(child: Text('매물을 찾을 수 없습니다. (${widget.propertyId})')),
      );
    }

    final images = [
      property.thumbnailUrl ??
          'https://picsum.photos/seed/${property.id}/800/600',
      'https://picsum.photos/seed/${property.id}-b/800/600',
      'https://picsum.photos/seed/${property.id}-c/800/600',
    ];

    final collapsed = _collapseT;
    final iconColor = Color.lerp(Colors.white, AppColors.textPrimary, collapsed)!;
    final appBarBg = Color.lerp(Colors.transparent, AppColors.surface, collapsed)!;
    final price = CurrencyFormatter.krw(property.monthlyRent);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: collapsed > 0.5
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: _expandedHeight,
              pinned: true,
              backgroundColor: appBarBg,
              foregroundColor: iconColor,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: iconColor),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.ios_share_rounded, color: iconColor),
                  onPressed: () {},
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _PropertyGallery(
                  images: images,
                  index: _galleryIndex,
                  onPageChanged: (i) => setState(() => _galleryIndex = i),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AuthorProfileRow(
                name: '주거메이트',
                neighborhood: _neighborhoodFrom(property),
                trustScore: 43.2,
              ),
            ),
            const SliverToBoxAdapter(child: Divider(height: 1)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      property.address,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (property.availableFrom != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '입주 가능 ${DateFormatter.ymd(property.availableFrom!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      '자취·단기 거주에 맞는 매물입니다. 상세 조건은 채팅으로 문의해 주세요.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: StickyCtaBar(
          priceOrCondition: price,
          ctaLabel: '채팅하기',
          liked: _liked,
          onLikeToggle: () => setState(() => _liked = !_liked),
          onCtaPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('채팅 — 곧 연결됩니다.')),
            );
          },
        ),
      ),
    );
  }

  String _neighborhoodFrom(Property property) {
    final parts = property.address.split(' ');
    return parts.length >= 2 ? parts[1] : property.address;
  }
}

class _PropertyGallery extends StatelessWidget {
  const _PropertyGallery({
    required this.images,
    required this.index,
    required this.onPageChanged,
  });

  final List<String> images;
  final int index;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, i) {
            return CachedNetworkImage(
              imageUrl: images[i],
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: AppColors.skeletonBase),
              errorWidget: (_, _, _) => Container(
                color: AppColors.skeletonBase,
                child: const Icon(Icons.apartment_outlined, size: 48),
              ),
            );
          },
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [Color(0x66000000), Colors.transparent],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.lg,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (i) {
              final active = i == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.white54,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
