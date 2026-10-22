import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/create_post_provider.dart';

typedef CreatePostDraftBuilder = CreatePostDraft Function();

class CreatePostScaffold extends ConsumerWidget {
  const CreatePostScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.buildDraft,
  });

  final String title;
  final Widget body;
  final CreatePostDraftBuilder buildDraft;

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(createPostProvider.notifier).submit(buildDraft());
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 등록되었습니다.')),
      );
      context.pop();
    } on CreatePostException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException ? '등록에 실패했습니다. ${e.message}' : '등록에 실패했습니다.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(createPostProvider);
    final submitting = phase != CreatePostPhase.idle;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: AppTypography.header2),
        bottom: submitting
            ? PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Column(
                  children: [
                    Text(phase.label, style: AppTypography.caption),
                    const SizedBox(height: 4),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                ),
              )
            : null,
        actions: [
          TextButton(
            onPressed: submitting ? null : () => _submit(context, ref),
            child: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    '완료',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: submitting,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: body,
        ),
      ),
    );
  }
}
