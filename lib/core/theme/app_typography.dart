import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const TextStyle header1 = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle header2 = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    height: 1.3,
  );

  static const TextStyle badgeText = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Material [TextTheme] bridge for ThemeData.
  static TextTheme get textTheme {
    return const TextTheme(
      headlineLarge: header1,
      headlineMedium: header2,
      titleLarge: header2,
      titleMedium: titleMedium,
      titleSmall: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.35,
      ),
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: caption,
      labelLarge: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        height: 1.2,
      ),
      labelMedium: badgeText,
      labelSmall: caption,
    );
  }
}
