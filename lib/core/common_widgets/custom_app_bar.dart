import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.locationName,
    this.onLocationTap,
    this.onSearchTap,
    this.onNotificationTap,
    this.onMenuTap,
    this.visible = true,
    this.notificationBadge = false,
  });

  final String locationName;
  final VoidCallback? onLocationTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMenuTap;
  final bool visible;
  final bool notificationBadge;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(0, -1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: visible ? 1 : 0,
        child: AppBar(
          titleSpacing: 16.0,
          title: InkWell(
            key: const ValueKey('feed-location-button'),
            onTap: onLocationTap,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(locationName, style: AppTypography.header2),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              key: const ValueKey('feed-search-button'),
              icon: const Icon(
                Icons.search,
                color: AppColors.textPrimary,
                size: 26,
              ),
              onPressed: onSearchTap,
            ),
            IconButton(
              icon: Badge(
                isLabelVisible: notificationBadge,
                smallSize: 8,
                child: const Icon(
                  Icons.notifications_none,
                  color: AppColors.textPrimary,
                  size: 26,
                ),
              ),
              onPressed: onNotificationTap,
            ),
            if (onMenuTap != null)
              IconButton(
                icon: const Icon(
                  Icons.menu,
                  color: AppColors.textPrimary,
                  size: 26,
                ),
                onPressed: onMenuTap,
              ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
