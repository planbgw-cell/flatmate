import '../entities/local_post.dart';

abstract class LocalLifeRepository {
  Future<List<LocalPost>> fetchPosts();
}
