import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../providers/search_provider.dart';
import '../widgets/recent_searches_widget.dart';
import '../widgets/search_result_widget.dart';

/// 당근-style search: 최근 검색 until a keyword is submitted, then results.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const _maxLength = 50;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit([String? term]) {
    final value = (term ?? _controller.text).trim();
    if (value.isEmpty) return;
    if (_controller.text != value) {
      _controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    _focusNode.unfocus();
    ref.read(recentSearchesProvider.notifier).add(value);
    ref.read(searchQueryProvider.notifier).state = value;
  }

  void _onChanged(String text) {
    setState(() {});
    if (text.trim().isEmpty) {
      ref.read(searchQueryProvider.notifier).state = '';
    }
  }

  void _clear() {
    _controller.clear();
    _onChanged('');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final dong = ref.watch(currentLocationProvider).dongName;
    final showResults = query.isNotEmpty && _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        leading: const BackButton(),
        title: TextField(
          key: const ValueKey('search-field'),
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          maxLength: _maxLength,
          textInputAction: TextInputAction.search,
          style: AppTypography.bodyLarge,
          onChanged: _onChanged,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: '$dong 근처에서 검색',
            hintStyle: AppTypography.bodyMedium,
            counterText: '',
            filled: true,
            fillColor: AppColors.surface,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    key: const ValueKey('search-clear-text'),
                    tooltip: '지우기',
                    icon: const Icon(Icons.cancel, size: 18),
                    color: AppColors.textHint,
                    onPressed: _clear,
                  ),
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('search-submit'),
            onPressed: _submit,
            child: Text(
              '검색',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: showResults
          ? const SearchResultWidget()
          : RecentSearchesWidget(onSelected: _submit),
    );
  }
}
