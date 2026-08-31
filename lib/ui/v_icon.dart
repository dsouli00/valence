/// Stops Phosphor glyphs mirroring themselves in Arabic.
///
/// `phosphor_flutter` sets `matchTextDirection: true` on EVERY icon it ships
/// (see `PhosphorIconData`'s constructor), so under `TextDirection.rtl` Flutter
/// flips all of them horizontally. Most Phosphor glyphs are near enough to
/// symmetric that nobody notices. The asymmetric ones are wrong, and two of
/// them carry meaning:
///
///   * the **checkmark** — a tick reads the same in every script, and mirrored
///     it just looks like a rendering fault;
///   * **trendUp** on the Progress tab — mirrored, the arrow points DOWN-left,
///     so an Arabic-speaking client's progress tab is labelled with a falling
///     graph.
///
/// `matchTextDirection` exists for glyphs whose meaning genuinely depends on
/// reading order — a "next" caret, a reply arrow, a speech bubble's tail. It is
/// the exception, not the default, and the package has it backwards.
///
/// [noMirrorIcon] rebuilds the same glyph with the flag off; [VIcon] is the
/// widget form. Pass `mirrorInRtl: true` for the genuine directional cases.
library;

import 'package:flutter/widgets.dart';

/// The same glyph, minus the automatic RTL flip.
IconData noMirrorIcon(IconData icon) => IconData(
      icon.codePoint,
      fontFamily: icon.fontFamily,
      fontPackage: icon.fontPackage,
      matchTextDirection: false,
    );

class VIcon extends StatelessWidget {
  const VIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
    this.mirrorInRtl = false,
  });

  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  /// True only for glyphs whose meaning follows reading order — a forward
  /// caret, a back arrow, a reply. Everything else keeps its shape.
  final bool mirrorInRtl;

  @override
  Widget build(BuildContext context) => Icon(
        mirrorInRtl ? icon : noMirrorIcon(icon),
        size: size,
        color: color,
        semanticLabel: semanticLabel,
      );
}
