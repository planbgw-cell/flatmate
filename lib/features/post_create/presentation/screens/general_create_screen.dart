import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../providers/create_post_provider.dart';
import '../widgets/create_post_scaffold.dart';
import '../widgets/image_picker_grid.dart';
import '../widgets/post_form_fields.dart';

class GeneralCreateScreen extends ConsumerStatefulWidget {
  const GeneralCreateScreen({super.key});

  @override
  ConsumerState<GeneralCreateScreen> createState() =>
      _GeneralCreateScreenState();
}

class _GeneralCreateScreenState extends ConsumerState<GeneralCreateScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _price = TextEditingController();

  List<String> _images = [];
  bool _offerEnabled = false;
  bool _isSharing = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _price.dispose();
    super.dispose();
  }

  CreatePostDraft _draft() {
    final priceText = _isSharing
        ? '나눔'
        : (_price.text.trim().isEmpty
            ? ''
            : '${_format(_price.text.trim())}원');

    final badges = <FeedBadge>[
      FeedBadge.market,
      if (_isSharing) FeedBadge.sharing,
    ];

    return CreatePostDraft(
      kind: CreatePostKind.general,
      title: _title.text,
      description: _body.text,
      priceOrCondition: priceText,
      imageUrls: _images,
      badges: badges,
      detailMeta: {
        '가격': priceText.isEmpty ? '-' : priceText,
        '가격 제안': _offerEnabled ? '가능' : '불가',
        '나눔': _isSharing ? '예' : '아니오',
      },
    );
  }

  String _format(String digits) {
    if (digits.isEmpty) return digits;
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final reverse = digits.length - i;
      buf.write(digits[i]);
      if (reverse > 1 && reverse % 3 == 1) buf.write(',');
    }
    return buf.toString();
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
            priceController: _price,
            priceLabel: '가격',
            priceHint: '희망 가격',
            showPrice: !_isSharing,
          ),
          const SizedBox(height: AppSpacing.md),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text('가격 제안 받기', style: AppTypography.bodyLarge),
            value: _offerEnabled,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _offerEnabled = v ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text('나눔', style: AppTypography.bodyLarge),
            value: _isSharing,
            activeColor: AppColors.primary,
            onChanged: (v) {
              setState(() {
                _isSharing = v ?? false;
                if (_isSharing) _price.clear();
              });
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
