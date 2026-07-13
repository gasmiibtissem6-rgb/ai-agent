import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_localizations.dart';

/// Holds the app's active [Locale] and persists the choice, mirroring
/// [ThemeNotifier]. The stored value is bootstrapped into [AppLocale.initial]
/// before `runApp` so the first frame already renders in the right language.
class LocaleNotifier extends Notifier<Locale> {
  static const _storage = FlutterSecureStorage();
  static const storageKey = 'app_locale';

  @override
  Locale build() => AppLocale.initial;

  /// Switches to [languageCode] ('en' | 'fr') and persists it. Unknown codes
  /// are ignored so a corrupted value can never break the UI.
  Future<void> setLanguage(String languageCode) async {
    if (!AppLocalizations.supportedLocales
        .any((l) => l.languageCode == languageCode)) {
      return;
    }
    final locale = Locale(languageCode);
    if (locale == state) return;
    state = locale;
    try {
      await _storage.write(key: storageKey, value: languageCode);
    } catch (_) {
      // Persistence is best-effort; the in-memory switch already happened.
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

/// Startup-time holder for the persisted locale (read once in `main`).
class AppLocale {
  const AppLocale._();

  static Locale initial = const Locale('en');

  /// Reads the saved language code from secure storage. Call before `runApp`.
  static Future<void> bootstrap() async {
    const storage = FlutterSecureStorage();
    try {
      final code = await storage.read(key: LocaleNotifier.storageKey);
      if (code != null &&
          AppLocalizations.supportedLocales
              .any((l) => l.languageCode == code)) {
        initial = Locale(code);
      }
    } catch (_) {
      initial = const Locale('en');
    }
  }
}
