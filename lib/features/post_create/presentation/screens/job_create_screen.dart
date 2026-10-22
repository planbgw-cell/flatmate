import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../feed/domain/models/feed_extra_meta.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../../domain/post_image.dart';
import '../providers/create_post_provider.dart';
import '../widgets/create_post_scaffold.dart';
import '../widgets/image_picker_grid.dart';
import '../widgets/post_form_fields.dart';

/// 알바 (`JOB`): pay_type · pay_amount (원) · work_period · work_days ·
/// work_hours.
class JobCreateScreen extends ConsumerStatefulWidget {
  const JobCreateScreen({super.key, this.targetFeed});

  /// Edit mode (`PATCH /feeds/{id}`) when set; fields are prefilled from it.
  final FeedItem? targetFeed;

  @override
  ConsumerState<JobCreateScreen> createState() => _JobCreateScreenState();
}

class _JobCreateScreenState extends ConsumerState<JobCreateScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _pay = TextEditingController();
  final _hours = TextEditingController(text: '09:00~18:00');

  List<PostImage> _images = [];
  PayType _payType = PayType.hourly;
  String? _period;
  Set<String> _days = {};

  @override
  void initState() {
    super.initState();
    final target = widget.targetFeed;
    if (target == null) return;
    final meta = FeedExtraMeta(FeedCategory.job, target.extraMeta);
    _title.text = target.title;
    _body.text = target.description;
    _images = remotePostImages(target);
    _payType = meta.payType ?? PayType.hourly;
    _pay.text = meta.payAmount?.toString() ?? '';
    final period = meta.workPeriod;
    _period = kWorkPeriodOptions.contains(period) ? period : null;
    _days = meta.workDays.where(kWorkDayOptions.contains).toSet();
    _hours.text = meta.workHours ?? '';
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _pay.dispose();
    _hours.dispose();
    super.dispose();
  }

  CreatePostDraft _draft() {
    final days = kWorkDayOptions.where(_days.contains).join(',');
    final hours = _hours.text.trim();
    return CreatePostDraft(
      kind: CreatePostKind.job,
      title: _title.text,
      description: _body.text,
      images: _images,
      extraMeta: {
        ExtraMetaKeys.payType: _payType.code,
        ExtraMetaKeys.payAmount: ?int.tryParse(_pay.text),
        ExtraMetaKeys.workPeriod: ?_period,
        if (days.isNotEmpty) ExtraMetaKeys.workDays: days,
        if (hours.isNotEmpty) ExtraMetaKeys.workHours: hours,
      },
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return CreatePostScaffold(
      title: widget.targetFeed == null ? '알바 공고 등록' : '글 수정하기',
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
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel('급여 조건'),
          SelectableChipRow(
            options: [for (final t in PayType.values) t.label],
            selected: {_payType.label},
            onSelected: (next) => setState(() {
              _payType = PayType.values.firstWhere((t) => t.label == next.first);
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          NumberField(
            key: const ValueKey('field-pay-amount'),
            controller: _pay,
            label: '${_payType.label} 금액',
            suffix: '원',
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel('근무 기간'),
          SelectableChipRow(
            options: kWorkPeriodOptions,
            selected: {?_period},
            onSelected: (next) => setState(() => _period = next.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel('근무 요일'),
          SelectableChipRow(
            options: kWorkDayOptions,
            selected: _days,
            multi: true,
            onSelected: (next) => setState(() => _days = next),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel('근무 시간'),
          TextField(
            key: const ValueKey('field-work-hours'),
            controller: _hours,
            style: AppTypography.bodyLarge,
            decoration: _decoration('예: 07:00~13:00'),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
