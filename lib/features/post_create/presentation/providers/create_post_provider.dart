import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../../../feed/domain/repositories/feed_repository.dart';
import '../../../feed/presentation/providers/feed_provider.dart';
import '../../../location/presentation/providers/location_provider.dart';

enum CreatePostKind { realEstate, job, general }

class CreatePostDraft {
  const CreatePostDraft({
    required this.kind,
    required this.title,
    required this.description,
    required this.priceOrCondition,
    this.imageUrls = const [],
    this.badges = const [],
    this.detailMeta = const {},
    this.ctaLabel,
  });

  final CreatePostKind kind;
  final String title;
  final String description;
  final String priceOrCondition;
  final List<String> imageUrls;
  final List<FeedBadge> badges;
  final Map<String, String> detailMeta;
  final String? ctaLabel;
}

class CreatePostException implements Exception {
  CreatePostException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CreatePostNotifier extends AsyncNotifier<void> {
  FeedRepository get _repo => sl<FeedRepository>();

  @override
  Future<void> build() async {}

  /// Validates + creates post, then refreshes the home feed.
  Future<FeedItem> submit(CreatePostDraft draft) async {
    final title = draft.title.trim();
    final body = draft.description.trim();
    if (title.length < 2) {
      throw CreatePostException('제목은 2자 이상 입력해 주세요.');
    }
    if (body.isEmpty) {
      throw CreatePostException('내용을 입력해 주세요.');
    }
    if (draft.priceOrCondition.trim().isEmpty) {
      throw CreatePostException(
        draft.kind == CreatePostKind.job
            ? '급여(시급/일급/월급)를 입력해 주세요.'
            : '가격 또는 조건을 입력해 주세요.',
      );
    }

    state = const AsyncLoading();
    try {
      final location = ref.read(currentLocationProvider);
      final category = switch (draft.kind) {
        CreatePostKind.realEstate => FeedCategory.housing,
        CreatePostKind.job => FeedCategory.job,
        CreatePostKind.general => FeedCategory.market,
      };
      final thumb = draft.imageUrls.isNotEmpty
          ? draft.imageUrls.first
          : 'https://picsum.photos/seed/flatnew${DateTime.now().millisecondsSinceEpoch}/400/400';

      final item = FeedItem(
        id: 'f-new-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        neighborhood: location.dongName,
        postedAt: DateTime.now(),
        priceOrCondition: draft.priceOrCondition.trim(),
        thumbnailUrl: thumb,
        imageUrls: draft.imageUrls,
        likeCount: 0,
        chatCount: 0,
        category: category,
        badges: draft.badges,
        isBumped: false,
        description: body,
        authorName: ref.read(authProvider).value?.nickname ?? '나',
        authorId: ref.read(currentUserIdProvider),
        trustScore: 40.0,
        ctaLabel: draft.ctaLabel ??
            (draft.kind == CreatePostKind.job ? '지원하기' : '채팅하기'),
        verificationCount: 1,
        detailMeta: draft.detailMeta,
      );

      final created = await _repo.createPost(item, location: location);
      ref.invalidate(feedListProvider);
      state = const AsyncData(null);
      return created;
    } catch (error, stack) {
      state = AsyncError(error, stack);
      rethrow;
    }
  }
}

final createPostProvider =
    AsyncNotifierProvider<CreatePostNotifier, void>(CreatePostNotifier.new);
