import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../places/domain/models/local_place.dart';
import '../../domain/map_browse_mode.dart';

class MapCategoryIconBar extends StatelessWidget {
  const MapCategoryIconBar({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final MapBrowseMode mode;
  final ValueChanged<MapBrowseMode> onChanged;

  static final _items = <_BarItem>[
    const _BarItem.feeds(),
    _BarItem.place(PlaceCategory.food, Icons.restaurant),
    _BarItem.place(PlaceCategory.cafe, Icons.local_cafe),
    _BarItem.place(PlaceCategory.mart, Icons.storefront),
    _BarItem.place(PlaceCategory.medical, Icons.local_hospital),
    _BarItem.place(PlaceCategory.fitness, Icons.fitness_center),
    _BarItem.place(PlaceCategory.life, Icons.local_laundry_service),
    _BarItem.place(PlaceCategory.car, Icons.local_gas_station),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background.withValues(alpha: 0.92),
      elevation: 2,
      child: SizedBox(
        height: 92,
        child: ListView.separated(
          key: const ValueKey('map-category-icon-bar'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          itemCount: _items.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            final item = _items[index];
            final selected = item.matches(mode);
            return _IconChip(
              item: item,
              selected: selected,
              onTap: () => onChanged(item.mode),
            );
          },
        ),
      ),
    );
  }
}

class _BarItem {
  const _BarItem._({
    required this.mode,
    required this.label,
    required this.icon,
  });

  const _BarItem.feeds()
      : this._(
          mode: MapBrowseMode.feeds,
          label: '피드/공공',
          icon: Icons.map_outlined,
        );

  _BarItem.place(PlaceCategory category, IconData icon)
      : this._(
          mode: MapBrowsePlaces(category),
          label: category.label,
          icon: icon,
        );

  final MapBrowseMode mode;
  final String label;
  final IconData icon;

  bool matches(MapBrowseMode current) => mode == current;
}

class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _BarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('map-cat-${item.label}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : AppColors.surface,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Icon(
                item.icon,
                size: 22,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
