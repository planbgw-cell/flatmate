import '../../../location/domain/models/location_item.dart';
import '../../domain/models/feed_item.dart';

/// App category ↔ FastAPI `feed_type` enum.
const _feedTypeByCategory = {
  FeedCategory.housing: 'REAL_ESTATE',
  FeedCategory.job: 'JOB',
  FeedCategory.community: 'LOCAL_NEWS',
  FeedCategory.market: 'GENERAL',
};

/// `null` for `all` (no server-side filter).
String? feedTypeForCategoryKey(String key) {
  final category = FeedCategoryX.fromKey(key);
  return _feedTypeByCategory[category];
}

FeedCategory categoryForFeedType(String? feedType) {
  for (final entry in _feedTypeByCategory.entries) {
    if (entry.value == feedType) return entry.key;
  }
  return FeedCategory.community;
}

/// `FeedOut` → [FeedItem]. UI-only fields travel in the free-form `extra` map.
FeedItem feedItemFromJson(Map<String, dynamic> json) {
  final extraRaw = json['extra'];
  final extra = extraRaw is Map
      ? Map<String, dynamic>.from(extraRaw)
      : const <String, dynamic>{};

  final images = (extra['image_urls'] as List?)
          ?.map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList() ??
      const <String>[];

  final badgeNames = (extra['badges'] as List?) ?? const [];
  final badges = <FeedBadge>[
    for (final b in badgeNames)
      ...FeedBadge.values.where((e) => e.name == b.toString()),
  ];

  final detailMeta = <String, String>{};
  final metaRaw = extra['detail_meta'];
  if (metaRaw is Map) {
    metaRaw.forEach((key, value) {
      detailMeta[key.toString()] = value.toString();
    });
  }

  final address = json['address']?.toString() ?? '';
  final neighborhood = extra['neighborhood']?.toString() ??
      (address.isEmpty ? '' : address.split(' ').last);

  final thumbnail = extra['thumbnail_url']?.toString() ??
      (images.isNotEmpty ? images.first : '');

  final postedAt = DateTime.tryParse(json['published_at']?.toString() ?? '') ??
      DateTime.tryParse(json['created_at']?.toString() ?? '') ??
      DateTime.now();

  return FeedItem(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    neighborhood: neighborhood,
    postedAt: postedAt.toLocal(),
    priceOrCondition: extra['price_or_condition']?.toString() ?? '',
    thumbnailUrl: thumbnail,
    imageUrls: images,
    likeCount: (extra['like_count'] as num?)?.toInt() ?? 0,
    chatCount: (extra['chat_count'] as num?)?.toInt() ?? 0,
    category: categoryForFeedType(json['feed_type']?.toString()),
    badges: badges,
    isBumped: extra['is_bumped'] as bool? ?? false,
    description: json['content']?.toString() ?? '',
    authorName: extra['author_nickname']?.toString() ?? '이웃',
    authorId: json['author_id']?.toString(),
    ctaLabel: extra['cta_label']?.toString() ?? '채팅하기',
    detailMeta: detailMeta,
  );
}

/// [FeedItem] → `FeedCreate` body for `POST /feeds`.
Map<String, dynamic> feedCreateToJson(FeedItem item, {LocationItem? location}) {
  // Only remote URLs are shareable; local picks need an upload API first.
  final remoteImages =
      item.imageUrls.where((url) => url.startsWith('http')).toList();
  return {
    'feed_type': _feedTypeByCategory[item.category] ?? 'GENERAL',
    'title': item.title,
    'content': item.description,
    if (location != null) 'lat': location.latitude,
    if (location != null) 'lng': location.longitude,
    if (location != null) 'address': location.fullName,
    'extra': {
      'neighborhood': item.neighborhood,
      'price_or_condition': item.priceOrCondition,
      if (item.thumbnailUrl.startsWith('http'))
        'thumbnail_url': item.thumbnailUrl,
      'image_urls': remoteImages,
      'badges': item.badges.map((b) => b.name).toList(),
      'detail_meta': item.detailMeta,
      'cta_label': item.ctaLabel,
      'author_nickname': item.authorName,
    },
  };
}
