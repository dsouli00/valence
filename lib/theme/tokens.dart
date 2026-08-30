/// Valence design tokens — the single source of truth for color, radius,
/// spacing, and motion (design.md §1). Everything visual in the app resolves
/// from here; screens and V-components must never invent literals.
///
/// Colors live in [ValenceTokens], a [ThemeExtension] that ships explicit
/// light + dark pairs (no `ColorScheme.fromSeed` guessing — every semantic
/// token in design.md §1.1 is spelled out). Read them anywhere with
/// `context.tokens`. Radius / spacing / motion are theme-independent const
/// scales ([VRadius], [VSpace], [VDuration], [VMotion]).
///
/// THE COLOR LAW (design.md §1.1): ink carries structure (button fills, active
/// states), gold carries identity (rings, washes, highlights, charts, moments).
/// Gold never fills large areas. Status hues are state only. Data tints are
/// data only. No fifth role.
library;

import 'package:flutter/material.dart';

/// Every semantic color in the design system, in light ("Day") and dark
/// ("Night"). Registered on both [ThemeData]s via `extensions` and read with
/// `context.tokens`.
@immutable
class ValenceTokens extends ThemeExtension<ValenceTokens> {
  // Structure -------------------------------------------------------------
  /// Scaffold background — the warm paper canvas.
  final Color canvas;

  /// Cards, sheets, tab bar.
  final Color surface;

  /// Input fills, inactive segments, skeleton base.
  final Color surfaceSubtle;

  // Ink (text + primary structure) ---------------------------------------
  /// Primary text; primary pill fill.
  final Color ink;

  /// Secondary text, sublines.
  final Color inkSecondary;

  /// Hints, meta, disabled.
  final Color inkTertiary;

  /// Text/icon on a primary (ink) pill.
  final Color onInk;

  // Gold (brand identity) -------------------------------------------------
  /// Brand accent: fills at tint alphas, rings, charts. Never large fills.
  final Color gold;

  /// Gold TEXT/ICON variant — legible on light surfaces (~4.5:1).
  final Color goldDeep;

  // Lines -----------------------------------------------------------------
  /// Separators + the few allowed rings.
  final Color hairline;

  // Status (state only) ---------------------------------------------------
  /// On track.
  final Color good;

  /// Slipping.
  final Color watch;

  /// At risk — also the destructive color.
  final Color alert;

  // Overlays --------------------------------------------------------------
  /// Behind sheets.
  final Color scrim;

  // Data tints (small glyphs, chart series, identity avatars ONLY) --------
  final Color sage;
  final Color steel;
  final Color clay;
  final Color lilac;
  final Color teal;

  /// Which theme this instance is — drives alpha conventions (tint fills are
  /// 12% on light, 16% on dark).
  final Brightness brightness;

  const ValenceTokens({
    required this.canvas,
    required this.surface,
    required this.surfaceSubtle,
    required this.ink,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.onInk,
    required this.gold,
    required this.goldDeep,
    required this.hairline,
    required this.good,
    required this.watch,
    required this.alert,
    required this.scrim,
    required this.sage,
    required this.steel,
    required this.clay,
    required this.lilac,
    required this.teal,
    required this.brightness,
  });

  /// Light ("Day") — the design-lead theme.
  static const ValenceTokens light = ValenceTokens(
    canvas: Color(0xFFF4F1E9),
    surface: Color(0xFFFDFCF8),
    surfaceSubtle: Color(0xFFECE8DD),
    ink: Color(0xFF1A1814),
    inkSecondary: Color(0xFF6E675C),
    inkTertiary: Color(0xFFA39B8D),
    onInk: Color(0xFFF7F4EC),
    gold: Color(0xFFC6A87C),
    // Deep enough to clear the ~4.5:1 contrast floor (§1.10) as TEXT on cream —
    // the lighter #A8875A washed out. Still a warm sandy bronze.
    goldDeep: Color(0xFF8C6A2E),
    hairline: Color(0xFFE3DED2),
    good: Color(0xFF4E9160),
    watch: Color(0xFFC4922F),
    alert: Color(0xFFD0654B),
    scrim: Color(0x661A1814), // ink @ 40%
    sage: Color(0xFF9BB08C),
    steel: Color(0xFF8FA7BC),
    clay: Color(0xFFC08D7C),
    lilac: Color(0xFFA79ABF),
    teal: Color(0xFF7CB0A5),
    brightness: Brightness.light,
  );

