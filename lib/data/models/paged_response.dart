/// 공통 JSON DTO 자리. 여러 feature가 공유하는 페이징/에러 응답 모델을 둡니다.
class PagedResponse<T> {
  const PagedResponse({
    required this.items,
    required this.page,
    required this.total,
  });

  final List<T> items;
  final int page;
  final int total;
}
