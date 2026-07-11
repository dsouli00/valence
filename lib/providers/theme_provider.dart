import 'package:flutter/material.dart';

/// Light/dark mode toggle, consumed by MaterialApp's `themeMode`.
///
/// Starts on [ThemeMode.system] and is intentionally NOT persisted yet —
/// following the OS setting is the right default, and the toggle in Settings
/// only lasts for the session. If persistence is ever wanted, mirror
/// LocaleProvider's shared_preferences pattern.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Note: from `system`, the first toggle jumps to explicit light mode
  /// (isDarkMode is false for `system`), leaving system-follow behind.
  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
