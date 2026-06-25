import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static bool isDarkMode = true;

  static const primary = Color(0xFF02529C);
  static const primaryDark = Color(0xFF082F57);
  static const accent = Color(0xFF00B4D8);
  static const error = Color(0xFFDC2626);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);

  static Color get surface => isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  static Color get surfaceAlt => isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
  static Color get card => isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
  static Color get input => isDarkMode ? const Color(0xFF0B1220) : const Color(0xFFF1F5F9);
  static Color get border => isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  static Color get textPrimary => isDarkMode ? const Color(0xFFF0F5FA) : const Color(0xFF0F172A);
  static Color get textSecondary => isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
}
