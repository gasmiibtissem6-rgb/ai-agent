import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static bool isDarkMode = true;

  static const primaryDark = Color(0xFF082F57);
  static const accent = Color(0xFF00B4D8);

  // Brand and semantic colors resolve to lighter tones in dark mode so
  // selected/active items stay readable against the dark slate surfaces.
  static Color get primary =>
      isDarkMode ? const Color(0xFF3B82F6) : const Color(0xFF02529C);
  static Color get error =>
      isDarkMode ? const Color(0xFFEF4444) : const Color(0xFFDC2626);
  static Color get success =>
      isDarkMode ? const Color(0xFF22C55E) : const Color(0xFF16A34A);
  static Color get warning =>
      isDarkMode ? const Color(0xFFF59E0B) : const Color(0xFFD97706);

  static Color get surface =>
      isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  static Color get surfaceAlt =>
      isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
  static Color get card =>
      isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
  static Color get input =>
      isDarkMode ? const Color(0xFF0B1220) : const Color(0xFFF1F5F9);
  static Color get border =>
      isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  static Color get textPrimary =>
      isDarkMode ? const Color(0xFFF0F5FA) : const Color(0xFF0F172A);
  static Color get textSecondary =>
      isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
}
