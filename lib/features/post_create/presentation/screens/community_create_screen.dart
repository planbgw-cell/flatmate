import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../../domain/post_image.dart';
import '../providers/create_post_provider.dart';
import '../widgets/create_post_scaffold.dart';
import '../widgets/image_picker_grid.dart';
import '../widgets/post_form_fields.dart';

/// 동네소식 (`LOCAL_NEWS`): photos · title · body, no `extra_meta`.
class CommunityCreateScreen extends ConsumerStatefulWidget {
  const CommunityCreateScreen({super.key, this.targetFeed});

  /// Edit mode (`PATCH /feeds/{id}`) when set; fields are prefilled from it.
  final FeedItem? targetFeed;

  @override
  ConsumerState<CommunityCreateScreen> createState() =>
      _CommunityCreateScreenState();
}

class _CommunityCreateScreenState extends ConsumerState<CommunityCreateScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  List<PostImage> _images = [];

  @override
  void initState() {
    super.initState();
    final target = widget.targetFeed;
    if (target == null) return;
    _title.text = target.title;
    _body.text = target.description;
    _images = remotePostImages(target);
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  CreatePostDraft _draft() {
    return CreatePostDraft(
      kind: CreatePostKind.community,
      title: _title.text,
      description: _body.text,
      images: _images,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CreatePostScaffold(
      title: widget.targetFeed == null ? '동네소식 쓰기' : '글 수정하기',
      editing: widget.targetFeed,
      buildDraft: _draft,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImagePickerGrid(
            images: _images,
            onChanged: (next) => setState(() => _images = next),
          ),
          const SizedBox(height: AppSpacing.lg),
          PostFormFields(
            titleController: _title,
            bodyController: _body,
            showPrice: false,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
