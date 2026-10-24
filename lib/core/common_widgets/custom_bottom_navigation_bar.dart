import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Flatmate 5-tab bottom navigation (fixed type, state-preserving shell).
class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const items = <({
    String key,
    IconData icon,
    IconData activeIcon,
    String label,
  })>[
    (
      key: 'tab-home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: '홈',
    ),
    (
      key: 'tab-community',
      icon: Icons.campaign_outlined,
      activeIcon: Icons.campaign,
      label: '동네소식',
    ),
    (
      key: 'tab-around',
      icon: Icons.map_outlined,
      activeIcon: Icons.map,
      label: '내주변',
    ),
    (
      key: 'tab-chat',
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: '채팅',
    ),
    (
      key: 'tab-my',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: '마이플랫',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.cardBackground,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      elevation: 8,
      items: [
        for (final item in items)
          BottomNavigationBarItem(
            icon: Icon(item.icon, key: ValueKey(item.key)),
            activeIcon: Icon(item.activeIcon, key: ValueKey(item.key)),
            label: item.label,
          ),
      ],
    );
  }
}
