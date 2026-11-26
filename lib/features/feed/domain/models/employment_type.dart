/// Request filter for `GET /feeds?employment_type=` (job chip only).
/// Separate from response [PublicJobType] / `extra_meta.job_type`.
enum EmploymentType {
  all('ALL', '전체'),
  partTime('PART_TIME', '단기·알바'),
  intern('INTERN', '청년인턴'),
  public('PUBLIC', '공공일자리');

  const EmploymentType(this.code, this.label);

  final String code;
  final String label;

  static EmploymentType fromCode(Object? code) => values.firstWhere(
        (e) => e.code == code?.toString().toUpperCase(),
        orElse: () => EmploymentType.all,
      );
}
