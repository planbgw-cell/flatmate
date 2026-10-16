import '../../domain/models/feed_item.dart';

abstract class FeedRemoteDataSource {
  Future<List<FeedItem>> fetchPage({required int page, int pageSize = 10});
}

class FeedRemoteDataSourceStub implements FeedRemoteDataSource {
  @override
  Future<List<FeedItem>> fetchPage({
    required int page,
    int pageSize = 10,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (page < 1) return const [];

    final seed = buildMockFeedItems();
    // Cap demo feed at ~2 pages so infinite scroll is visible but finite.
    final maxItems = seed.length * 2;
    final start = (page - 1) * pageSize;
    if (start >= maxItems) return const [];

    final count = (maxItems - start).clamp(0, pageSize);
    return List.generate(count, (index) {
      final source = seed[(start + index) % seed.length];
      final pageOffset = start + index;
      return FeedItem(
        id: '${source.id}-p$page-$pageOffset',
        title: source.title,
        neighborhood: source.neighborhood,
        postedAt: source.postedAt.subtract(Duration(minutes: pageOffset * 7)),
        priceOrCondition: source.priceOrCondition,
        thumbnailUrl: source.thumbnailUrl,
        imageUrls: source.imageUrls,
        likeCount: source.likeCount + (pageOffset % 5),
        chatCount: source.chatCount + (pageOffset % 3),
        category: source.category,
        badges: source.badges,
        isBumped: source.isBumped && page == 1 && index < 2,
        description: source.description,
        authorName: source.authorName,
        authorAvatarUrl: source.authorAvatarUrl,
        trustScore: source.trustScore,
        ctaLabel: source.ctaLabel,
        verificationCount: source.verificationCount,
        detailMeta: source.detailMeta,
      );
    });
  }
}
