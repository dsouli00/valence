/// [VSegmented] — the iOS-style segmented control (design.md §2). Container
/// `surfaceSubtle`, an `ink` pill that slides 240ms to the active segment,
/// inactive labels `inkSecondary`. `selectionClick` on change.
///
/// Used for Week/Month/Year, roster filters, detail tabs, kg|lb · cm|ft.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

/// One segment: a [value] and its [label].
class VSegment<T> {
  const VSegment(this.value, this.label);
  final T value;
  final String label;
}

class VSegmented<T> extends StatelessWidget {
  const VSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  }) : assert(segments.length > 0, 'VSegmented needs at least one segment');

  final List<VSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final n = segments.length;
    var index = segments.indexWhere((s) => s.value == selected);
    if (index < 0) index = 0;
    final alignX = n > 1 ? -1.0 + 2.0 * index / (n - 1) : 0.0;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.surfaceSubtle,
        borderRadius: BorderRadius.circular(VRadius.pill),
      ),
      child: SizedBox(
        height: 34,
        child: Stack(
          children: [
            // The sliding ink pill.
            AnimatedAlign(
              alignment: Alignment(alignX, 0),
              duration: reduceMotion ? Duration.zero : VDuration.standard,
              curve: VMotion.curve,
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: t.ink,
                    borderRadius: BorderRadius.circular(VRadius.pill),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < n; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (i == index) return;
                        HapticFeedback.selectionClick();
                        onChanged(segments[i].value);
                      },
                      child: Center(
                        child: Text(
                          segments[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VType.subhead.copyWith(
                            fontWeight: FontWeight.w600,
                            color: i == index ? t.onInk : t.inkSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
