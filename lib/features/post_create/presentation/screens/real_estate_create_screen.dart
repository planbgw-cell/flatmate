import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../providers/create_post_provider.dart';
import '../widgets/create_post_scaffold.dart';
import '../widgets/image_picker_grid.dart';
import '../widgets/post_form_fields.dart';

class RealEstateCreateScreen extends ConsumerStatefulWidget {
  const RealEstateCreateScreen({super.key});

  @override
  ConsumerState<RealEstateCreateScreen> createState() =>
      _RealEstateCreateScreenState();
}

class _RealEstateCreateScreenState
    extends ConsumerState<RealEstateCreateScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _deposit = TextEditingController();
  final _rent = TextEditingController();
  final _maintenance = TextEditingController();

  List<String> _images = [];
  Set<String> _housingType = {'원룸'};
  Set<String> _options = {};

  static const _housingOptions = ['원룸', '투룸+', '셰어하우스/룸메', '단기임대'];
  static const _amenityOptions = ['엘리베이터', '주차가능', '반려동물 가능', '여성전용'];

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _deposit.dispose();
    _rent.dispose();
    _maintenance.dispose();
    super.dispose();
  }

  CreatePostDraft _draft() {
    final type = _housingType.firstOrNull ?? '원룸';
    final deposit = _deposit.text.trim();
    final rent = _rent.text.trim();
    final maint = _maintenance.text.trim();
    final price = (deposit.isEmpty && rent.isEmpty)
        ? ''
        : '보증금 ${deposit.isEmpty ? '0' : deposit} / 월세 ${rent.isEmpty ? '0' : rent}';

    final badges = <FeedBadge>[
      FeedBadge.housing,
      if (type == '단기임대') FeedBadge.shortStay,
      if (type == '셰어하우스/룸메') FeedBadge.roommate,
    ];

    return CreatePostDraft(
      kind: CreatePostKind.realEstate,
      title: _title.text,
      description: _body.text,
      priceOrCondition: price,
      imageUrls: _images,
      badges: badges,
      detailMeta: {
        '주거 유형': type,
        '보증금/월세':
            '${deposit.isEmpty ? '-' : deposit} / ${rent.isEmpty ? '-' : rent}',
        if (maint.isNotEmpty) '관리비': maint,
        if (_options.isNotEmpty) '옵션': _options.join(' · '),
      },
      ctaLabel: '채팅으로 문의하기',
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTypography.bodyMedium,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CreatePostScaffold(
      title: '부동산 / 주거 등록',
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
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel('주거 유형'),
          SelectableChipRow(
            options: _housingOptions,
            selected: _housingType,
            onSelected: (next) => setState(() => _housingType = next),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel('계약 / 금액'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _deposit,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _fieldDecoration('보증금 (만)'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _rent,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _fieldDecoration('월세 (만)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _maintenance,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _fieldDecoration('관리비 (만, 선택)'),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel('옵션'),
          SelectableChipRow(
            options: _amenityOptions,
            selected: _options,
            multi: true,
            onSelected: (next) => setState(() => _options = next),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
