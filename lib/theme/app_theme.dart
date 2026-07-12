/// Valence theme assembly — turns the design tokens (`tokens.dart`) into the
/// two `ThemeData`s the app runs on.
///
/// The design language is "warm paper + ink + gold" (design.md §0). Colors,
/// radii, spacing and type all resolve from [ValenceTokens] / [VType] / [VRadius]
/// — this file only wires them into Material's `ColorScheme`, `TextTheme` and
/// component themes so stock widgets inherit the look, and registers
/// [ValenceTokens] as a theme extension so `context.tokens` works everywhere.
///
/// [AppColors] and [AppSpacing] remain as LEGACY aliases while screens migrate
/// (design.md §3). New code must read `context.tokens`, [VType], [VSpace] etc.
/// directly — not these. The status hues + brand ink below are kept in sync
/// with §1.1 so unmigrated screens shift toward the new palette automatically.
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/enums.dart';
import 'tokens.dart';
import 'typography.dart';

/// LEGACY brand + status constants. Kept only so unmigrated screens keep
/// compiling; they now resolve to the design.md §1.1 hues. New code uses
/// `context.tokens`.
class AppColors {
  AppColors._();

  /// Warm brand ink (design.md `ink` light). Structure: fills, active states.
  static const Color primaryColor = Color(0xFF1A1814);

  /// The signature sandy gold — brand identity.
  static const Color secondaryColor = Color(0xFFC6A87C);

  // Status hues, warmed to §1.1 (good / watch / alert).
  static const Color statusGreen = Color(0xFF4E9160); // On track
  static const Color statusYellow = Color(0xFFC4922F); // Slipping
  static const Color statusRed = Color(0xFFD0654B); // At risk (also destructive)

  static Color getColorForStatus(ClientStatus status) {
    switch (status) {
      case ClientStatus.onTrack:
        return statusGreen;
      case ClientStatus.slipping:
        return statusYellow;
      case ClientStatus.atRisk:
        return statusRed;
      case ClientStatus.unconfigured:
        // Deliberately loud: unconfigured should never reach a themed surface
        // (screens render "Setup →" instead), so pink flags a missed case.
        return Colors.pink;
    }
  }
}

/// LEGACY screenutil-scaled spacing. New code uses [VSpace] (fixed logical
/// points). Kept because ~600 call sites still reference it.
class AppSpacing {
  AppSpacing._();
  static double p4 = 4.w;
  static double p8 = 8.w;
  static double p12 = 12.w;
  static double p16 = 16.w;
  static double p20 = 20.w;
  static double p24 = 24.w;
  static double p32 = 32.w;
}

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
