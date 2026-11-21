import 'feed_extra_meta.dart';
import 'feed_item.dart';

/// `extra_meta.item_category` of public share facilities (SEOUL_SHARE / GG_SHARE).
enum ShareItemCategory {
  recycle('RECYCLE', '재활용센터'),
  facility('FACILITY', '공유시설'),
  share('SHARE', '공공나눔');

  const ShareItemCategory(this.code, this.label);
  final String code;
  final String label;

  static ShareItemCategory fromCode(Object? code) {
    final raw = code?.toString().trim().toUpperCase() ?? '';
    if (raw == 'RECYCLE') return ShareItemCategory.recycle;
    if (raw == 'FACILITY' ||
        raw == 'SHARE_FACILITY' ||
        raw == 'SHARED_FACILITY') {
      return ShareItemCategory.facility;
    }
    if (raw == 'SHARE' || raw == 'FLEA' || raw == 'MARKET') {
      return ShareItemCategory.share;
    }
    return ShareItemCategory.share;
  }
}

/// Parsed public share / recycle facility from `extra_meta` (+ content lines).
class PublicShareNotice {
  PublicShareNotice({
    required this.fields,
    required this.meta,
  });

  factory PublicShareNotice.parse(
    String content,
    Map<String, dynamic> extraMeta,
  ) {
    final fields = <String, String>{};
    for (final raw in content.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final match = _line.firstMatch(line);
      if (match == null || match.group(2)!.startsWith('//')) continue;
      fields.putIfAbsent(match.group(1)!.trim(), () => match.group(2)!.trim());
    }
    return PublicShareNotice(
      fields: fields,
      meta: FeedExtraMeta(FeedCategory.market, extraMeta),
    );
  }

  static final _line = RegExp(r'^([^:：]{1,12})[:：]\s*(.+)$');
  static final _bracketRegion = RegExp(r'\[([^\[\]]{1,20})\]');

  final Map<String, String> fields;
  final FeedExtraMeta meta;

  String? _field(String key) => fields[key];
  String? _metaString(String key) {
    final value = meta.values[key]?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  ShareItemCategory get itemCategory =>
      ShareItemCategory.fromCode(meta.values[ExtraMetaKeys.itemCategory]);

  String? get providerName =>
      _metaString(ExtraMetaKeys.providerName) ?? _field('운영');

  String get priceSummary {
    final fromMeta = _metaString(ExtraMetaKeys.priceSummary);
    if (fromMeta != null) return fromMeta;
    final fromField = _field('이용');
    if (fromField != null && fromField.isNotEmpty) return fromField;
    final label = meta.priceLabel;
    return label.isNotEmpty ? label : '센터 문의';
  }

  String? get detailUrl {
    final url = _metaString(ExtraMetaKeys.detailUrl);
    if (url != null && url.startsWith('http')) return url;
    final line = _field('안내');
    return line != null && line.startsWith('http') ? line : null;
  }

  String? get hoursLabel {
    final weekday = _field('평일 운영');
    final closed = _field('휴무');
    if (weekday != null && closed != null) return '$weekday · 휴무 $closed';
    return weekday ?? closed ?? _field('문의');
  }

  String? get itemsHandled => _field('취급');

  String? get addressField => _field('위치');

  /// 시설 지역: address, else first `[지역]` token in title (skip 공공 나눔).
  static String? regionFrom({String? address, String? title}) {
    final addr = address?.trim() ?? '';
    if (addr.isNotEmpty) return addr;
    for (final match in _bracketRegion.allMatches(title ?? '')) {
      final token = match.group(1)!.trim();
      if (token == '공공 나눔' || token == '공공나눔') continue;
      return token;
    }
    return null;
  }

  /// 나눔·공유 시설 정보 rows for the detail card.
  List<FeedDetailRow> summaryRows({String? address, String? title}) {
    final region = regionFrom(address: address, title: title) ?? addressField;
    return [
      if (providerName case final v?) FeedDetailRow('운영 기관', v),
      FeedDetailRow('이용 조건', priceSummary),
      if (itemsHandled case final v?) FeedDetailRow('취급 품목', v),
      FeedDetailRow('시설 유형', itemCategory.label),
      if (hoursLabel case final v?) FeedDetailRow('운영 안내', v),
      if (region case final v?) FeedDetailRow('위치', v),
      if (detailUrl case final v?) FeedDetailRow('안내', v),
    ];
  }
}
