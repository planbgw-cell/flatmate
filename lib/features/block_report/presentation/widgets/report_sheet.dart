import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/report_reason.dart';

typedef ReportSubmission = ({ReportReason reason, String details});

/// 신고 사유 + 상세 내용; `null` when dismissed.
Future<ReportSubmission?> showReportSheet(BuildContext context) {
  return showModalBottomSheet<ReportSubmission>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const ReportSheet(),
  );
}

class ReportSheet extends StatefulWidget {
  const ReportSheet({super.key});

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  final _details = TextEditingController();
  ReportReason? _reason;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reason = _reason;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('게시글 신고하기', style: AppTypography.header2),
              const SizedBox(height: AppSpacing.xs),
              Text('신고 사유를 선택해 주세요.', style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final option in ReportReason.values)
                    ChoiceChip(
                      key: ValueKey('report-reason-${option.code}'),
                      label: Text(option.label),
                      selected: option == reason,
                      showCheckmark: false,
                      selectedColor: AppColors.primary,
                      labelStyle: AppTypography.bodyMedium.copyWith(
                        color: option == reason
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                      onSelected: (_) => setState(() => _reason = option),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const ValueKey('report-details'),
                controller: _details,
                maxLength: 1000,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '상세 내용을 적어 주시면 검토에 도움이 돼요. (선택)',
                  hintStyle: AppTypography.bodyMedium,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('report-submit'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: reason == null
                      ? null
                      : () => Navigator.pop<ReportSubmission>(
                            context,
                            (reason: reason, details: _details.text.trim()),
                          ),
                  child: const Text('신고하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
