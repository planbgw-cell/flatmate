/// `ReportCreate.reason` values accepted by `POST /reports/feeds`.
enum ReportReason {
  spam('SPAM', '스팸/광고'),
  inappropriate('INAPPROPRIATE', '부적절한 내용'),
  fraud('FRAUD', '사기 의심'),
  other('OTHER', '기타');

  const ReportReason(this.code, this.label);
  final String code;
  final String label;
}
