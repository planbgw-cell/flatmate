import '../../../../core/network/media_url.dart';
import '../../../location/domain/models/location_item.dart';
import '../../domain/models/feed_extra_meta.dart';
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

String? _nonEmpty(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

List<String> _stringList(Object? raw) => raw is List
    ? raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
    : const [];

/// `FeedOut` → [FeedItem].
///
/// Structured posts carry typed `extra_meta` (see [ExtraMetaKeys]); posts
/// written before the schema change still hold display keys there
/// (`price_or_condition`, `detail_meta`, `neighborhood`, …).
FeedItem feedItemFromJson(Map<String, dynamic> json) {
  final metaRaw = json['extra_meta'] ?? json['extra'];
  final meta = metaRaw is Map
      ? Map<String, dynamic>.from(metaRaw)
      : const <String, dynamic>{};
  final category = categoryForFeedType(json['feed_type']?.toString());
  final typed = FeedExtraMeta(category, meta);

  var images = _stringList(json['image_urls']);
  if (images.isEmpty) images = _stringList(meta['image_urls']);
  images = images.map(resolveMediaUrl).toList();
  final thumbnail = resolveMediaUrl(
    json['thumbnail_url']?.toString() ??
        (images.isNotEmpty ? images.first : meta['thumbnail_url']?.toString()),
  );

  final legacyBadges = <FeedBadge>[
    for (final b in (meta['badges'] as List?) ?? const [])
      ...FeedBadge.values.where((e) => e.name == b.toString()),
  ];
  final legacyDetail = <String, String>{};
  final legacyDetailRaw = meta['detail_meta'];
  if (legacyDetailRaw is Map) {
    legacyDetailRaw.forEach((key, value) {
      legacyDetail[key.toString()] = value.toString();
    });
  }

  final address = json['address']?.toString() ?? '';
  final neighborhood = meta['neighborhood']?.toString() ??
      (address.isEmpty ? '' : address.split(' ').last);

  final postedAt = DateTime.tryParse(json['published_at']?.toString() ?? '') ??
      DateTime.tryParse(json['created_at']?.toString() ?? '') ??
      DateTime.now();

  return FeedItem(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    neighborhood: neighborhood,
    postedAt: postedAt.toLocal(),
    // Server-formatted text first ("15,000원", "월세 500/45", "나눔").
    priceOrCondition: _nonEmpty(json['price_text']) ??
        (typed.isStructured
            ? typed.priceLabel
            : meta['price_or_condition']?.toString() ?? ''),
    thumbnailUrl: thumbnail,
    imageUrls: images,
    likeCount: (json['like_count'] as num?)?.toInt() ??
        (meta['like_count'] as num?)?.toInt() ??
        0,
    isFavorite: json['is_liked'] as bool? ?? false,
    tradeStatus: TradeStatus.fromCode(json['trade_status']),
    chatCount: (meta['chat_count'] as num?)?.toInt() ?? 0,
    category: category,
    badges: typed.isStructured ? typed.badges : legacyBadges,
    isBumped: meta['is_bumped'] as bool? ?? false,
    description: json['content']?.toString() ?? '',
    // Collected (external) feeds have no author → "이웃".
    authorName: _nonEmpty(json['author_nickname']) ??
        _nonEmpty(meta['author_nickname']) ??
        '이웃',
    authorAvatarUrl: _nonEmpty(
      resolveMediaUrl(json['author_profile_image']?.toString()),
    ),
    authorId: json['author_id']?.toString(),
    ctaLabel: meta['cta_label']?.toString() ??
        (category == FeedCategory.job ? '지원하기' : '채팅하기'),
    detailMeta: typed.isStructured
        ? {for (final row in typed.rows) row.label: row.value}
        : legacyDetail,
    extraMeta: meta,
  );
}

/// `FeedUpdate` body for `PATCH /feeds/{id}` (all editable fields).
Map<String, dynamic> feedUpdateToJson({
  required String title,
  required String content,
  required Map<String, dynamic> extraMeta,
  required List<String> imageUrls,
}) {
  return {
    'title': title,
    'content': content,
    'extra_meta': extraMeta,
    'image_urls': imageUrls,
  };
}

/// [FeedItem] → `FeedCreate` body for `POST /feeds`.
///
/// [FeedItem.imageUrls] must hold the URLs returned by `POST /uploads/images`;
/// `extra_meta` only accepts the per-type keys (no display helpers).
Map<String, dynamic> feedCreateToJson(FeedItem item, {LocationItem? location}) {
  return {
    'feed_type': _feedTypeByCategory[item.category] ?? 'GENERAL',
    'title': item.title,
    'content': item.description,
    if (location != null) 'lat': location.latitude,
    if (location != null) 'lng': location.longitude,
    if (location != null) 'address': location.fullName,
    'image_urls': item.imageUrls,
    'extra_meta': item.extraMeta,
  };
}
