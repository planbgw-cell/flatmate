import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class PostFormFields extends StatelessWidget {
  const PostFormFields({
    super.key,
    required this.titleController,
    required this.bodyController,
    this.priceController,
    this.priceLabel = '가격',
    this.priceHint = '가격을 입력하세요',
    this.showPrice = true,
  });

  final TextEditingController titleController;
  final TextEditingController bodyController;
  final TextEditingController? priceController;
  final String priceLabel;
  final String priceHint;
  final bool showPrice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('제목', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          key: const ValueKey('post-title'),
          controller: titleController,
          style: AppTypography.bodyLarge,
          decoration: _decoration(hint: '제목을 입력하세요 (2자 이상)'),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('내용', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          key: const ValueKey('post-body'),
          controller: bodyController,
          style: AppTypography.bodyLarge.copyWith(height: 1.5),
          minLines: 5,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          decoration: _decoration(hint: '내용을 입력하세요'),
        ),
        if (showPrice && priceController != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(priceLabel, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: priceController,
            style: AppTypography.bodyLarge,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _decoration(hint: priceHint),
          ),
        ],
      ],
    );
  }

  InputDecoration _decoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMedium,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.all(AppSpacing.sm),
    );
  }
}

class SelectableChipRow extends StatelessWidget {
  const SelectableChipRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.multi = false,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onSelected;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final option in options)
          FilterChip(
            label: Text(option),
            selected: selected.contains(option),
            onSelected: (value) {
              final next = {...selected};
              if (multi) {
                value ? next.add(option) : next.remove(option);
              } else {
                next
                  ..clear()
                  ..add(option);
              }
              onSelected(next);
            },
            selectedColor: AppColors.primaryContainer,
            checkmarkColor: AppColors.primary,
            labelStyle: AppTypography.badgeText.copyWith(
              color: selected.contains(option)
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            side: BorderSide(
              color: selected.contains(option)
                  ? AppColors.primary
                  : AppColors.border,
            ),
            backgroundColor: AppColors.background,
          ),
      ],
    );
  }
}

/// Digits-only amount input with a unit suffix (e.g. "만원", "원").
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.controller,
    required this.label,
    required this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppTypography.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodyMedium,
        suffixText: suffix,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(text, style: AppTypography.titleMedium),
    );
  }
}
