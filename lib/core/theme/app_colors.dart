import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand — deep sage + warm off-white
  static const Color primary = Color(0xFF2E6F5E);
  static const Color primaryLight = Color(0xFFE8F1EE);
  static const Color primaryDark = Color(0xFF245A4C);

  static const Color accent = Color(0xFFE07A5F);
  static const Color accentLight = Color(0xFFFBECE8);

  static const Color secondary = Color(0xFF2B2F3A);
  static const Color accentBlue = Color(0xFF2F80ED);

  static const Color background = Color(0xFFF9F8F6);
  static const Color surface = Color(0xFFF9F8F6);
  static const Color cardBackground = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1E2624);
  static const Color textSecondary = Color(0xFF64706C);
  static const Color textHint = Color(0xFF8C9693);
  static const Color textDisabled = Color(0xFFC5CBC9);

  static const Color border = Color(0xFFE6EAE8);
  static const Color divider = Color(0xFFE6EAE8);

  /// Bottom tab unselected icon/label.
  static const Color navInactive = Color(0xFF8C9693);

  /// Map category icon when unselected.
  static const Color iconMuted = Color(0xFF4A5552);

  // Status & badges
  static const Color statusUrgent = accent;
  static const Color statusSuccess = Color(0xFF27AE60);
  static const Color statusWarning = Color(0xFFF2994A);

  // Compatibility aliases
  static const Color primaryContainer = primaryLight;
  static const Color textTertiary = textHint;
  static const Color outline = border;
  static const Color error = Color(0xFFEB5757);
  static const Color skeletonBase = border;
  static const Color skeletonHighlight = surface;
  static const Color trustHigh = statusSuccess;
  static const Color trustMid = statusWarning;
  static const Color trustLow = accent;
  static const Color chipBump = primaryLight;
  static const Color chipUrgent = accentLight;
  static const Color chipStatus = Color(0xFFE3F2FD);
}
