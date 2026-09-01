/// The "building your plan" moment, shared by both intakes.
///
/// WHY IT LOOKS LIKE THIS.
///
/// It was a Material `CircularProgressIndicator` with one line of text rotating
/// under it over 3000ms. Four things were wrong and they compounded into a
/// screen that read as dead time.
///
/// 1. A stock progress ring is off-brand BY CONSTRUCTION. Valence's language is
///    naked data as typography — the dashboard hero is a number that counts up,
///    and fill bars are the house shape (§5.7, v2.5). A Material spinner is the
///    one widget in the app that could have come from anywhere.
///
/// 2. NO HEADLINE. Every other intake step opens with a serif question. This
///    one had nothing, so next to its neighbours it looked unfinished rather
///    than quiet.
///
/// 3. The atmosphere was static. §1.9 permits the gold glow on Moment screens
///    and names "analyzing" as one — but a fixed wash is wallpaper. Here it
///    warms as the plan forms, so progress is FELT rather than only read.
///
/// 4. Nothing accumulated, and 3000ms across four steps is 750ms each. A plan
///    that computes that fast reads as a lookup table. The wait is the value
///    signal on this screen, not dead time to minimise.
library;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'v_atmosphere.dart';
import 'v_icon.dart';

class VBuildMoment extends StatelessWidget {
  const VBuildMoment({
    super.key,
    required this.title,
    required this.progress,
    required this.steps,
  });

  /// Serif headline — the beat every other step in the flow has.
  final String title;

  /// 0..1, driven by the caller's AnimationController.
  final double progress;

  /// The work being done, in order. Each becomes one checklist line.
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final p = progress.clamp(0.0, 1.0);
    final pct = (p * 100).round();

    return Stack(
      children: [
        // Warms from a whisper to a real glow as the plan forms. The screen's
        // own atmosphere doing the work, rather than a spinner.
        Positioned.fill(child: VSkyGlow(alpha: 0.06 + 0.16 * p)),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VTextScaleCap(
                  child: Text(
                    title,
                    style: VType.serifDisplay.copyWith(color: t.ink),
                  ),
                ),
                const SizedBox(height: 28),
                // The hero: a number that counts up, like every other hero in
                // the app. Tabular, so the width does not jitter as it climbs.
                VTextScaleCap(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('$pct', style: VType.stat(56).copyWith(color: t.ink)),
                      const SizedBox(width: 3),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(bottom: 7),
                        child: Text('%',
                            style: VType.title2.copyWith(color: t.goldDeep)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // The house fill bar, not a ring.
                ClipRRect(
                  borderRadius: BorderRadius.circular(VRadius.pill),
                  child: SizedBox(
                    height: 4,
                    child: Stack(
                      children: [
                        Container(color: t.surfaceSubtle),
                        FractionallySizedBox(
                          alignment: AlignmentDirectional.centerStart,
                          widthFactor: p,
                          child: Container(color: t.gold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 34),
                for (var i = 0; i < steps.length; i++)
                  _Step(
                    text: steps[i],
                    done: p >= (i + 1) / steps.length,
                    shown: p >= i / steps.length * 0.92,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.text, required this.done, required this.shown});

  final String text;
  final bool done;
  final bool shown;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AnimatedOpacity(
      opacity: shown ? 1 : 0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: Offset(0, shown ? 0 : 0.4),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // A tinted circle, the way every other icon in the app sits —
              // settings rows, sheet actions, macro columns. Bare glyphs on
              // canvas are what made the list read as unfinished text.
              AnimatedContainer(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOut,
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: done ? t.tintFill(t.gold) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  // elasticOut, not a fade — the tick is the only moment on
                  // this screen that says "done", so it should land with weight.
                  child: AnimatedScale(
                    scale: done ? 1 : 0.45,
                    duration: const Duration(milliseconds: 440),
                    curve: done ? Curves.elasticOut : Curves.easeOut,
                    child: done
                        ? VIcon(PhosphorIconsBold.check,
                            size: 14, color: t.legibleTint(t.gold))
                        : Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: t.inkTertiary.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 320),
                  style: VType.subhead.copyWith(
                    color: done ? t.ink : t.inkSecondary,
                    fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                  ),
                  child: Text(text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
