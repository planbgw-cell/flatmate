import 'feed_item.dart';

/// `extra_meta` vocabulary validated by the server per `feed_type`
/// (unknown keys are rejected).
abstract final class ExtraMetaKeys {
  // REAL_ESTATE — deposit / rent / fee in 만원.
  static const roomType = 'room_type';
  static const deposit = 'deposit';
  static const monthlyRent = 'monthly_rent';
  static const maintenanceFee = 'maintenance_fee';
  static const isShortTerm = 'is_short_term';

  // JOB — pay_amount in 원; work_days is a comma-joined string ("월,수,금").
  static const payType = 'pay_type';
  static const payAmount = 'pay_amount';
  static const workPeriod = 'work_period';
  static const workDays = 'work_days';
  static const workHours = 'work_hours';

  // GENERAL — price in 원 (server stores 0 for 나눔).
  static const price = 'price';
  static const isFree = 'is_free';
  static const canNegotiate = 'can_negotiate';
}

enum RoomType {
  oneRoom('ONE_ROOM', '원룸'),
  twoRoom('TWO_ROOM', '투룸'),
  threeRoom('THREE_ROOM', '쓰리룸'),
  officetel('OFFICETEL', '오피스텔');

  const RoomType(this.code, this.label);
  final String code;
  final String label;

  static RoomType? fromCode(Object? code) =>
      values.where((e) => e.code == code).firstOrNull;
}

enum PayType {
  hourly('HOURLY', '시급'),
  monthly('MONTHLY', '월급');

  const PayType(this.code, this.label);
  final String code;
  final String label;

  static PayType? fromCode(Object? code) =>
      values.where((e) => e.code == code).firstOrNull;
}

const kWorkDayOptions = ['월', '화', '수', '목', '금', '토', '일'];
const kWorkPeriodOptions = ['하루', '1주일 이하', '1개월 이하', '3개월 이하', '6개월 이상'];

class FeedDetailRow {
  const FeedDetailRow(this.label, this.value);
  final String label;
  final String value;
}

/// Read-side helpers turning `extra_meta` into display strings.
class FeedExtraMeta {
  const FeedExtraMeta(this.category, this.values);

  final FeedCategory category;
  final Map<String, dynamic> values;

  /// Written by the structured create forms (vs. legacy free-form posts).
  bool get isStructured => switch (category) {
        FeedCategory.housing => values.containsKey(ExtraMetaKeys.roomType),
        FeedCategory.job => values.containsKey(ExtraMetaKeys.payType),
        FeedCategory.market => values.containsKey(ExtraMetaKeys.isFree) ||
            values.containsKey(ExtraMetaKeys.canNegotiate) ||
            values.containsKey(ExtraMetaKeys.price),
        _ => false,
      };

  RoomType? get roomType => RoomType.fromCode(values[ExtraMetaKeys.roomType]);
  int? get deposit => _int(ExtraMetaKeys.deposit);
  int? get monthlyRent => _int(ExtraMetaKeys.monthlyRent);
  int? get maintenanceFee => _int(ExtraMetaKeys.maintenanceFee);
  bool get isShortTerm => values[ExtraMetaKeys.isShortTerm] == true;

  PayType? get payType => PayType.fromCode(values[ExtraMetaKeys.payType]);
  int? get payAmount => _int(ExtraMetaKeys.payAmount);
  String? get workPeriod => _string(ExtraMetaKeys.workPeriod);
  String? get workHours => _string(ExtraMetaKeys.workHours);
  List<String> get workDays =>
      (_string(ExtraMetaKeys.workDays) ?? '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

  int? get price => _int(ExtraMetaKeys.price);
  bool get isFree => values[ExtraMetaKeys.isFree] == true;
  bool get canNegotiate => values[ExtraMetaKeys.canNegotiate] == true;

  /// Local price line (mock / offline); real posts use the server `price_text`.
  String get priceLabel => switch (category) {
        FeedCategory.housing =>
          '보증금 ${formatNumber(deposit ?? 0)} / 월세 ${formatNumber(monthlyRent ?? 0)}',
        FeedCategory.job => payAmount == null
            ? ''
            : '${payType?.label ?? '급여'} ${formatNumber(payAmount!)}원',
        FeedCategory.market => isFree
            ? '나눔'
            : (price != null && price! > 0)
                ? '${formatNumber(price!)}원'
                : '가격 문의',
        _ => '',
      };

  List<FeedDetailRow> get rows => switch (category) {
        FeedCategory.housing => [
            FeedDetailRow('방 종류', roomType?.label ?? '-'),
            FeedDetailRow('보증금', _manwon(deposit)),
            FeedDetailRow('월세', _manwon(monthlyRent)),
            FeedDetailRow(
              '관리비',
              maintenanceFee == null || maintenanceFee == 0
                  ? '없음'
                  : _manwon(maintenanceFee),
            ),
            FeedDetailRow('단기임대', isShortTerm ? '가능' : '불가'),
          ],
        FeedCategory.job => [
            FeedDetailRow('급여', priceLabel.isEmpty ? '-' : priceLabel),
            FeedDetailRow('근무 기간', workPeriod ?? '협의'),
            FeedDetailRow(
              '근무 요일',
              workDays.isEmpty ? '협의' : workDays.join('·'),
            ),
            FeedDetailRow('근무 시간', workHours ?? '협의'),
          ],
        FeedCategory.market => [
            FeedDetailRow('거래 방식', isFree ? '나눔' : '판매'),
            if (!isFree) FeedDetailRow('가격', priceLabel),
            FeedDetailRow('가격 제안', canNegotiate ? '가능' : '불가'),
          ],
        _ => const [],
      };

  List<FeedBadge> get badges => switch (category) {
        FeedCategory.housing => [
            FeedBadge.housing,
            if (isShortTerm) FeedBadge.shortStay,
          ],
        FeedCategory.job => const [FeedBadge.recruiting],
        FeedCategory.market => [
            FeedBadge.market,
            if (isFree) FeedBadge.sharing,
          ],
        _ => const [],
      };

  int? _int(String key) => (values[key] as num?)?.toInt();

  String? _string(String key) {
    final value = values[key]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  static String _manwon(int? value) =>
      value == null ? '-' : '${formatNumber(value)}만원';
}

/// 1234567 → "1,234,567".
String formatNumber(int value) {
  final digits = value.abs().toString();
  final buf = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    buf.write(digits[i]);
    final remaining = digits.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) buf.write(',');
  }
  return buf.toString();
}
