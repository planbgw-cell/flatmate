import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors (Flatmate Main: 따뜻하고 활기찬 주황 계열)
  static const Color primary = Color(0xFFFF6F00);
  static const Color primaryLight = Color(0xFFFF9E40);
  static const Color primaryDark = Color(0xFFC63F00);

  // Secondary & Accents
  static const Color secondary = Color(0xFF2B2F3A);
  static const Color accentBlue = Color(0xFF2F80ED);

  // Neutral Colors (Background, Surface, Text, Border)
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F8FA);
  static const Color cardBackground = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textDisabled = Color(0xFFE0E0E0);

  static const Color border = Color(0xFFEEEEEE);
  static const Color divider = Color(0xFFF0F0F0);

  // Status & Badges
  static const Color statusUrgent = Color(0xFFEB5757); // 급구 / 긴급
  static const Color statusSuccess = Color(0xFF27AE60); // 완료 / 예약가능
  static const Color statusWarning = Color(0xFFF2994A); // 계약대기 / 진행중

  // Compatibility aliases used by existing screens
  static const Color primaryContainer = Color(0xFFFFE0B2);
  static const Color textTertiary = textHint;
  static const Color outline = border;
  static const Color error = statusUrgent;
  static const Color skeletonBase = border;
  static const Color skeletonHighlight = surface;
  static const Color trustHigh = statusSuccess;
  static const Color trustMid = statusWarning;
  static const Color trustLow = statusUrgent;
  static const Color chipBump = Color(0xFFE8F5E9);
  static const Color chipUrgent = Color(0xFFFFEBEE);
  static const Color chipStatus = Color(0xFFE3F2FD);
}
