import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:valence/l10n/app_localizations.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/models/daily_log_model.dart';
import 'package:valence/models/target_macros.dart';
import 'package:valence/ui/ui.dart';
import 'package:valence/utils/units.dart';

/// Shared progress charts (calories, weight, habits score) rendered from a
/// list of DailyLogs. Used by BOTH the client's Progress tab and the coach's
/// client-details Analytics tab — improve here and both benefit. Charts are
/// custom-painted (no chart package dependency for three simple series).
///
/// DESIGN: VChart (design.md §2/§5.8) — series colors from the data tints
/// (calories=gold, weight=teal, habits=lilac), dashed `hairline` grid,
/// `surface`-filled dots with a tint ring on line charts, area fade 18% → 0,
/// `caption` axes, range = VSegmented, metric summary as VStatColumns.

// Normalization ceiling for the water component of the habits score.
const double _waterDailyMaxLiters = 4.0;

enum ChartRange { weekly, monthly, yearly }
enum ChartVisualType { line, bar }

extension ChartRangeX on ChartRange {
  String get label => switch (this) {
        ChartRange.weekly => 'Weekly',
        ChartRange.monthly => 'Monthly',
        ChartRange.yearly => 'Yearly',
      };

  int get days => switch (this) {
        ChartRange.weekly => 7,
        ChartRange.monthly => 30,
        ChartRange.yearly => 365,
      };

  String localizedLabel(AppLocalizations l) => switch (this) {
        ChartRange.weekly => l.chartWeekly,
        ChartRange.monthly => l.chartMonthly,
        ChartRange.yearly => l.chartYearly,
      };
}

class ProgressChartsSection extends StatelessWidget {
  final List<DailyLog> logs;
  final TargetMacros targets;
  final ChartRange? selectedRange;
  final ValueChanged<ChartRange>? onRangeChanged;

  /// The viewed client's display unit ('kg'|'lb'); the weight chart converts
  /// from the canonical kg logs accordingly.
  final String? weightUnit;

  /// Optional widget pinned above the charts, inside the same scroll view.
  ///
  /// Exists for the coach's AI analysis card, which must sit directly above
  /// the charts (they are its evidence surface) and scroll WITH them rather
  /// than fighting them in a second scroll area. Null on the client's Progress
  /// tab — deliberately: the analysis is written for the coach and a client
  /// must never see it.
  final Widget? header;

