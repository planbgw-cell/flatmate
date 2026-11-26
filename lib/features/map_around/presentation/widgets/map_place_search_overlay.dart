import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../places/domain/models/local_place.dart';
import '../../../places/presentation/providers/places_provider.dart';
import '../providers/map_around_provider.dart';

/// Result of a place keyword search overlay.
class MapPlaceSearchResult {
  const MapPlaceSearchResult({
    required this.query,
    required this.places,
    required this.selected,
  });

  final String query;
  final List<LocalPlace> places;
  final LocalPlace selected;
}

/// Full-screen place search with debounce, suggestion chips, and result list.
class MapPlaceSearchOverlay extends ConsumerStatefulWidget {
  const MapPlaceSearchOverlay({
    super.key,
    required this.lat,
    required this.lng,
  });

  final double lat;
  final double lng;

  static Future<MapPlaceSearchResult?> open(
    BuildContext context, {
    required double lat,
    required double lng,
  }) {
    return Navigator.of(context).push<MapPlaceSearchResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MapPlaceSearchOverlay(lat: lat, lng: lng),
      ),
    );
  }

  @override
  ConsumerState<MapPlaceSearchOverlay> createState() =>
      _MapPlaceSearchOverlayState();
}

class _MapPlaceSearchOverlayState extends ConsumerState<MapPlaceSearchOverlay> {
  static const _debounceMs = 300;
  static const _suggestions = [
    '정형외과',
    '치과',
    '24시 약국',
    '코인세탁소',
    '다이소',
    '공영주차장',
  ];

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  String _activeQuery = '';
  List<LocalPlace> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    setState(() {});
    _debounce?.cancel();
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _activeQuery = '';
        _results = const [];
        _loading = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      _search(trimmed);
    });
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _activeQuery = q;
    });
    try {
      final result = await ref.read(placesRepositoryProvider).nearby(
            lat: widget.lat,
            lng: widget.lng,
            q: q,
            radius: MapAroundNotifier.searchRadiusM,
            limit: 20,
          );
      if (!mounted || _controller.text.trim() != q) return;
      setState(() {
        _results = result.items;
        _loading = false;
        _error = result.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _results = const [];
        _error = e is ApiException ? e.message : '검색에 실패했어요.';
      });
    }
  }

  void _submit([String? term]) {
    _debounce?.cancel();
    final value = (term ?? _controller.text).trim();
    if (value.isEmpty) return;
    if (_controller.text != value) {
      _controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    _search(value);
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _activeQuery = '';
      _results = const [];
      _loading = false;
      _error = null;
    });
    _focusNode.requestFocus();
  }

  void _select(LocalPlace place) {
    Navigator.of(context).pop(
      MapPlaceSearchResult(
        query: _activeQuery.isEmpty ? place.name : _activeQuery,
        places: _results.isEmpty ? [place] : _results,
        selected: place,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showSuggestions =
        _controller.text.trim().isEmpty && !_loading && _results.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        leading: const BackButton(),
        title: TextField(
          key: const ValueKey('map-place-search-field'),
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: AppTypography.bodyLarge,
          onChanged: _onChanged,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: '상호명, 업종, 편의시설 검색 (예: 스타벅스, 정형외과)',
            hintStyle: AppTypography.bodyMedium.copyWith(fontSize: 13),
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
                    key: const ValueKey('map-place-search-clear'),
                    tooltip: '지우기',
                    icon: const Icon(Icons.cancel, size: 18),
                    color: AppColors.textHint,
                    onPressed: _clear,
                  ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: showSuggestions
                ? _SuggestionChips(
                    suggestions: _suggestions,
                    onTap: (chip) {
                      _controller.value = TextEditingValue(
                        text: chip,
                        selection:
                            TextSelection.collapsed(offset: chip.length),
                      );
                      _submit(chip);
                    },
                  )
                : _ResultBody(
                    loading: _loading,
                    error: _error,
                    results: _results,
                    query: _activeQuery,
                    onSelect: _select,
                  ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({
    required this.suggestions,
    required this.onTap,
  });

  final List<String> suggestions;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          '추천 검색어',
          style: AppTypography.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final chip in suggestions)
              ActionChip(
                key: ValueKey('map-place-suggest-$chip'),
                label: Text(chip),
                onPressed: () => onTap(chip),
              ),
          ],
        ),
      ],
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({
    required this.loading,
    required this.error,
    required this.results,
    required this.query,
    required this.onSelect,
  });

  final bool loading;
  final String? error;
  final List<LocalPlace> results;
  final String query;
  final ValueChanged<LocalPlace> onSelect;

  @override
  Widget build(BuildContext context) {
    if (!loading && results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            error ??
                (query.isEmpty
                    ? '검색어를 입력해 보세요.'
                    : '‘$query’ 검색 결과가 없어요.'),
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
        ),
      );
    }
    return ListView.separated(
      key: const ValueKey('map-place-search-results'),
      itemCount: results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final place = results[index];
        return ListTile(
          key: ValueKey('map-place-search-row-${place.placeId}'),
          title: Text(place.name, style: AppTypography.titleMedium),
          subtitle: Text(
            [
              if (place.subCategory.isNotEmpty) place.subCategory,
              place.distanceLabel,
              if (place.address.isNotEmpty) place.address,
            ].join(' · '),
            style: AppTypography.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => onSelect(place),
        );
      },
    );
  }
}
