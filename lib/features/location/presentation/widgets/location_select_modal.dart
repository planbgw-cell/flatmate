import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/location_item.dart';
import '../providers/location_provider.dart';
import 'location_radius_slider.dart';

Future<void> showLocationSelectModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const LocationSelectModal(),
  );
}

class LocationSelectModal extends ConsumerStatefulWidget {
  const LocationSelectModal({super.key});

  @override
  ConsumerState<LocationSelectModal> createState() =>
      _LocationSelectModalState();
}

class _LocationSelectModalState extends ConsumerState<LocationSelectModal> {
  final _searchController = TextEditingController();
  bool _gpsLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _findByGps() async {
    setState(() => _gpsLoading = true);
    try {
      final nearest = await resolveLocationFromGps();
      if (!mounted) return;
      ref.read(myLocationsProvider.notifier).select(nearest);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${nearest.dongName}으로 설정했어요.')),
      );
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currentLocationProvider);
    final myLocations = ref.watch(myLocationsProvider);
    final results = ref.watch(locationSearchResultsProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.88;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('내 동네 설정', style: AppTypography.header2),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                ref.read(locationSearchQueryProvider.notifier).state = value;
              },
              decoration: InputDecoration(
                hintText: '동네 이름 검색 (예: 정자동, 판교동)',
                hintStyle: AppTypography.bodyMedium,
                prefixIcon: const Icon(Icons.search, size: 22),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '내 동네 · 최대 ${MyLocationsNotifier.maxSlots}개',
                style: AppTypography.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                for (var i = 0; i < MyLocationsNotifier.maxSlots; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _MyTownChip(
                      location: i < myLocations.length ? myLocations[i] : null,
                      selected: i < myLocations.length &&
                          myLocations[i].id == current.id,
                      onTap: i < myLocations.length
                          ? () => ref
                              .read(myLocationsProvider.notifier)
                              .setActive(myLocations[i])
                          : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _gpsLoading ? null : _findByGps,
                icon: _gpsLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 20),
                label: Text(
                  _gpsLoading ? '위치 확인 중…' : '내 위치로 동네 찾기',
                  style: AppTypography.titleMedium,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.lg + bottom,
              ),
              children: [
                if (_searchController.text.trim().isNotEmpty) ...[
                  Text('검색 결과', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  if (results.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      child: Text(
                        '검색 결과가 없습니다.',
                        style: AppTypography.bodyMedium,
                      ),
                    )
                  else
                    ...results.map(
                      (loc) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(loc.dongName, style: AppTypography.titleMedium),
                        subtitle: Text(
                          loc.fullName,
                          style: AppTypography.bodyMedium,
                        ),
                        trailing: loc.id == current.id
                            ? const Icon(
                                Icons.check,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () {
                          ref.read(myLocationsProvider.notifier).select(loc);
                          ref.read(locationSearchQueryProvider.notifier).state =
                              '';
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                const LocationRadiusSlider(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyTownChip extends StatelessWidget {
  const _MyTownChip({
    required this.location,
    required this.selected,
    this.onTap,
  });

  final LocationItem? location;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final empty = location == null;
    return Material(
      color: selected
          ? AppColors.primary
          : empty
              ? AppColors.surface
              : AppColors.primaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : empty
                      ? AppColors.border
                      : AppColors.primaryContainer,
            ),
          ),
          child: Text(
            empty
                ? '+'
                : selected
                    ? '${location!.dongName} ✓'
                    : location!.dongName,
            style: AppTypography.titleMedium.copyWith(
              color: selected
                  ? Colors.white
                  : empty
                      ? AppColors.textHint
                      : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
