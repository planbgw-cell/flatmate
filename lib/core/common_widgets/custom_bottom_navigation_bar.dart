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

  static const _items = <({IconData icon, IconData activeIcon, String label})>[
    (
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: '홈',
    ),
    (
      icon: Icons.apartment_outlined,
      activeIcon: Icons.apartment,
      label: '주거',
    ),
    (
      icon: Icons.work_outline,
      activeIcon: Icons.work,
      label: '알바',
    ),
    (
      icon: Icons.forum_outlined,
      activeIcon: Icons.forum,
      label: '동네생활',
    ),
    (
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: '내정보',
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
        for (final item in _items)
          BottomNavigationBarItem(
            icon: Icon(item.icon),
            activeIcon: Icon(item.activeIcon),
            label: item.label,
          ),
      ],
    );
  }
}
