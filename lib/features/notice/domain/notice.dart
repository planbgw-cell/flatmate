/// `NoticeOut` from `GET /notices` (written in flatmate_admin).
class Notice {
  const Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    DateTime parse(Object? value) =>
        DateTime.tryParse(value?.toString() ?? '')?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final createdAt = parse(json['created_at']);
    return Notice(
      id: (json['id'] as num).toInt(),
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      isPinned: json['is_pinned'] == true,
      createdAt: createdAt,
      updatedAt:
          json['updated_at'] == null ? createdAt : parse(json['updated_at']),
    );
  }

  final int id;
  final String title;
  final String content;

  /// 상단 고정 (필독).
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Pinned first, then newest first (the server order, enforced locally).
List<Notice> sortNotices(Iterable<Notice> notices) => notices.toList()
  ..sort((a, b) {
    if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
    return b.createdAt.compareTo(a.createdAt);
  });
