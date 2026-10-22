import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../feed/domain/models/feed_extra_meta.dart';
import '../providers/create_post_provider.dart';
import '../widgets/create_post_scaffold.dart';
import '../widgets/image_picker_grid.dart';
import '../widgets/post_form_fields.dart';

/// 일반 / 중고 (`GENERAL`): is_free · can_negotiate. The server schema has no
/// price field, so a price belongs in the body text.
class GeneralCreateScreen extends ConsumerStatefulWidget {
  const GeneralCreateScreen({super.key});

  @override
  ConsumerState<GeneralCreateScreen> createState() =>
      _GeneralCreateScreenState();
}

class _GeneralCreateScreenState extends ConsumerState<GeneralCreateScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  List<XFile> _images = [];
  bool _isFree = false;
  bool _canNegotiate = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  CreatePostDraft _draft() {
    return CreatePostDraft(
      kind: CreatePostKind.general,
      title: _title.text,
      description: _body.text,
      images: _images,
      extraMeta: {
        ExtraMetaKeys.isFree: _isFree,
        ExtraMetaKeys.canNegotiate: !_isFree && _canNegotiate,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CreatePostScaffold(
      title: '일반글 작성',
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            '판매 가격이 있다면 내용에 함께 적어 주세요.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.md),
          CheckboxListTile(
            key: const ValueKey('field-is-free'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text('나눔하기', style: AppTypography.bodyLarge),
            value: _isFree,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _isFree = v ?? false),
          ),
          SwitchListTile(
            key: const ValueKey('field-can-negotiate'),
            contentPadding: EdgeInsets.zero,
            title: Text('가격 제안 받기', style: AppTypography.bodyLarge),
            value: !_isFree && _canNegotiate,
            activeThumbColor: AppColors.primary,
            onChanged: _isFree ? null : (v) => setState(() => _canNegotiate = v),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
