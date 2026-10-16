import '../../domain/entities/local_post.dart';
import '../../domain/repositories/local_life_repository.dart';
import '../datasources/local_life_remote_datasource.dart';

class LocalLifeRepositoryImpl implements LocalLifeRepository {
  LocalLifeRepositoryImpl(this._remote);

  final LocalLifeRemoteDataSource _remote;

  @override
  Future<List<LocalPost>> fetchPosts() async {
    final models = await _remote.fetchPosts();
    return models.map((model) => model.toEntity()).toList();
  }
}
