import '../models/local_post_model.dart';

abstract class LocalLifeRemoteDataSource {
  Future<List<LocalPostModel>> fetchPosts();
}

class LocalLifeRemoteDataSourceStub implements LocalLifeRemoteDataSource {
  @override
  Future<List<LocalPostModel>> fetchPosts() async {
    return [
      LocalPostModel(
        id: 'l-1',
        title: '신촌 맛집 공유 — 저녁 혼밥 추천',
        neighborhood: '신촌',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      LocalPostModel(
        id: 'l-2',
        title: '홍대 단기임대 체크리스트',
        neighborhood: '홍대',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
