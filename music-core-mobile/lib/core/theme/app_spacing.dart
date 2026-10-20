import 'package:flutter/material.dart';

/// Predictable, standardized spacing scale defined according to `docs/ux-ui.md`.
abstract final class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // Edge insets helpers
  static const paddingScreen = EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0);
  static const paddingScreenHorizontal = EdgeInsets.symmetric(horizontal: 20.0);
  static const paddingCard = EdgeInsets.all(16.0);
  static const paddingList = EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
}

/// Standardized border radius tokens
abstract final class AppRadius {
  static const double sm = 6.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;

  static const borderRadiusSm = BorderRadius.all(Radius.circular(sm));
  static const borderRadiusMd = BorderRadius.all(Radius.circular(md));
  static const borderRadiusLg = BorderRadius.all(Radius.circular(lg));
  static const borderRadiusXl = BorderRadius.all(Radius.circular(xl));
  static const borderRadiusFull = BorderRadius.all(Radius.circular(full));
}
