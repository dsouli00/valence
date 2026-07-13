/// Data-as-typography primitives (design.md §2). No containers, no chrome —
/// numbers carry the weight.
///
/// - [VStatColumn] — a naked metric: tint glyph · number · label.
/// - [VQuietStats] — one-line `label value · label value · …`.
/// - [VHeroMetric] — dashboard hero: label · count-up number / target · fill bar.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

/// A single naked metric — icon over number over label, whitespace-separated.
class VStatColumn extends StatelessWidget {
  const VStatColumn({
    super.key,
    required this.icon,
    required this.tint,
    required this.value,
    this.label,
    this.statSize = 22,
  });

  final IconData icon;
  final Color tint;
  final String value;
  final String? label;
  final double statSize;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: t.legibleTint(tint)),
        const SizedBox(height: 6),
        VTextScaleCap(
          child: Text(value, style: VType.stat(statSize).copyWith(color: t.ink)),
        ),
        if (label != null) ...[
          const SizedBox(height: 2),
          Text(
            label!,
            style: VType.caption.copyWith(color: t.inkTertiary),
          ),
        ],
      ],
    );
  }
}

/// One-line stats: `label value · label value`. Labels quiet, values bold +
/// tabular. Pass `(label, value)` pairs.
class VQuietStats extends StatelessWidget {
  const VQuietStats({super.key, required this.pairs});

  final List<(String label, String value)> pairs;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final labelStyle = VType.subhead.copyWith(color: t.inkTertiary);
    final valueStyle = VType.subhead.copyWith(
      color: t.ink,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final sep = TextSpan(text: '  ·  ', style: labelStyle);

    final spans = <InlineSpan>[];
    for (var i = 0; i < pairs.length; i++) {
      if (i > 0) spans.add(sep);
      spans.add(TextSpan(text: '${pairs[i].$1} ', style: labelStyle));
      spans.add(TextSpan(text: pairs[i].$2, style: valueStyle));
    }
    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// The dashboard hero metric: caption label, a display number that counts up
/// once (dashboards only), " / target", and a fill bar (gold; `alert` when the
/// value exceeds target).
class VHeroMetric extends StatelessWidget {
  const VHeroMetric({
    super.key,
    required this.label,
    required this.value,
    required this.target,
    this.unit = '',
    this.fractionDigits = 0,
  });

  final String label;
  final num value;
  final num target;
  final String unit;
  final int fractionDigits;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final over = target > 0 && value > target;
    final fraction =
        target > 0 ? (value / target).clamp(0.0, 1.0).toDouble() : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: VType.caption.copyWith(color: t.inkSecondary)),
        const SizedBox(height: 4),
        VTextScaleCap(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value.toDouble()),
                duration: reduceMotion ? Duration.zero : VDuration.countUp,
                curve: VMotion.curve,
                builder: (context, v, _) => Text(
                  v.toStringAsFixed(fractionDigits),
                  style: VType.display.copyWith(color: t.ink),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ ${target.toStringAsFixed(fractionDigits)}$unit',
                style: VType.subhead.copyWith(color: t.inkSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(VRadius.pill),
          child: Container(
            height: 10,
            color: t.surfaceSubtle,
            child: AnimatedFractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: fraction,
              duration: reduceMotion ? Duration.zero : VDuration.fill,
              curve: VMotion.curve,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: over ? t.alert : t.gold,
                  borderRadius: BorderRadius.circular(VRadius.pill),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
