import '../../domain/models/feed_item.dart';

FeedItem feedItemFromJson(Map<String, dynamic> json) {
  final categoryName = (json['category'] as String?) ?? 'community';
  final category = FeedCategory.values.firstWhere(
    (c) => c.name == categoryName,
    orElse: () => FeedCategory.community,
  );

  final badgeNames = (json['badges'] as List?) ?? const [];
  final badges = <FeedBadge>[
    for (final b in badgeNames)
      ...FeedBadge.values.where((e) => e.name == b.toString()),
  ];

  final metaRaw = json['detail_meta'] ?? json['detailMeta'];
  final detailMeta = <String, String>{};
  if (metaRaw is Map) {
    metaRaw.forEach((key, value) {
      detailMeta[key.toString()] = value.toString();
    });
  }

  final images = (json['image_urls'] as List?)?.map((e) => e.toString()).toList() ??
      (json['imageUrls'] as List?)?.map((e) => e.toString()).toList() ??
      const <String>[];

  return FeedItem(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    neighborhood: json['neighborhood']?.toString() ?? '',
    postedAt: DateTime.tryParse(json['posted_at']?.toString() ?? '') ??
        DateTime.tryParse(json['postedAt']?.toString() ?? '') ??
        DateTime.now(),
    priceOrCondition: json['price_or_condition']?.toString() ??
        json['priceOrCondition']?.toString() ??
        '',
    thumbnailUrl: json['thumbnail_url']?.toString() ??
        json['thumbnailUrl']?.toString() ??
        '',
    likeCount: (json['like_count'] as num?)?.toInt() ??
        (json['likeCount'] as num?)?.toInt() ??
        0,
    chatCount: (json['chat_count'] as num?)?.toInt() ??
        (json['chatCount'] as num?)?.toInt() ??
        0,
    category: category,
    badges: badges,
    isBumped: json['is_bumped'] as bool? ?? json['isBumped'] as bool? ?? false,
    imageUrls: images,
    description: json['description']?.toString() ?? '',
    authorName: json['author_name']?.toString() ??
        json['authorName']?.toString() ??
        '이웃',
    authorAvatarUrl: json['author_avatar_url']?.toString() ??
        json['authorAvatarUrl']?.toString(),
    trustScore: (json['trust_score'] as num?)?.toDouble() ??
        (json['trustScore'] as num?)?.toDouble() ??
        36.5,
    ctaLabel: json['cta_label']?.toString() ??
        json['ctaLabel']?.toString() ??
        '채팅하기',
    verificationCount: (json['verification_count'] as num?)?.toInt() ??
        (json['verificationCount'] as num?)?.toInt() ??
        3,
    detailMeta: detailMeta,
    isFavorite:
        json['is_favorite'] as bool? ?? json['isFavorite'] as bool? ?? false,
  );
}

Map<String, dynamic> feedItemToJson(FeedItem item) {
  return {
    'id': item.id,
    'title': item.title,
    'neighborhood': item.neighborhood,
    'posted_at': item.postedAt.toIso8601String(),
    'price_or_condition': item.priceOrCondition,
    'thumbnail_url': item.thumbnailUrl,
    'like_count': item.likeCount,
    'chat_count': item.chatCount,
    'category': item.category.name,
    'badges': item.badges.map((b) => b.name).toList(),
    'is_bumped': item.isBumped,
    'image_urls': item.imageUrls,
    'description': item.description,
    'author_name': item.authorName,
    'author_avatar_url': item.authorAvatarUrl,
    'trust_score': item.trustScore,
    'cta_label': item.ctaLabel,
    'verification_count': item.verificationCount,
    'detail_meta': item.detailMeta,
    'is_favorite': item.isFavorite,
  };
}
