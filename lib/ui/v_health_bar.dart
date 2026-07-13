/// [VHealthBar] — the roster-pulse health bar (design.md §2 / §5.11): a h8 r999
/// stacked bar of solid status segments (good / watch / alert) with 3px gaps and
/// a one-time 550ms fill, plus quiet legend dots. NO glow (§6.3).
///
/// Segment widths are proportional to [total] (the WHOLE roster), so pending
/// clients (New / Setup — not part of the health grade) read as unfilled track
/// on the right. The fill animates once via a fixed-target tween, so it never
/// re-triggers when the parent rebuilds on search / filter (§1.7).
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

/// One band of the health bar: a status [color], its [count], and a legend
/// [label].
class VHealthSegment {
  const VHealthSegment({
    required this.color,
    required this.count,
    required this.label,
  });

  final Color color;
  final int count;
  final String label;
}

class VHealthBar extends StatelessWidget {
  const VHealthBar({
    super.key,
    required this.segments,
    required this.total,
    this.showLegend = true,
  });

  /// Bands in draw order (good → watch → alert). Zero-count bands are dropped.
  final List<VHealthSegment> segments;

  /// Denominator for the proportions — the full roster size, so pending
  /// clients leave the bar partly unfilled.
  final int total;

  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final active = [for (final s in segments) if (s.count > 0) s];
    final denom = total <= 0 ? 1 : total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 3.0;
            final gaps = active.length > 1 ? (active.length - 1) * gap : 0.0;
            final usable = (constraints.maxWidth - gaps).clamp(0.0, constraints.maxWidth);
            return SizedBox(
              height: 8,
              child: Stack(
                children: [
                  // Track — the unfilled remainder (pending clients live here).
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.surfaceSubtle,
                        borderRadius: BorderRadius.circular(VRadius.pill),
                      ),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: reduceMotion ? Duration.zero : VDuration.fill,
                    curve: VMotion.curve,
                    builder: (context, anim, _) => Row(
                      children: [
                        for (var i = 0; i < active.length; i++) ...[
                          if (i > 0) const SizedBox(width: gap),
                          Container(
                            height: 8,
                            width: usable * (active[i].count / denom) * anim,
                            decoration: BoxDecoration(
                              color: active[i].color,
                              borderRadius: BorderRadius.circular(VRadius.pill),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (showLegend && active.isNotEmpty) ...[
          const SizedBox(height: 12),
          VHealthLegend(segments: active),
        ],
      ],
    );
  }
}

/// The legend line on its own — dot · count · label per band — so screens can
/// compose it separately from the bar (e.g. the roster pulse header row).
class VHealthLegend extends StatelessWidget {
  const VHealthLegend({super.key, required this.segments});

  final List<VHealthSegment> segments;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final s in segments)
          if (s.count > 0)
            _LegendDot(color: s.color, count: s.count, label: s.label),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.count,
    required this.label,
  });

  final Color color;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: VType.subhead.copyWith(
            color: t.ink,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: VType.caption.copyWith(color: t.inkSecondary)),
      ],
    );
  }
}
