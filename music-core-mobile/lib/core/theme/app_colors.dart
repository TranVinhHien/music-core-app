import 'package:flutter/material.dart';

/// Centralized color palette defined according to `docs/ux-ui.md`.
abstract final class AppColors {
  // Brand / Accent
  static const primary = Color(0xFF6366F1); // Indigo Accent
  static const primaryContainer = Color(0xFF4F46E5);
  static const accent = Color(0xFF10B981); // Emerald Green for playback / active

  // Semantic
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  // Dark Theme Colors (Primary for Music App)
  static const darkBackground = Color(0xFF121214);
  static const darkSurface = Color(0xFF18181B);
  static const darkSurfaceElevated = Color(0xFF27272A);
  static const darkTextPrimary = Color(0xFFF4F4F5);
  static const darkTextSecondary = Color(0xFFA1A1AA);
  static const darkTextMuted = Color(0xFF71717A);
  static const darkDivider = Color(0xFF27272A);
  static const darkBorder = Color(0xFF3F3F46);

  // Light Theme Colors
  static const lightBackground = Color(0xFFF8F9FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceElevated = Color(0xFFF1F3F5);
  static const lightTextPrimary = Color(0xFF09090B);
  static const lightTextSecondary = Color(0xFF52525B);
  static const lightTextMuted = Color(0xFF71717A);
  static const lightDivider = Color(0xFFE4E4E7);
  static const lightBorder = Color(0xFFD4D4D8);
}
