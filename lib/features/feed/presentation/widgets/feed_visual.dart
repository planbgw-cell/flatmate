import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/feed_item.dart';
import 'public_job_banner.dart';
import 'public_share_banner.dart';

/// Icon + brand color per post kind (sage primary for all categories).
({IconData icon, Color color}) feedVisual(FeedItem item) {
  const brand = AppColors.primary;
  if (item.isFestival) {
    return (icon: Icons.celebration, color: brand);
  }
  final housing = item.housingType;
  if (housing != null) {
    return switch (housing) {
      HousingType.happyHouse => (icon: Icons.home_work, color: brand),
      HousingType.youthHouse => (icon: Icons.school, color: brand),
      HousingType.publicRental => (icon: Icons.location_city, color: brand),
    };
  }
  if (item.isPublicJob) {
    final kind = JobBannerKind.fromTitle(item.title);
    return (icon: kind.icon, color: brand);
  }
  if (item.isPublicShare) {
    final kind = ShareBannerKind.fromItem(item);
    return (icon: kind.icon, color: brand);
  }
  return switch (item.category) {
    FeedCategory.housing => (icon: Icons.apartment, color: brand),
    FeedCategory.job => (icon: Icons.work, color: brand),
    FeedCategory.community => (icon: Icons.campaign, color: brand),
    _ => (icon: Icons.shopping_bag, color: brand),
  };
}
