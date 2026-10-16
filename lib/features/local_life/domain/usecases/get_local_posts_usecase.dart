import '../entities/local_post.dart';
import '../repositories/local_life_repository.dart';

class GetLocalPostsUseCase {
  const GetLocalPostsUseCase(this._repository);

  final LocalLifeRepository _repository;

  Future<List<LocalPost>> call() => _repository.fetchPosts();
}
