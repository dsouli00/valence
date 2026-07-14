/// Valence theme assembly — turns the design tokens (`tokens.dart`) into the
/// two `ThemeData`s the app runs on.
///
/// The design language is "warm paper + ink + gold" (design.md §0). Colors,
/// radii, spacing and type all resolve from [ValenceTokens] / [VType] / [VRadius]
/// — this file only wires them into Material's `ColorScheme`, `TextTheme` and
/// component themes so stock widgets inherit the look, and registers
/// [ValenceTokens] as a theme extension so `context.tokens` works everywhere.
///
/// The AppColors/AppSpacing legacy aliases are GONE (Phase 7 cleanup,
/// design.md §7): every screen reads `context.tokens`, [VType], [VSpace] etc.
library;

import 'package:flutter/material.dart';

import 'tokens.dart';
import 'typography.dart';

/// Builds the light ("Day") and dark ("Night") themes from [ValenceTokens].
/// Both ship day one — light is the design lead.
class AppTheme {
  AppTheme._();

  static ColorScheme _scheme(ValenceTokens t) => ColorScheme(
        brightness: t.brightness,
        primary: t.ink,
        onPrimary: t.onInk,
        secondary: t.gold,
        onSecondary: t.ink, // dark ink on gold — light-on-gold is washed out
        tertiary: t.goldDeep,
        onTertiary: t.onInk,
        error: t.alert,
        onError: t.onInk,
        surface: t.canvas,
        onSurface: t.ink,
        surfaceDim: t.surfaceSubtle,
        surfaceBright: t.surface,
        surfaceContainerLowest: t.surface,
        surfaceContainerLow: t.surface,
        surfaceContainer: t.surface,
        surfaceContainerHigh: t.surfaceSubtle,
        surfaceContainerHighest: t.surfaceSubtle,
        onSurfaceVariant: t.inkSecondary,
        outline: t.hairline,
        outlineVariant: t.hairline,
        scrim: t.scrim,
        shadow: const Color(0xFF000000),
      );

  /// Maps the §1.2 ramp onto Material's slots so stock widgets read on-brand.
  /// V-components use [VType] directly.
  static TextTheme _textTheme(ValenceTokens t) => TextTheme(
        displayLarge: VType.display,
        displayMedium: VType.title1,
        displaySmall: VType.title1,
        headlineLarge: VType.title1,
        headlineMedium: VType.title2,
        headlineSmall: VType.title2,
        titleLarge: VType.title2,
        titleMedium: VType.headline,
        titleSmall: VType.headline,
        bodyLarge: VType.body,
        bodyMedium: VType.body,
        bodySmall: VType.subhead,
        labelLarge: VType.headline,
        labelMedium: VType.caption,
        labelSmall: VType.label,
      ).apply(bodyColor: t.ink, displayColor: t.ink);

  static ThemeData _build(ValenceTokens t) {
    final scheme = _scheme(t);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(VRadius.input),
      borderSide: BorderSide.none,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: t.brightness,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[t],
      textTheme: _textTheme(t),
      scaffoldBackgroundColor: t.canvas,
      canvasColor: t.canvas,
      // Purely-iOS: Cupertino push/pop on every platform (design.md §0).
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      dividerTheme: DividerThemeData(color: t.hairline, thickness: 1, space: 1),
      // The gold/onPrimary ElevatedButton is RETIRED (design.md §3). Any legacy
      // ElevatedButton now renders as the ink pill (matches VPillButton.primary).
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.ink,
          foregroundColor: t.onInk,
          disabledBackgroundColor: t.surfaceSubtle,
          disabledForegroundColor: t.inkTertiary,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: VType.headline,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.ink,
          side: BorderSide(color: t.ink.withValues(alpha: 0.25), width: 1.5),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: VType.headline,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.goldDeep,
          textStyle: VType.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      // Filled, borderless until focused (gold focus ring) — matches VField.
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: t.surfaceSubtle,
        isDense: true,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VRadius.input),
          borderSide: BorderSide(color: t.gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VRadius.input),
          borderSide: BorderSide(color: t.alert, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VRadius.input),
          borderSide: BorderSide(color: t.alert, width: 1.5),
        ),
        hintStyle: VType.body.copyWith(color: t.inkTertiary),
        labelStyle: VType.subhead.copyWith(color: t.inkSecondary),
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VRadius.card),
        ),
      ),
    );
  }

  static final ThemeData lightTheme = _build(ValenceTokens.light);
  static final ThemeData darkTheme = _build(ValenceTokens.dark);
}