  /// Dark ("Night").
  static const ValenceTokens dark = ValenceTokens(
    canvas: Color(0xFF14120D),
    // v2.6 — dark got its own pass. §1.5 says the tone difference between
    // `surface` and `canvas` does the work in dark, because there is no shadow
    // there. It was not doing the work: the two sat 1.07:1 apart, LESS than
    // light's 1.099:1, and light also has a 6% shadow helping it. Cards nearly
    // vanished, and the invite-code boxes — the entire interaction of that
    // screen — read as seven faint rectangles.
    //
    // Lifted to 1.26:1, which is what the law already asks for. Not a border:
    // §6.2 forbids those, and the mechanism was never wrong, only timid.
    surface: Color(0xFF2C271E),
    surfaceSubtle: Color(0xFF3B3527),
    ink: Color(0xFFF1EDE3),
    inkSecondary: Color(0xFFA79F90),
    // Lifted with the surface so hints keep the 3.17:1 they had before; every
    // other ink token still clears its floor on the new ground unaided.
    inkTertiary: Color(0xFF7B7362),
    onInk: Color(0xFF14120D),
    gold: Color(0xFFC6A87C),
    // v2.6 — was #D4B98F, which was LESS saturated than `gold` (44.5% against
    // 39.4%… lighter, not stronger). Light gets this right: its goldDeep is
    // more saturated than gold, which is why the accent bites there and drifted
    // to beige here. An accent on a dark ground needs chroma, not luminance.
    // 57.3% saturation now, same hue family, 7.6:1 on the new surface.
    goldDeep: Color(0xFFD9B573),
    hairline: Color(0xFF433B2D),
    good: Color(0xFF6FAE7E),
    watch: Color(0xFFD8A64C),
    alert: Color(0xFFE27E62),
    scrim: Color(0x8C000000), // black @ 55%
    sage: Color(0xFF9BB08C),
    steel: Color(0xFF8FA7BC),
    clay: Color(0xFFC08D7C),
    lilac: Color(0xFFA79ABF),
    teal: Color(0xFF7CB0A5),
    brightness: Brightness.dark,
  );

  bool get isLight => brightness == Brightness.light;

  // Data-tint helpers -----------------------------------------------------

  /// The six data tints in fixed order (design.md §1.1). Identity avatars are
  /// name-hashed across this list; chart series pick from it.
  List<Color> get dataTints => [gold, sage, steel, clay, lilac, teal];

  /// Stable name → data-tint mapping for identity avatars. Same name always
  /// gets the same tint, in any session.
  Color identityTint(String seed) {
    if (seed.isEmpty) return gold;
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return dataTints[hash % dataTints.length];
  }

  // Alpha conventions (design.md §1.1) ------------------------------------

  /// Tint fill for icon circles / status pills: color @ 12% (light) / 16%
  /// (dark).
  Color tintFill(Color color) =>
      color.withValues(alpha: isLight ? 0.12 : 0.16);

  /// A legible glyph/icon color for [tint] on the current surface. Gold washes
  /// out on light, so it deepens to [goldDeep]; the mid-tone data tints read
  /// fine as small glyphs and pass through unchanged.
  Color legibleTint(Color tint) => (tint == gold && isLight) ? goldDeep : tint;

  /// Selected-option / calendar wash: gold @ 8%.
  Color get selectedWash => gold.withValues(alpha: 0.08);

  /// Pressed overlay for tappable surfaces: ink @ 4%.
  Color get pressedOverlay => ink.withValues(alpha: 0.04);

