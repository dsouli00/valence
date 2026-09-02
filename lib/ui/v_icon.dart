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
/// HOW THIS IS DONE, AND WHY NOT THE OBVIOUS WAY.
///
/// The first version rebuilt each glyph as a fresh `IconData` with the flag
/// off. That works in debug and BREAKS EVERY AOT BUILD: the icon tree-shaker
/// has to know every codepoint statically, so a non-const `IconData(...)` call
/// fails the build outright — «Avoid non-constant invocations of IconData».
/// Profile and release, not just release, so it hid until the first profile
/// build.
///
/// `Icon` already takes a `textDirection` that overrides the inherited one, and
/// it is the ONLY thing `matchTextDirection` consults. Pinning it to ltr
/// suppresses the flip without touching the glyph — const icons stay const, the
/// tree-shaker stays happy, and the app keeps shipping only the glyphs it uses.
///
/// Pass `mirrorInRtl: true` for the genuine directional cases.
library;

import 'package:flutter/widgets.dart';

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
        icon,
        size: size,
        color: color,
        semanticLabel: semanticLabel,
        // null = inherit the ambient direction and mirror as Phosphor asks.
        textDirection: mirrorInRtl ? null : TextDirection.ltr,
      );
}
