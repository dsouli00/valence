/// Valence design system — the ONLY place colors, spacing and theme live.
///
/// The app's design language is "premium charcoal + gold": near-black brand
/// ink, a warm gold accent, and Material 3 color-scheme roles for everything
/// else. Screens must use `Theme.of(context).colorScheme.*` for surfaces and
/// text so light AND dark mode both work; the constants below are the only
/// literal colors allowed (brand + status), because they must stay identical
/// in both modes.
///
/// Do NOT invent new palettes per screen — premium comes from technique
/// (shadows, hairline borders, typography weight), not new colors. The
/// reference screen for the look is `lib/pages/client/client_home_screen.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/enums.dart';

/// Brand + status constants. Everything else comes from the ColorScheme.
class AppColors {
  AppColors._();

  // Brand: charcoal ink (also used as dark text ON gold buttons — gold bg +
  // light text is washed out, so gold buttons always use primaryColor ink).
  static const Color primaryColor = Color(0xFF181A1F);
  // Brand: the signature warm gold accent.
  static const Color secondaryColor = Color(0xFFC6A87C);

  // Status Colors (Mapped to ClientStatus) — used on the coach side to grade
  // client adherence. Keep in sync with the Alert/Watch/Good labels.
  static const Color statusGreen = Color(0xFF4CAF50); // On Track
  static const Color statusYellow = Color(0xFFFFC107); // Slipping
  static const Color statusRed = Color(0xFFFF7043); // At Risk

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
        // (screens use their own neutral grey for "Setup"), so pink flags a
        // spot that forgot to handle it.
        return Colors.pink;
    }
  }
}

/// Spacing scale (multiples of 4). Uses ScreenUtil's `.w` so paddings scale
/// with device width — that's why these are `static double`, not const.
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

/// Builds the light and dark [ThemeData]. Both are seeded from the charcoal
/// brand color so all M3 container roles (primaryContainer, surfaceContainerLow
/// etc.) are harmonized with it, then `secondary` is pinned to the brand gold.
class AppTheme {
  static const _seedColor = AppColors.primaryColor;
  static final BorderRadius defaultBorderRadius = BorderRadius.circular(12.r);

  static final _lightColorScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    primary: _seedColor,
    secondary: AppColors.secondaryColor,
    brightness: Brightness.light,
  );

  static final _darkColorScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    // Charcoal is invisible as `primary` on dark surfaces, so dark mode swaps
    // in an indigo primary; gold stays the shared accent in both modes.
    primary: const Color(0xFF5C6BC0),
    secondary: AppColors.secondaryColor,
    brightness: Brightness.dark,
  );

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final baseTextTheme = (colorScheme.brightness == Brightness.light
        ? ThemeData.light()
        : ThemeData.dark()).textTheme;

    // Typography: ONE grotesk voice. Inter Tight for display/headline/title
    // (tight tracking = the premium editorial look of Whoop/Linear-class apps),
    // Inter for body/label (readability at small sizes). Same superfamily, so
    // the app reads as one voice — the rounded Poppins template look is gone.
    final textTheme = GoogleFonts.interTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.interTight(textStyle: baseTextTheme.displayLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.5)),
      displayMedium: GoogleFonts.interTight(textStyle: baseTextTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.0)),
      displaySmall: GoogleFonts.interTight(textStyle: baseTextTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8)),
      headlineLarge: GoogleFonts.interTight(textStyle: baseTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6)),
      headlineMedium: GoogleFonts.interTight(textStyle: baseTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
      titleLarge: GoogleFonts.interTight(textStyle: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3)),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      // KNOWN CAVEAT: this global ElevatedButton pairs a gold background with
      // the light `onPrimary` foreground, which reads washed-out. Redesigned
      // screens avoid it with custom gold buttons using dark
      // AppColors.primaryColor ink (see settings_ui.dart GoldButton). If you
      // touch this, switching foregroundColor to a dark ink is the fix — but
      // re-check every legacy screen still using plain ElevatedButton.
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.secondary,
            foregroundColor: colorScheme.onPrimary,
            disabledBackgroundColor: colorScheme.onSurface.withAlpha(30),
            disabledForegroundColor: colorScheme.onSurface.withAlpha(30),
            shape: RoundedRectangleBorder(borderRadius: defaultBorderRadius),
            elevation: 2.0,
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          )
      ),
      // Text fields: filled, borderless until focused (gold focus ring).
      inputDecorationTheme: InputDecorationThemeData(
        labelStyle: TextStyle(color: colorScheme.onSurface,),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: defaultBorderRadius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: defaultBorderRadius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: defaultBorderRadius,
          borderSide: BorderSide(color: colorScheme.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
            borderRadius: defaultBorderRadius,
            borderSide: BorderSide(color: colorScheme.error)),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: defaultBorderRadius,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        hintStyle: TextStyle(color: colorScheme.onSurface.withAlpha(125)),
        isDense: true,
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: defaultBorderRadius),
        elevation: 0,
        color: colorScheme.surfaceContainer,
        margin: EdgeInsets.only(bottom: AppSpacing.p12),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
            side: BorderSide(color: colorScheme.outline),
            shape: RoundedRectangleBorder(
              borderRadius: defaultBorderRadius,
            ),
            padding: EdgeInsets.all(8.w),
            textStyle: textTheme.labelMedium,
          )
      ),
    );
  }

  static final ThemeData lightTheme = _buildTheme(_lightColorScheme);
  static final ThemeData darkTheme = _buildTheme(_darkColorScheme);
}