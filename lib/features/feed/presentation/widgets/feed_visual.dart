import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/feed_item.dart';

/// Icon + color per post kind, shared by thumbnails placeholders and map pins.
({IconData icon, Color color}) feedVisual(FeedItem item) {
  if (item.isFestival) {
    return (icon: Icons.celebration, color: const Color(0xFFE5487F));
  }
  final housing = item.housingType;
  if (housing != null) {
    return switch (housing) {
      HousingType.happyHouse => (
          icon: Icons.home_work,
          color: const Color(0xFF16A34A),
        ),
      HousingType.youthHouse => (
          icon: Icons.school,
          color: const Color(0xFF4F46E5),
        ),
      HousingType.publicRental => (
          icon: Icons.location_city,
          color: const Color(0xFF0D9488),
        ),
    };
  }
  return switch (item.category) {
    FeedCategory.housing => (
        icon: Icons.apartment,
        color: const Color(0xFF3B82F6),
      ),
    FeedCategory.job => (icon: Icons.work, color: const Color(0xFF10B981)),
    FeedCategory.community => (
        icon: Icons.campaign,
        color: const Color(0xFF8B5CF6),
      ),
    _ => (icon: Icons.shopping_bag, color: AppColors.primary),
  };
}
