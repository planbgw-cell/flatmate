import 'package:flutter/material.dart';

import 'custom_app_bar.dart';

/// Backward-compatible alias for [CustomAppBar].
class FlatmateAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FlatmateAppBar({
    super.key,
    required this.neighborhood,
    this.onNeighborhoodTap,
    this.onSearchTap,
    this.onNotificationTap,
    this.onMenuTap,
    this.visible = true,
    this.notificationBadge = false,
  });

  final String neighborhood;
  final VoidCallback? onNeighborhoodTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMenuTap;
  final bool visible;
  final bool notificationBadge;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      locationName: neighborhood,
      onLocationTap: onNeighborhoodTap,
      onSearchTap: onSearchTap,
      onNotificationTap: onNotificationTap,
      onMenuTap: onMenuTap,
      visible: visible,
      notificationBadge: notificationBadge,
    );
  }
}
