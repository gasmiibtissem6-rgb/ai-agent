import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_colors.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  static const _storage = FlutterSecureStorage();
  static const _themeKey = 'theme_mode';

  @override
  ThemeMode build() {
    return AppColors.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme(bool isDark) async {
    AppColors.isDarkMode = isDark;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    try {
      await _storage.write(key: _themeKey, value: isDark ? 'dark' : 'light');
    } catch (_) {}
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);
