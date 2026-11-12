import 'feed_extra_meta.dart';
import 'feed_item.dart';

/// `extra_meta.housing_type` of public housing notices (LH 마이홈 etc.).
enum HousingType {
  publicRental('PUBLIC_RENTAL', '공공임대'),
  happyHouse('HAPPY_HOUSE', '행복주택'),
  youthHouse('YOUTH_HOUSE', '청년주택');

  const HousingType(this.code, this.label);
  final String code;
  final String label;

  /// Unknown / missing codes read as 공공임대.
  static HousingType fromCode(Object? code) => values.firstWhere(
        (e) => e.code == code,
        orElse: () => HousingType.publicRental,
      );
}

/// A public housing notice: `content` holds "키: 값" lines (공급기관, 모집 기간,
/// 당첨자 발표, 문의, 임대 조건, …); structured `extra_meta` wins where present
/// (모집 기간, 신청 URL, 보증금 / 월세).
class PublicHousingNotice {
  PublicHousingNotice({
    required this.fields,
    required this.meta,
  });

  factory PublicHousingNotice.parse(
    String content,
    Map<String, dynamic> extraMeta,
  ) {
    final fields = <String, String>{};
    for (final line in content.split('\n')) {
      final match = _line.firstMatch(line.trim());
      if (match == null) continue;
      fields.putIfAbsent(match.group(1)!.trim(), () => match.group(2)!.trim());
    }
    return PublicHousingNotice(
      fields: fields,
      meta: FeedExtraMeta(FeedCategory.housing, extraMeta),
    );
  }

  static final _line = RegExp(r'^([^:：]{1,10})[:：]\s*(.+)$');

  /// Parsed "키: 값" lines in content order.
  final Map<String, String> fields;
  final FeedExtraMeta meta;

  String? _field(String key) => fields[key];

  String? get supplier => _field('공급기관');
  String? get supplyType => _field('공급유형');
  String? get buildingType => _field('주택유형');
  String? get complex => _field('단지');
  String? get units => _field('공급호수');
  String? get noticeDate => _field('공고일');
  String? get winnerDate => _field('당첨자 발표');
  String? get contact => _field('문의');
  String? get rentTerms => _field('임대 조건');
  String? get address => _field('주소');

  /// 모집 기간: `event_start_date` ~ `event_end_date`, else the content line.
  String? get applyPeriod {
    final label = meta.eventPeriodLabel;
    if (label.isNotEmpty) return label;
    return _field('모집 기간');
  }

  /// 신청 URL: `apply_url`, else the content line.
  String? get applyUrl {
    final url = meta.values[ExtraMetaKeys.applyUrl]?.toString().trim() ?? '';
    if (url.isNotEmpty) return url;
    final line = _field('신청');
    return line != null && line.startsWith('http') ? line : null;
  }

  /// Card price slot: 임대 조건 line → structured 보증금 / 월세 → fallback.
  String get rentSummary {
    final terms = rentTerms;
    if (terms != null && terms.isNotEmpty) return terms;
    final deposit = meta.deposit ?? 0;
    final rent = meta.monthlyRent ?? 0;
    if (deposit > 0 || rent > 0) {
      return [
        if (deposit > 0) '보증금 ${formatNumber(deposit)}만',
        if (rent > 0) '월 ${formatNumber(rent)}만',
      ].join(' · ');
    }
    return '임대 조건은 공고문 참고';
  }

  /// 공고 정보 card rows: application facts first, then the notice details.
  List<FeedDetailRow> get rows => [
        if (applyPeriod case final v?) FeedDetailRow('모집 기간', v),
        if (winnerDate case final v?) FeedDetailRow('당첨자 발표', v),
        if (contact case final v?) FeedDetailRow('문의', v),
        if (applyUrl case final v?) FeedDetailRow('신청', v),
        if (supplier case final v?) FeedDetailRow('공급기관', v),
        if (supplyType case final v?) FeedDetailRow('공급유형', v),
        if (buildingType case final v?) FeedDetailRow('주택유형', v),
        if (complex case final v?) FeedDetailRow('단지', v),
        if (units case final v?) FeedDetailRow('공급호수', v),
        if (rentTerms case final v?) FeedDetailRow('임대 조건', v),
        if (noticeDate case final v?) FeedDetailRow('공고일', v),
        if (address case final v?) FeedDetailRow('주소', v),
      ];
}
