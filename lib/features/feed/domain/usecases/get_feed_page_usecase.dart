import '../entities/feed_item.dart';
import '../repositories/feed_repository.dart';

class GetFeedPageUseCase {
  const GetFeedPageUseCase(this._repository);

  final FeedRepository _repository;

  Future<List<FeedItem>> call({required int page, int pageSize = 10}) {
    return _repository.fetchPage(page: page, pageSize: pageSize);
  }
}