  /// The one card shadow (design.md §1.5): ink @ 6%, blur 24, y 6 — light only.
  /// In dark, tone difference does the work, so this returns an empty list.
  List<BoxShadow> get cardShadow => isLight
      ? [
          BoxShadow(
            color: ink.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ]
      : const [];

  @override
  ValenceTokens copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceSubtle,
    Color? ink,
    Color? inkSecondary,
    Color? inkTertiary,
    Color? onInk,
    Color? gold,
    Color? goldDeep,
    Color? hairline,
    Color? good,
    Color? watch,
    Color? alert,
    Color? scrim,
    Color? sage,
    Color? steel,
    Color? clay,
    Color? lilac,
    Color? teal,
    Brightness? brightness,
  }) {
    return ValenceTokens(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      ink: ink ?? this.ink,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      inkTertiary: inkTertiary ?? this.inkTertiary,
      onInk: onInk ?? this.onInk,
      gold: gold ?? this.gold,
      goldDeep: goldDeep ?? this.goldDeep,
      hairline: hairline ?? this.hairline,
      good: good ?? this.good,
      watch: watch ?? this.watch,
      alert: alert ?? this.alert,
      scrim: scrim ?? this.scrim,
      sage: sage ?? this.sage,
      steel: steel ?? this.steel,
      clay: clay ?? this.clay,
      lilac: lilac ?? this.lilac,
      teal: teal ?? this.teal,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  ValenceTokens lerp(ThemeExtension<ValenceTokens>? other, double t) {
    if (other is! ValenceTokens) return this;
    return ValenceTokens(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSecondary: Color.lerp(inkSecondary, other.inkSecondary, t)!,
      inkTertiary: Color.lerp(inkTertiary, other.inkTertiary, t)!,
      onInk: Color.lerp(onInk, other.onInk, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldDeep: Color.lerp(goldDeep, other.goldDeep, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      good: Color.lerp(good, other.good, t)!,
      watch: Color.lerp(watch, other.watch, t)!,
      alert: Color.lerp(alert, other.alert, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
      steel: Color.lerp(steel, other.steel, t)!,
      clay: Color.lerp(clay, other.clay, t)!,
      lilac: Color.lerp(lilac, other.lilac, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      brightness: t < 0.5 ? brightness : other.brightness,
    );
  }
}

/// `context.tokens` — the terse accessor, mirroring `context.l10n`.
extension ValenceTokensX on BuildContext {
  ValenceTokens get tokens => Theme.of(this).extension<ValenceTokens>()!;
}

/// Corner radii (design.md §1.4). People avatars are full circles (use the
/// element's own radius); everything else picks from here.
class VRadius {
  VRadius._();
  static const double card = 24;
  static const double cardSmall = 18;
  static const double sheetTop = 28;
  static const double input = 14;
  static const double pill = 999;
  static const double codeBox = 12;

  /// Thing-avatars (workouts, templates).
  static const double squircle = 14;
}

/// Spacing scale (design.md §1.3). Fixed logical points — Dynamic Type handles
/// text growth; layout stays on the grid.
class VSpace {
  VSpace._();
  static const double screenMargin = 20;
  static const double cardPadding = 18;
  static const double cardPaddingHero = 20;
  static const double cardGap = 12;
  static const double sectionGap = 28;
  static const double rowVPad = 14;
  static const double rowMinHeight = 64;

  /// Separator inset to text start.
  static const double separatorInset = 64;

  /// Scroll bottom padding (before the tab bar is added).
  static const double scrollBottom = 32;
}

/// Motion durations + curve (design.md §1.7). The five allowed animations use
/// these; nothing else moves on its own.
class VDuration {
  VDuration._();
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration entrance = Duration(milliseconds: 420);
  static const Duration fill = Duration(milliseconds: 550);
  static const Duration countUp = Duration(milliseconds: 650);

  /// The app's single looping animation — the at-risk breathing dot.
  static const Duration breathing = Duration(milliseconds: 2200);

  /// Skeleton shimmer sweep.
  static const Duration shimmer = Duration(milliseconds: 1400);
}

/// Motion constants (design.md §1.5/§1.7).
class VMotion {
  VMotion._();
  static const Curve curve = Curves.easeOutCubic;

  /// Pressed scale for everything tappable.
  static const double pressedScale = 0.98;
}
