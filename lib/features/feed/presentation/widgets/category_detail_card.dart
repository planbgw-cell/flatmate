import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/feed_extra_meta.dart';
import '../../domain/models/feed_item.dart';

/// Category-specific facts for the detail screen (부동산 / 알바 / 일반).
/// Legacy posts without typed `extra_meta` fall back to their key-value list.
class CategoryDetailCard extends StatelessWidget {
  const CategoryDetailCard({super.key, required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    final meta = FeedExtraMeta(item.category, item.extraMeta);
    if (!meta.isStructured) {
      if (item.detailMeta.isEmpty) return const SizedBox.shrink();
      return _CardShell(
        child: _Rows(
          rows: [
            for (final e in item.detailMeta.entries) FeedDetailRow(e.key, e.value),
          ],
        ),
      );
    }

    final (title, chips) = switch (item.category) {
      FeedCategory.housing => (
          '주거 정보',
          [meta.roomType?.label ?? '', if (meta.isShortTerm) '단기임대 가능'],
        ),
      FeedCategory.job => ('근무 조건', meta.workDays),
      _ => ('거래 정보', [if (meta.isFree) '나눔']),
    };

    return _CardShell(
      key: ValueKey('detail-card-${item.category.name}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            meta.priceLabel,
            style: AppTypography.header2.copyWith(color: AppColors.primary),
          ),
          if (chips.any((c) => c.isNotEmpty)) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final chip in chips.where((c) => c.isNotEmpty))
                  _Chip(label: chip),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          _Rows(rows: meta.rows),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows({required this.rows});

  final List<FeedDetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: Text(rows[i].label, style: AppTypography.bodyMedium),
              ),
              Expanded(
                child: Text(rows[i].value, style: AppTypography.bodyLarge),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTypography.badgeText.copyWith(color: AppColors.primary),
      ),
    );
  }
}
