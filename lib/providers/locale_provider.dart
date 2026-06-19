import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One selectable app language: its locale code, the name written in its own
/// script (shown in the picker), and the English name (for reference/search).
class AppLanguage {
  final String code;
  final String nativeName;
  final String englishName;
  const AppLanguage(this.code, this.nativeName, this.englishName);
}

/// The languages Valence ships. Keep in sync with the .arb files in lib/l10n
/// and AppLocalizations.supportedLocales.
const List<AppLanguage> kAppLanguages = [
  AppLanguage('en', 'English', 'English'),
  AppLanguage('ar', 'العربية', 'Arabic'),
  AppLanguage('fr', 'Français', 'French'),
  AppLanguage('es', 'Español', 'Spanish'),
  AppLanguage('pt', 'Português', 'Portuguese'),
  AppLanguage('de', 'Deutsch', 'German'),
];

/// Holds the user's chosen app language and persists it across launches.
/// A null [locale] means "follow the device language" — Flutter then resolves
/// the device locale against the supported set (falling back to English).
class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = 'app_locale';

  Locale? _locale;
  Locale? get locale => _locale;

  LocaleProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  /// Sets the language (pass null to follow the device default) and persists it.
  Future<void> setLocale(Locale? locale) async {
    if (_locale?.languageCode == locale?.languageCode) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
  }
}
