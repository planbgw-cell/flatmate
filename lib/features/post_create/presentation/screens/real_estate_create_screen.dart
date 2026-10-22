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

/// 부동산 (`REAL_ESTATE`): room_type · deposit · monthly_rent (만원) ·
/// maintenance_fee · is_short_term.
class RealEstateCreateScreen extends ConsumerStatefulWidget {
  const RealEstateCreateScreen({super.key, this.targetFeed});

  /// Edit mode (`PATCH /feeds/{id}`) when set; fields are prefilled from it.
  final FeedItem? targetFeed;

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

  List<PostImage> _images = [];
  RoomType _roomType = RoomType.oneRoom;
  bool _shortTerm = false;

  @override
  void initState() {
    super.initState();
    final target = widget.targetFeed;
    if (target == null) return;
    final meta = FeedExtraMeta(FeedCategory.housing, target.extraMeta);
    _title.text = target.title;
    _body.text = target.description;
    _images = remotePostImages(target);
    _roomType = meta.roomType ?? RoomType.oneRoom;
    _shortTerm = meta.isShortTerm;
    _deposit.text = meta.deposit?.toString() ?? '';
    _rent.text = meta.monthlyRent?.toString() ?? '';
    _maintenance.text = meta.maintenanceFee?.toString() ?? '';
  }

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
    return CreatePostDraft(
      kind: CreatePostKind.realEstate,
      title: _title.text,
      description: _body.text,
      images: _images,
      extraMeta: {
        ExtraMetaKeys.roomType: _roomType.code,
        ExtraMetaKeys.deposit: ?int.tryParse(_deposit.text),
        ExtraMetaKeys.monthlyRent: ?int.tryParse(_rent.text),
        ExtraMetaKeys.maintenanceFee: ?int.tryParse(_maintenance.text),
        ExtraMetaKeys.isShortTerm: _shortTerm,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CreatePostScaffold(
      title: widget.targetFeed == null ? '부동산 / 주거 등록' : '글 수정하기',
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
          const SectionLabel('방 종류'),
          SelectableChipRow(
            options: [for (final t in RoomType.values) t.label],
            selected: {_roomType.label},
            onSelected: (next) => setState(() {
              _roomType = RoomType.values.firstWhere(
                (t) => t.label == next.first,
              );
            }),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel('보증금 / 월세'),
          Row(
            children: [
              Expanded(
                child: NumberField(
                  key: const ValueKey('field-deposit'),
                  controller: _deposit,
                  label: '보증금',
                  suffix: '만원',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: NumberField(
                  key: const ValueKey('field-monthly-rent'),
                  controller: _rent,
                  label: '월세',
                  suffix: '만원',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          NumberField(
            key: const ValueKey('field-maintenance-fee'),
            controller: _maintenance,
            label: '관리비 (선택)',
            suffix: '만원',
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            key: const ValueKey('field-short-term'),
            contentPadding: EdgeInsets.zero,
            title: Text('단기임대 가능', style: AppTypography.bodyLarge),
            subtitle: Text('1~3개월 단기 계약 가능', style: AppTypography.caption),
            value: _shortTerm,
            activeThumbColor: AppColors.primary,
            onChanged: (v) => setState(() => _shortTerm = v),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
