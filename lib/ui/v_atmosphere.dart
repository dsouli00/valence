/// [VSkyGlow] — the only allowed atmosphere (design.md §1.9): a soft gold radial
/// fade from the top edge to nothing. Permitted on Moment screens ONLY
/// (cover/onboarding, analyzing, reveal, paywall, code-success). Working screens
/// sit on flat `canvas`.
///
/// Drop it as the first child of a Stack — it expands to fill and ignores taps.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class VSkyGlow extends StatelessWidget {
  const VSkyGlow({super.key, this.color, this.alpha = 0.12});

  /// Glow color — defaults to the brand gold.
  final Color? color;

  /// Peak opacity at the top edge (design.md §1.9 = 12%).
  final double alpha;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final glow = color ?? t.gold;
    // Gold muddies on cream far faster than it glows on dark — halve it on
    // light so the wash stays a whisper, not grime.
    final effAlpha = t.isLight ? alpha * 0.5 : alpha;
    return IgnorePointer(
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.85),
              radius: 1.1,
              colors: [
                glow.withValues(alpha: effAlpha),
                glow.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
