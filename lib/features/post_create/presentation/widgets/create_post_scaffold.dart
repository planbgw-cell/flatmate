import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../providers/create_post_provider.dart';

typedef CreatePostDraftBuilder = CreatePostDraft Function();

class CreatePostScaffold extends ConsumerWidget {
  const CreatePostScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.buildDraft,
    this.editing,
  });

  final String title;
  final Widget body;
  final CreatePostDraftBuilder buildDraft;

  /// Edit mode: the post being edited; the screen pops with the updated item.
  final FeedItem? editing;

  bool get isEdit => editing != null;

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final verb = isEdit ? '수정' : '등록';
    try {
      final saved = await ref
          .read(createPostProvider.notifier)
          .submit(buildDraft(), editing: editing);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? '게시글을 수정했어요.' : '게시글이 등록되었습니다.'),
        ),
      );
      context.pop(isEdit ? saved : null);
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
            e is ApiException
                ? '$verb에 실패했습니다. ${e.message}'
                : '$verb에 실패했습니다.',
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
                    isEdit ? '수정 완료' : '완료',
                    key: const ValueKey('post-submit'),
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
