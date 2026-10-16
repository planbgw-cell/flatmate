import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // EdgeInsets Quick Helpers
  static const EdgeInsets paddingAllSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingAllMd = EdgeInsets.all(md);
  static const EdgeInsets paddingSymmetricH =
      EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingSymmetricV =
      EdgeInsets.symmetric(vertical: sm);

  // Component metrics
  static const double cardRadius = 12.0;
  static const double thumbRadius = 10.0;
  static const double chipRadius = 4.0;
  static const double thumbSize = 90.0;
}
