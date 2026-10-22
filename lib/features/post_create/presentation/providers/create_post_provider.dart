import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/media_url.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../feed/domain/models/feed_extra_meta.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../../../feed/domain/repositories/feed_repository.dart';
import '../../../feed/presentation/providers/feed_provider.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../data/image_picker_service.dart';
import '../../data/image_upload_service.dart';
import '../../domain/post_image.dart';

enum CreatePostKind { realEstate, job, general }

class CreatePostDraft {
  const CreatePostDraft({
    required this.kind,
    required this.title,
    required this.description,
    this.images = const [],
    this.extraMeta = const {},
  });

  final CreatePostKind kind;
  final String title;
  final String description;

  /// Existing server photos and new local ones in display order; the first
  /// one becomes the thumbnail.
  final List<PostImage> images;

  /// Per-type `extra_meta` (see [ExtraMetaKeys]).
  final Map<String, dynamic> extraMeta;

  FeedCategory get category => switch (kind) {
        CreatePostKind.realEstate => FeedCategory.housing,
        CreatePostKind.job => FeedCategory.job,
        CreatePostKind.general => FeedCategory.market,
      };
}

class CreatePostException implements Exception {
  CreatePostException(this.message);
  final String message;

  @override
  String toString() => message;
}

enum CreatePostPhase {
  idle(''),
  uploading('사진 업로드 중…'),
  saving('등록 중…'),
  updating('수정 중…');

  const CreatePostPhase(this.label);
  final String label;
}

final postImagePickerProvider = Provider<PostImagePicker>((ref) {
  return PostImagePicker();
});

final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  return sl<ImageUploadService>();
});

class CreatePostNotifier extends Notifier<CreatePostPhase> {
  FeedRepository get _repo => ref.read(feedRepositoryProvider);

  @override
  CreatePostPhase build() => CreatePostPhase.idle;

  /// Validates → uploads new photos → creates the post (or, with [editing],
  /// `PATCH`es it) → refreshes the feed / detail copies.
  Future<FeedItem> submit(CreatePostDraft draft, {FeedItem? editing}) async {
    final title = draft.title.trim();
    final body = draft.description.trim();
    if (title.length < 2) {
      throw CreatePostException('제목은 2자 이상 입력해 주세요.');
    }
    if (body.isEmpty) {
      throw CreatePostException('내용을 입력해 주세요.');
    }
    final metaError = validateExtraMeta(draft.kind, draft.extraMeta);
    if (metaError != null) throw CreatePostException(metaError);

    try {
      final locals = [
        for (final image in draft.images)
          if (image is LocalPostImage) image.file,
      ];
      state = CreatePostPhase.uploading;
      final uploaded = locals.isEmpty
          ? const <String>[]
          : await ref.read(imageUploadServiceProvider).upload(locals);
      var next = 0;
      final imageUrls = [
        for (final image in draft.images)
          switch (image) {
            RemotePostImage(:final url) => toServerMediaPath(url),
            LocalPostImage() => uploaded[next++],
          },
      ];

      if (editing != null) {
        state = CreatePostPhase.updating;
        return await _update(editing, title, body, draft.extraMeta, imageUrls);
      }

      state = CreatePostPhase.saving;
      final location = ref.read(currentLocationProvider);
      final item = FeedItem(
        id: 'f-new-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        neighborhood: location.dongName,
        postedAt: DateTime.now(),
        priceOrCondition:
            FeedExtraMeta(draft.category, draft.extraMeta).priceLabel,
        thumbnailUrl: imageUrls.isEmpty ? '' : imageUrls.first,
        imageUrls: imageUrls,
        likeCount: 0,
        chatCount: 0,
        category: draft.category,
        badges: FeedExtraMeta(draft.category, draft.extraMeta).badges,
        isBumped: false,
        description: body,
        authorName: ref.read(authProvider).value?.nickname ?? '나',
        authorId: ref.read(currentUserIdProvider),
        extraMeta: draft.extraMeta,
      );
      final created = await _repo.createPost(item, location: location);
      ref.invalidate(feedListProvider);
      return created;
    } finally {
      state = CreatePostPhase.idle;
    }
  }

  Future<FeedItem> _update(
    FeedItem editing,
    String title,
    String body,
    Map<String, dynamic> extraMeta,
    List<String> imageUrls,
  ) async {
    final server = await _repo.updateFeed(
      editing.id,
      title: title,
      content: body,
      extraMeta: extraMeta,
      imageUrls: imageUrls,
    );
    final updated = server.copyWith(
      isFavorite: editing.isFavorite,
      likeCount: editing.likeCount,
      chatCount: editing.chatCount,
      tradeStatus: editing.tradeStatus,
    );
    ref.read(feedOverridesProvider.notifier).update(
          (map) => {...map, editing.id: updated},
        );
    ref.read(feedListProvider.notifier).patchItem(updated);
    ref.read(feedMutationTickProvider.notifier).state++;
    return updated;
  }
}

/// Mirrors the server's required `extra_meta` fields with Korean messages.
String? validateExtraMeta(CreatePostKind kind, Map<String, dynamic> meta) {
  switch (kind) {
    case CreatePostKind.realEstate:
      if (RoomType.fromCode(meta[ExtraMetaKeys.roomType]) == null) {
        return '방 종류를 선택해 주세요.';
      }
      if (meta[ExtraMetaKeys.deposit] is! int) return '보증금을 입력해 주세요.';
      if (meta[ExtraMetaKeys.monthlyRent] is! int) return '월세를 입력해 주세요.';
    case CreatePostKind.job:
      if (PayType.fromCode(meta[ExtraMetaKeys.payType]) == null) {
        return '급여 조건(시급/월급)을 선택해 주세요.';
      }
      final amount = meta[ExtraMetaKeys.payAmount];
      if (amount is! int || amount <= 0) return '급여 금액을 입력해 주세요.';
    case CreatePostKind.general:
      // Without a price the server stores 0 and returns no price_text.
      final price = meta[ExtraMetaKeys.price];
      if (meta[ExtraMetaKeys.isFree] != true && (price is! int || price <= 0)) {
        return '가격을 입력해 주세요. (무료라면 나눔하기를 선택해 주세요)';
      }
  }
  return null;
}

final createPostProvider =
    NotifierProvider<CreatePostNotifier, CreatePostPhase>(
  CreatePostNotifier.new,
);
