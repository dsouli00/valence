/// Buttons + small tappable chips (design.md §2). Every one presses via
/// [VPressable] and keeps a ≥44pt hit area.
///
/// - [VPillButton] — the pill family (primary / hero / secondary / gold /
///   destructive). THE default action everywhere is `.primary`.
/// - [VTextAction] — quiet gold text link ("See all", "Skip").
/// - [VIconCircle] — floating surface chip for back/menu/overflow.
/// - [VMiniPill] — outlined gold row-level action ("Assign", "+ Invite").
library;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'v_pressable.dart';

enum _VPill { primary, hero, secondary, gold, destructive }

/// The pill button. Height ≥52, fully rounded. Loading swaps the label for a
/// 20px spinner; disabled fills `surfaceSubtle` with `inkTertiary`.
class VPillButton extends StatelessWidget {
  const VPillButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  })  : _variant = _VPill.primary,
        _solid = true;

  /// Primary + a trailing 36px arrow circle. Max ONE per journey (final
  /// commits: "Start tracking", "Enter Valence").
  const VPillButton.hero({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expand = true,
  })  : icon = null,
        _variant = _VPill.hero,
        _solid = true;

  const VPillButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  })  : _variant = _VPill.secondary,
        _solid = false;

  /// Solid gold — RESERVED for at most one warm hero moment per flow; never
  /// paired with a primary on the same screen (design.md §2/§6).
  const VPillButton.gold({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  })  : _variant = _VPill.gold,
        _solid = true;

  /// `alert @ 12%` tint by default; [solid] `alert` only inside confirm sheets.
  const VPillButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    bool solid = false,
  })  : _variant = _VPill.destructive,
        _solid = solid;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final _VPill _variant;
  final bool _solid;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    // Resolve the four surfaces per variant + state.
    late Color fill;
    late Color fg;
    Color? border;
    switch (_variant) {
      case _VPill.primary:
      case _VPill.hero:
        fill = _enabled ? t.ink : t.surfaceSubtle;
        fg = _enabled ? t.onInk : t.inkTertiary;
      case _VPill.gold:
        fill = _enabled ? t.gold : t.surfaceSubtle;
        fg = _enabled ? const Color(0xFF1A1814) : t.inkTertiary;
      case _VPill.secondary:
        fill = Colors.transparent;
        fg = _enabled ? t.ink : t.inkTertiary;
        border = _enabled ? t.ink.withValues(alpha: 0.25) : t.hairline;
      case _VPill.destructive:
        if (_solid) {
          fill = _enabled ? t.alert : t.surfaceSubtle;
          fg = _enabled ? t.onInk : t.inkTertiary;
        } else {
          fill = _enabled ? t.alert.withValues(alpha: 0.12) : t.surfaceSubtle;
          fg = _enabled ? t.alert : t.inkTertiary;
        }
    }

    return VPressable(
      onTap: _enabled ? onPressed : null,
      enableFeedback: _enabled,
      builder: (context, pressed) {
        // Filled variants darken 6% on press; outlined/tinted rely on scale.
        final pressedFill = (pressed && fill.a == 1.0)
            ? Color.alphaBlend(Colors.black.withValues(alpha: 0.06), fill)
            : fill;
        return Container(
          width: expand ? double.infinity : null,
          constraints: const BoxConstraints(minHeight: 52),
          alignment: Alignment.center,
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: _variant == _VPill.hero ? 24 : 22,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: pressedFill,
            borderRadius: BorderRadius.circular(VRadius.pill),
            border: border == null
                ? null
                : Border.all(color: border, width: 1.5),
          ),
          child: _content(t, fg),
        );
      },
    );
  }

  Widget _content(ValenceTokens t, Color fg) {
    if (loading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
      );
    }

    final w = _variant == _VPill.secondary ? FontWeight.w600 : FontWeight.w700;

    // A button label must never clip and never wrap. `maxLines: 1` stops the
    // wrap (which made two buttons in a row end up different heights), and
    // scaleDown stops the clip — a long translation shrinks a little instead
    // of being cut off mid-glyph.
    //
    // This is a floor, not a licence to squeeze buttons: it exists because
    // every label here is localized into six languages and the German or
    // Portuguese string is routinely 40% longer than the English one it was
    // laid out against. Give the button real room; let this catch the rest.
    final text = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 1,
      softWrap: false,
      style: VType.headline.copyWith(color: fg, fontWeight: w),
    );
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: text)),
      ],
    );

    if (_variant != _VPill.hero) return row;

    // Hero: centered label with a trailing arrow circle that never shifts it.
    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 40),
          child: FittedBox(fit: BoxFit.scaleDown, child: text),
        ),
        PositionedDirectional(
          end: 0,
          child: Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(PhosphorIconsBold.arrowRight, size: 16, color: fg),
          ),
        ),
      ],
    );
  }
}

/// Quiet gold text link — 15 w600 `goldDeep`, optional trailing caret.
class VTextAction extends StatelessWidget {
  const VTextAction({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.arrow = false,
    this.color,
    this.dot = false,
  });

  final String label;
  final VoidCallback? onTap;

  /// Optional leading glyph (14px).
  final IconData? icon;

  /// Trailing caret (e.g. "Setup →").
  final bool arrow;

  /// Override the gold — e.g. `alert` for "N need you →".
  final Color? color;

  /// Leading status dot, matching [VStatusPill]'s.
  ///
  /// The roster has four states and only three of them read as states: Alert,
  /// Watch and Good are dot-and-word pills, while Setup was bare gold text with
  /// a caret. Scanning the column, the Setup row looked EMPTY rather than
  /// "waiting for you" — the one row that most needs the coach's attention.
  /// Setup stays an action (it goes somewhere; the pills don't), it just earns
  /// the same dot so the column reads as one thing.
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = color ?? t.goldDeep;
    return VPressable(
      onTap: onTap,
      scale: 1.0,
      child: Padding(
        // Grows the 15px text to a ≥44pt hit target.
        // 8, not 2. At 2 this butted straight against the sentence before it:
        // "Don't have an account?Sign up" — and worse in French, where the
        // space before "?" made it read "Vous avez déjà un compte ?Se
        // connecter". The vertical 11 already carries the 44pt target.
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            if (icon != null) ...[
              Icon(icon, size: 14, color: c),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: VType.body.copyWith(color: c, fontWeight: FontWeight.w600),
            ),
            if (arrow) ...[
              const SizedBox(width: 4),
              Icon(PhosphorIconsBold.caretRight, size: 13, color: c),
            ],
          ],
        ),
      ),
    );
  }
}

/// Floating round chip on `surface` with the one card shadow — replaces AppBar
/// icon rows. Back/menu/overflow.
class VIconCircle extends StatelessWidget {
  const VIconCircle({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.size = 40,
    this.iconSize = 20,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final double size;
  final double iconSize;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hit = size < 44 ? 44.0 : size;
    return Semantics(
      label: semanticLabel,
      button: true,
      child: VPressable(
        onTap: onTap,
        semanticButton: false,
        child: SizedBox(
          width: hit,
          height: hit,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: t.surface,
                shape: BoxShape.circle,
                boxShadow: t.cardShadow,
              ),
              child: Icon(icon, size: iconSize, color: iconColor ?? t.ink),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small outlined gold action pill for row-level actions.
class VMiniPill extends StatelessWidget {
  const VMiniPill({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return VPressable(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VRadius.pill),
          border: Border.all(color: t.gold.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: t.goldDeep),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: VType.subhead
                  .copyWith(color: t.goldDeep, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
