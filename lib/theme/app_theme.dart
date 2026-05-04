import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primaryColor = Color(0xFF181A1F);
  static const Color secondaryColor = Color(0xFFC6A87C);

  // Status Colors (Mapped to ClientStatus)
  static const Color statusGreen = Color(0xFF4CAF50); // On Track
  static const Color statusYellow = Color(0xFFFFC107); // Slipping
  static const Color statusRed = Color(0xFFFF7043); // At Risk
}

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
    primary: const Color(0xFF5C6BC0),
    secondary: AppColors.secondaryColor,
    brightness: Brightness.dark,
  );

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final baseTextTheme = (colorScheme.brightness == Brightness.light
        ? ThemeData.light()
        : ThemeData.dark()).textTheme;

    final textTheme = GoogleFonts.interTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.poppins(textStyle: baseTextTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold)),
      displayMedium: GoogleFonts.poppins(textStyle: baseTextTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold)),
      displaySmall: GoogleFonts.poppins(textStyle: baseTextTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
      headlineLarge: GoogleFonts.poppins(textStyle: baseTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
      headlineMedium: GoogleFonts.poppins(textStyle: baseTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
      titleLarge: GoogleFonts.poppins(textStyle: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
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
      inputDecorationTheme: InputDecorationThemeData(
        labelStyle: TextStyle(color: colorScheme.secondary),
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
        hintStyle: TextStyle(color: colorScheme.secondary),
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