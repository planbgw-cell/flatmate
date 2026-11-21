import 'feed_extra_meta.dart';
import 'feed_item.dart';

/// `extra_meta.job_type` of public job notices (SEOUL_JOB / GG_JOB etc.).
enum PublicJobType {
  publicWork('PUBLIC_WORK', '공공일자리'),
  contract('CONTRACT', '단기알바'),
  intern('INTERN', '청년인턴'),
  partTime('PART_TIME', '단기알바');

  const PublicJobType(this.code, this.label);
  final String code;
  final String label;

  static PublicJobType fromCode(Object? code) => values.firstWhere(
        (e) => e.code == code,
        orElse: () => PublicJobType.publicWork,
      );
}

/// Parsed public job notice from `extra_meta` (+ content "키: 값" fallbacks).
class PublicJobNotice {
  PublicJobNotice({
    required this.fields,
    required this.meta,
  });

  factory PublicJobNotice.parse(
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
    return PublicJobNotice(
      fields: fields,
      meta: FeedExtraMeta(FeedCategory.job, extraMeta),
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

  PublicJobType get jobType =>
      PublicJobType.fromCode(meta.values[ExtraMetaKeys.jobType]);

  String? get companyName =>
      _metaString(ExtraMetaKeys.companyName) ?? _field('모집 기관');

  String get wageSummary {
    final fromMeta = _metaString(ExtraMetaKeys.wageSummary);
    if (fromMeta != null) return fromMeta;
    final fromField = _field('급여');
    if (fromField != null && fromField.isNotEmpty) return fromField;
    final label = meta.priceLabel;
    return label.isNotEmpty ? label : '공고문 참고';
  }

  String? get workHours =>
      _metaString(ExtraMetaKeys.workHours) ?? _field('근무 시간');

  String? get applyUrl {
    final url = _metaString(ExtraMetaKeys.applyUrl);
    if (url != null && url.startsWith('http')) return url;
    final line = _field('신청') ?? _field('상세·신청');
    return line != null && line.startsWith('http') ? line : null;
  }

  /// 모집/접수 기간 label from event dates or content.
  String? get applyPeriod {
    final label = meta.eventPeriodLabel;
    if (label.isNotEmpty) return label;
    return _field('모집 기간') ?? _field('접수 기간');
  }

  /// Single end-date for card ("접수 마감 2026.12.31").
  String? get deadlineLabel {
    final end = meta.values[ExtraMetaKeys.eventEndDate]?.toString().trim();
    if (end == null || end.isEmpty) return null;
    final formatted = end.contains('-') ? end.replaceAll('-', '.') : end;
    return formatted.length >= 10 ? formatted.substring(0, 10) : formatted;
  }

  /// 근무 지역: address, else first `[양평군]`-style token in title, else null.
  static String? regionFrom({String? address, String? title}) {
    final addr = address?.trim() ?? '';
    if (addr.isNotEmpty) return addr;
    for (final match in _bracketRegion.allMatches(title ?? '')) {
      final token = match.group(1)!.trim();
      if (token == '공공 일자리' || token == '공공일자리') continue;
      return token;
    }
    return null;
  }

  /// 채용 핵심 정보 rows for the detail card.
  List<FeedDetailRow> summaryRows({String? address, String? title}) {
    final region = regionFrom(address: address, title: title);
    return [
      if (companyName case final v?) FeedDetailRow('모집 기관', v),
      FeedDetailRow('급여 조건', wageSummary),
      if (workHours case final v?) FeedDetailRow('근무 시간', v),
      FeedDetailRow('근무 형태', jobType.label),
      if (deadlineLabel case final v?) FeedDetailRow('접수 마감', v),
      if (applyPeriod case final v?) FeedDetailRow('모집 기간', v),
      if (region case final v?) FeedDetailRow('근무 지역', v),
      if (applyUrl case final v?) FeedDetailRow('신청', v),
    ];
  }
}
