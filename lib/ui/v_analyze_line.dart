/// One line of an intake build-moment checklist.
///
/// Both intakes used to show a bare determinate ring over a single rotating
/// line. That reads as dead time — the app is visibly WAITING rather than
/// visibly working, and the four things it is actually doing flashed past one
/// at a time and were gone.
///
/// The same strings become a checklist: each lands, ticks, and STAYS. The wait
/// accumulates into something, and by the end the person has read a list of
/// what was built for them instead of watching a circle.
library;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'v_icon.dart';

class AnalyzeLine extends StatelessWidget {
  const AnalyzeLine({
    super.key,
    required this.text,
    required this.reached,
    required this.shown,
  });

  final String text;

  /// The ring has passed this line's share of the work.
  final bool reached;

  /// Revealed a beat before it can tick, so lines appear in sequence rather
  /// than all at once.
  final bool shown;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AnimatedOpacity(
      opacity: shown ? 1 : 0,
      duration: VDuration.standard,
      curve: VMotion.curve,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 18,
              height: 20,
              child: Center(
                child: AnimatedScale(
                  scale: reached ? 1 : 0.6,
                  duration: VDuration.standard,
                  curve: VMotion.curve,
                  child: reached
                      ? VIcon(PhosphorIconsBold.check,
                          size: 14, color: t.goldDeep)
                      : Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: t.inkTertiary.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                style: VType.subhead
                    .copyWith(color: reached ? t.ink : t.inkSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
