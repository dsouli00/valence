/// Valence type ramp (design.md §1.2). Two voices: **Inter Tight** runs the app
/// (display/UI grotesk), **Inter** speaks the small print, **Fraunces** is "the
/// Voice" for human moments.
///
/// Styles are colorless by default — components apply a token color with
/// `.copyWith(color: context.tokens.ink)`. Numbers that can change carry
/// `tabularFigures` so they never jitter.
///
/// Rules baked in: serif only ≥24px and never for data/rows/buttons; max weight
/// w800 (calm); uppercase+tracking lives only in [label].
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The named editorial styles. Use these directly in V-components — never
/// hand-roll a `TextStyle` with a raw font size.
class VType {
  VType._();

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// Fraunces 32/1.15 w600 — onboarding questions, hero greetings, reveal.
  static TextStyle get serifDisplay => GoogleFonts.fraunces(
        fontSize: 32,
        height: 1.15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      );

  /// Fraunces 24/1.2 w600 — moment-screen statements.
  static TextStyle get serifTitle => GoogleFonts.fraunces(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      );

  /// Inter Tight 40/1.0 w800 — hero numbers (calories). Tabular.
  static TextStyle get display => GoogleFonts.interTight(
        fontSize: 40,
        height: 1.0,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        fontFeatures: _tabular,
      );

  /// Inter Tight 26/1.15 w800 — screen titles.
  static TextStyle get title1 => GoogleFonts.interTight(
        fontSize: 26,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      );

  /// Inter Tight 20/1.2 w700 — section heads ("Recovery").
  static TextStyle get title2 => GoogleFonts.interTight(
        fontSize: 20,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      );

  /// Inter Tight 17/1.25 w700 — row/card titles.
  static TextStyle get headline => GoogleFonts.interTight(
        fontSize: 17,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      );

  /// Inter Tight w800 — metric numbers (tabular). Size 22–28 (default 24).
  static TextStyle stat([double size = 24]) => GoogleFonts.interTight(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        fontFeatures: _tabular,
      );

  /// Inter 15/1.45 w500 — paragraphs.
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 15,
        height: 1.45,
        fontWeight: FontWeight.w500,
      );

  /// Inter 13/1.4 w500 — sublines, secondary info.
  static TextStyle get subhead => GoogleFonts.inter(
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w500,
      );

  /// Inter 12/1.3 w500 — meta, timestamps, units.
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w500,
      );

  /// Inter 11/1.2 w700 +0.8 — settings group headers ONLY. Caller uppercases
  /// the text (`.toUpperCase()`); the tracking lives here.
  static TextStyle get label => GoogleFonts.inter(
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      );
}

/// Caps the text-scale of hero numbers (display / stat / serifDisplay) so dense
/// metric rows never collide (design.md §1.10 — max 1.15 for these styles,
/// versus the 0.85–1.3 app-wide clamp). Wrap the number, not the whole screen.
class VTextScaleCap extends StatelessWidget {
  const VTextScaleCap({super.key, this.max = 1.15, required this.child});

  final double max;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(
        textScaler: mq.textScaler.clamp(maxScaleFactor: max),
      ),
      child: child,
    );
  }
}