  const ProgressChartsSection({
    super.key,
    required this.logs,
    required this.targets,
    this.selectedRange,
    this.onRangeChanged,
    this.weightUnit,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    if (logs.isEmpty) {
      return VEmpty(
        icon: PhosphorIconsRegular.chartLineUp,
        title: context.l10n.navProgress,
        message: context.l10n.noProgressData,
      );
    }

    final metricWeight = isMetricWeight(weightUnit);
    final weightUnitLabel = metricWeight ? context.l10n.unitKg : context.l10n.unitLb;
    final weightValues = logs
        .map((e) => e.weightKg)
        .whereType<double>()
        .map((kg) => displayWeight(kg, weightUnit))
        .toList();
    final calorieValues = logs.map((e) => e.totalCalories.toDouble()).toList();
    final waterValues = logs.map((e) => e.waterLiters ?? 0.0).toList();
    final sleepValues = logs.map((e) => (e.sleepRating ?? 0).toDouble()).toList();
    final habitsValues = _buildHabitsScoreSeries(waterValues, sleepValues);

    final averageCalories = calorieValues.isEmpty
        ? 0.0
        : calorieValues.reduce((a, b) => a + b) / calorieValues.length;
    final averageWater = waterValues.isEmpty
        ? 0.0
        : waterValues.reduce((a, b) => a + b) / waterValues.length;
    final averageSleep = sleepValues.isEmpty
        ? 0.0
        : sleepValues.reduce((a, b) => a + b) / sleepValues.length;
    final averageHabits = habitsValues.isEmpty
        ? 0.0
        : habitsValues.reduce((a, b) => a + b) / habitsValues.length;
    final weightDelta = weightValues.length >= 2
        ? weightValues.last - weightValues.first
        : null;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsetsDirectional.fromSTEB(
        VSpace.screenMargin,
        16,
        VSpace.screenMargin,
        VSpace.scrollBottom + 72,
      ),
      children: [
        if (header != null) ...[
          header!,
          const SizedBox(height: 20),
        ],
        if (selectedRange != null && onRangeChanged != null) ...[
          VSegmented<ChartRange>(
            selected: selectedRange!,
            onChanged: onRangeChanged!,
            segments: [
              for (final range in ChartRange.values)
                VSegment(range, range.localizedLabel(context.l10n)),
            ],
          ),
          const SizedBox(height: 20),
        ],
        _ChartCard(
          title: context.l10n.caloriesLabel,
          subtitle: context.l10n.chartCaloriesSubtitle(
              averageCalories.toStringAsFixed(0), '${targets.calories}'),
          values: calorieValues,
          tint: t.gold,
          chartVisualType: ChartVisualType.bar,
          minYOverride: 0,
          startLabel: _formatDate(logs.first.date),
          endLabel: _formatDate(logs.last.date),
        ),
        const SizedBox(height: VSpace.cardGap),
        _ChartCard(
          title: context.l10n.weightLabel,
          subtitle: weightValues.length >= 2
              ? '${weightValues.first.toStringAsFixed(metricWeight ? 1 : 0)} → ${weightValues.last.toStringAsFixed(metricWeight ? 1 : 0)} $weightUnitLabel'
              : context.l10n.weightTrendHint,
          values: weightValues,
          tint: t.teal,
          startLabel: _formatDate(logs.first.date),
          endLabel: _formatDate(logs.last.date),
        ),
        const SizedBox(height: VSpace.cardGap),
        _ChartCard(
          title: context.l10n.habitsScore,
          subtitle: context.l10n.chartHabitsSubtitle(
              averageWater.toStringAsFixed(1), averageSleep.toStringAsFixed(1)),
          values: habitsValues,
          tint: t.lilac,
          chartVisualType: ChartVisualType.bar,
          minYOverride: 0,
          maxYOverride: 5,
          startLabel: _formatDate(logs.first.date),
          endLabel: _formatDate(logs.last.date),
        ),
        // Metric summary — naked numbers under the charts (§5.8).
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: VStatColumn(
                icon: PhosphorIconsFill.fire,
                tint: t.gold,
                value: averageCalories.toStringAsFixed(0),
                label: context.l10n.kcal,
                statSize: 20,
              ),
            ),
            Expanded(
              child: VStatColumn(
                icon: PhosphorIconsFill.scales,
                tint: t.teal,
                value: weightDelta == null
                    ? '—'
                    : '${weightDelta >= 0 ? '+' : ''}${weightDelta.toStringAsFixed(metricWeight ? 1 : 0)}',
                label: weightUnitLabel,
                statSize: 20,
              ),
            ),
            Expanded(
              child: VStatColumn(
                icon: PhosphorIconsFill.moon,
                tint: t.lilac,
                value: averageHabits.toStringAsFixed(1),
                label: context.l10n.habitsScore,
                statSize: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds a simple 0-5 composite habits score:
  /// 1) normalize water to 0-5 (assuming 4L/day max), 2) average with sleep (0-5).
  List<double> _buildHabitsScoreSeries(List<double> waterValues, List<double> sleepValues) {
    final count = math.min(waterValues.length, sleepValues.length);
    if (count == 0) return const [];
    return List.generate(count, (i) {
      // Scale water into a 0-5 range (matching sleep scale) assuming 4L/day max.
      final waterNormalized =
          (waterValues[i] / _waterDailyMaxLiters).clamp(0.0, 1.0) * 5;
      final sleepNormalized = sleepValues[i].clamp(0.0, 5.0);
      return ((waterNormalized + sleepNormalized) / 2.0).toDouble();
    });
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day';
  }
}

// ---------------------------------------------------------------------------
// Chart card — VChart in one quiet surface card: series dot + title, subhead
// summary, the painted chart over a dashed hairline grid, caption axes.
// ---------------------------------------------------------------------------

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<double> values;
  final Color tint;
  final String startLabel;
  final String endLabel;
  final double? minYOverride;
  final double? maxYOverride;
  final ChartVisualType chartVisualType;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.values,
    required this.tint,
    required this.startLabel,
    required this.endLabel,
    this.chartVisualType = ChartVisualType.line,
    this.minYOverride,
    this.maxYOverride,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Container(
      padding: const EdgeInsets.all(VSpace.cardPadding),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        boxShadow: t.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VType.headline.copyWith(color: t.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: VType.subhead.copyWith(
              color: t.inkSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: values.length < 2
                ? Center(
                    child: Text(
                      context.l10n.notEnoughData,
                      style: VType.caption.copyWith(color: t.inkTertiary),
                    ),
                  )
                : CustomPaint(
                    painter: chartVisualType == ChartVisualType.bar
                        ? _VBarChartPainter(
                            values: values,
                            color: tint,
                            gridColor: t.hairline,
                            minYOverride: minYOverride,
                            maxYOverride: maxYOverride,
                          )
                        : _VLineChartPainter(
                            values: values,
                            color: tint,
                            gridColor: t.hairline,
                            dotFill: t.surface,
                            minYOverride: minYOverride,
                            maxYOverride: maxYOverride,
                          ),
                    child: const SizedBox.expand(),
                  ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(startLabel,
                  style: VType.caption.copyWith(color: t.inkTertiary)),
              Text(endLabel,
                  style: VType.caption.copyWith(color: t.inkTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painters (VChart §2): dashed hairline grid behind both; line = 2.5px stroke
// with area fade 18% → 0 and surface-filled tint-ringed dots (when sparse);
// bars = solid tint, rounded.
// ---------------------------------------------------------------------------

void _paintDashedGrid(Canvas canvas, Size size, Color gridColor) {
  final paint = Paint()
    ..color = gridColor
    ..strokeWidth = 1;
  const dash = 4.0;
  const gap = 4.0;
  for (final f in const [0.25, 0.5, 0.75]) {
    final y = size.height * f;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dash, size.width), y),
        paint,
      );
      x += dash + gap;
    }
  }
}

class _VBarChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final Color gridColor;
  final double? minYOverride;
  final double? maxYOverride;

  _VBarChartPainter({
    required this.values,
    required this.color,
    required this.gridColor,
    this.minYOverride,
    this.maxYOverride,
  });

  /// Above this many points the series is averaged into buckets before it is
  /// drawn. A year of daily bars is unreadable at any width — at 365 points
  /// each bar is under a pixel — so the honest reduction is to average, not to
  /// silently drop the tail.
  static const int _maxBars = 60;

  List<double> _bucketed(List<double> src) {
    if (src.length <= _maxBars) return src;
    final out = <double>[];
    final size = src.length / _maxBars;
    for (var i = 0; i < _maxBars; i++) {
      final start = (i * size).floor();
      final end = ((i + 1) * size).ceil().clamp(start + 1, src.length);
      var sum = 0.0;
      for (var j = start; j < end; j++) {
        sum += src[j];
      }
      out.add(sum / (end - start));
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    _paintDashedGrid(canvas, size, gridColor);

    // Bars are laid out on PROPORTIONAL slots so the series always fits the
    // canvas exactly, at any point count.
    //
    // The previous version clamped bar width to a 3px floor but still advanced
    // the cursor by `barWidth + 4`, so a long series ran off the right edge:
    // 365 points needed ~2551px on a ~314px card, which drew roughly the first
    // 45 days and clipped the other 320. The same clamp capped bars at 18px,
    // which left a 7-day week filling under half the card and reading as a
    // broken chart rather than a sparse one. Both ranges were wrong; only the
    // 30-day one happened to land inside the canvas.
    final data = _bucketed(values);
    final n = data.length;

    final minValue = minYOverride ?? data.reduce(math.min);
    final maxValue = maxYOverride ?? data.reduce(math.max);
    final range = (maxValue - minValue).abs() < 0.0001 ? 1.0 : (maxValue - minValue);

    final paint = Paint()..color = color;
    final slot = size.width / n;
    final gap = (slot * 0.22).clamp(0.0, 6.0);
    final barWidth = math.max(1.0, slot - gap);

    for (var i = 0; i < n; i++) {
      final normalized = ((data[i] - minValue) / range).clamp(0.0, 1.0);
      final barHeight = normalized * (size.height - 8);
      final x = i * slot + gap / 2;
      final y = size.height - barHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(math.min(3, barWidth / 2)),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VBarChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.minYOverride != minYOverride ||
        oldDelegate.maxYOverride != maxYOverride;
  }
}

class _VLineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final Color gridColor;
  final Color dotFill;
  final double? minYOverride;
  final double? maxYOverride;

  _VLineChartPainter({
    required this.values,
    required this.color,
    required this.gridColor,
    required this.dotFill,
    this.minYOverride,
    this.maxYOverride,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    _paintDashedGrid(canvas, size, gridColor);

    final minValue = minYOverride ?? values.reduce(math.min);
    final maxValue = maxYOverride ?? values.reduce(math.max);
    final range = (maxValue - minValue).abs() < 0.0001 ? 1.0 : (maxValue - minValue);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.5;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.18),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Inset so edge dots don't clip.
    const insetX = 5.0;
    final chartWidth = size.width - insetX * 2;

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];

    final dx = chartWidth / (values.length - 1);
    for (var i = 0; i < values.length; i++) {
      final x = insetX + i * dx;
      final normalized = ((values[i] - minValue) / range).clamp(0.0, 1.0);
      final y = size.height - (normalized * (size.height - 12)) - 6;
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath
      ..lineTo(insetX + chartWidth, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Surface-filled dots with a tint ring — only when sparse enough to read.
    if (points.length <= 12) {
      final dotFillPaint = Paint()..color = dotFill;
      final dotRingPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (final p in points) {
        canvas.drawCircle(p, 3.5, dotFillPaint);
        canvas.drawCircle(p, 3.5, dotRingPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VLineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.dotFill != dotFill ||
        oldDelegate.minYOverride != minYOverride ||
        oldDelegate.maxYOverride != maxYOverride;
  }
}
