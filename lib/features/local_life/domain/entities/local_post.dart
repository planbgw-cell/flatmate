class LocalPost {
  const LocalPost({
    required this.id,
    required this.title,
    required this.neighborhood,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String neighborhood;
  final DateTime createdAt;
}
