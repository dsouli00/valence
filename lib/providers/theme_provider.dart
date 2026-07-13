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

  /// Explicitly set dark/light. Callers pass the switch's new value computed
  /// from the EFFECTIVE brightness (`Theme.of(context).brightness`), so the
  /// first toggle from `system` always changes what's on screen — the old
  /// `toggleTheme()` needed two presses when the OS was already dark
  /// (system→dark was a visual no-op).
  void setDark(bool dark) {
    final next = dark ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode == next) return;
    _themeMode = next;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
