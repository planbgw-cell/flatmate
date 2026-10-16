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

class JobCreateScreen extends ConsumerStatefulWidget {
  const JobCreateScreen({super.key});

  @override
  ConsumerState<JobCreateScreen> createState() => _JobCreateScreenState();
}

class _JobCreateScreenState extends ConsumerState<JobCreateScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _pay = TextEditingController();
  final _hours = TextEditingController(text: '09:00 ~ 18:00');

  List<String> _images = [];
  Set<String> _payType = {'시급'};
  Set<String> _workDays = {'주말'};
  final Set<String> _perks = {};

  static const _payTypes = ['시급', '일급', '월급'];
  static const _dayOptions = ['단기', '주말', '협의'];
  static const _perkOptions = ['초보가능', '즉시출근', '급구'];

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _pay.dispose();
    _hours.dispose();
    super.dispose();
  }

  CreatePostDraft _draft() {
    final payType = _payType.firstOrNull ?? '시급';
    final amount = _pay.text.trim();
    final price = amount.isEmpty ? '' : '$payType ${currency(amount)}원';
    final days = _workDays.firstOrNull ?? '협의';

    final badges = <FeedBadge>[
      FeedBadge.recruiting,
      if (_perks.contains('급구')) FeedBadge.urgent,
    ];

    return CreatePostDraft(
      kind: CreatePostKind.job,
      title: _title.text,
      description: _body.text,
      priceOrCondition: price,
      imageUrls: _images,
      badges: badges,
      detailMeta: {
        '급여': price.isEmpty ? '-' : price,
        '근무 요일': days,
        '근무 시간': _hours.text.trim().isEmpty ? '-' : _hours.text.trim(),
        if (_perks.isNotEmpty) '우대/특이사항': _perks.join(' · '),
      },
      ctaLabel: '지원하기',
    );
  }

  String currency(String digits) {
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
      title: '알바 공고 등록',
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
          const SectionLabel('급여 유형'),
          SelectableChipRow(
            options: _payTypes,
            selected: _payType,
            onSelected: (next) => setState(() => _payType = next),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _pay,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTypography.bodyLarge,
            decoration: InputDecoration(
              hintText: '금액 입력',
              hintStyle: AppTypography.bodyMedium,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel('근무 요일'),
          SelectableChipRow(
            options: _dayOptions,
            selected: _workDays,
            onSelected: (next) => setState(() => _workDays = next),
          ),
          const SizedBox(height: AppSpacing.sm),
          const SectionLabel('근무 시간'),
          TextField(
            controller: _hours,
            style: AppTypography.bodyLarge,
            decoration: InputDecoration(
              hintText: '예: 07:00 ~ 13:00',
              hintStyle: AppTypography.bodyMedium,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel('우대 / 특이사항'),
          ..._perkOptions.map(
            (perk) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(perk, style: AppTypography.bodyLarge),
              value: _perks.contains(perk),
              activeColor: AppColors.primary,
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _perks.add(perk);
                  } else {
                    _perks.remove(perk);
                  }
                });
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
