import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocaleNotifier extends Notifier<Locale> {
  static const _storage = FlutterSecureStorage();
  static const _localeKey = 'app_locale';

  @override
  Locale build() {
    _loadSaved();
    return const Locale('fr');
  }

  Future<void> _loadSaved() async {
    try {
      final saved = await _storage.read(key: _localeKey);
      if (saved == 'en') {
        state = const Locale('en');
      } else if (saved == 'fr') {
        state = const Locale('fr');
      }
    } catch (_) {}
  }

  Future<void> setLocale(String languageCode) async {
    state = Locale(languageCode);
    try {
      await _storage.write(key: _localeKey, value: languageCode);
    } catch (_) {}
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
