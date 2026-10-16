import '../../domain/entities/local_post.dart';

class LocalPostModel {
  const LocalPostModel({
    required this.id,
    required this.title,
    required this.neighborhood,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String neighborhood;
  final DateTime createdAt;

  LocalPost toEntity() => LocalPost(
        id: id,
        title: title,
        neighborhood: neighborhood,
        createdAt: createdAt,
      );
}
