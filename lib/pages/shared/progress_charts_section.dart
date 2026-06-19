import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:valence/l10n/app_localizations.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/models/daily_log_model.dart';
import 'package:valence/models/target_macros.dart';
import 'package:valence/theme/app_theme.dart';

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

  const ProgressChartsSection({
    super.key,
    required this.logs,
    required this.targets,
    this.selectedRange,
    this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (logs.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noProgressData,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final weightValues = logs
        .map((e) => e.weightKg)
        .whereType<double>()
        .toList();
    final calorieValues = logs.map((e) => e.totalCalories.toDouble()).toList();
    final waterValues = logs.map((e) => e.waterLiters ?? 0.0).toList();
    final sleepValues = logs.map((e) => (e.sleepRating ?? 0).toDouble()).toList();

    final averageCalories = calorieValues.isEmpty
        ? 0
        : calorieValues.reduce((a, b) => a + b) / calorieValues.length;
    final averageWater = waterValues.isEmpty
        ? 0
        : waterValues.reduce((a, b) => a + b) / waterValues.length;
    final averageSleep = sleepValues.isEmpty
        ? 0
        : sleepValues.reduce((a, b) => a + b) / sleepValues.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (selectedRange != null && onRangeChanged != null) ...[
          _RangeSelector(
            selectedRange: selectedRange!,
            onChanged: onRangeChanged!,
          ),
          const SizedBox(height: 12),
        ],
        _ProgressChartCard(
          title: context.l10n.caloriesLabel,
          subtitle: context.l10n.chartCaloriesSubtitle(averageCalories.toStringAsFixed(0), '${targets.calories}'),
          values: calorieValues,
          lineColor: colorScheme.secondary,
          chartVisualType: ChartVisualType.bar,
          minYOverride: 0,
          startLabel: _formatDate(logs.first.date),
          endLabel: _formatDate(logs.last.date),
        ),
        const SizedBox(height: 12),
        _ProgressChartCard(
          title: context.l10n.weightLabel,
          subtitle: weightValues.length >= 2
              ? '${weightValues.first.toStringAsFixed(1)} → ${weightValues.last.toStringAsFixed(1)}'
              : context.l10n.weightTrendHint,
          values: weightValues,
          lineColor: AppColors.statusGreen,
          startLabel: _formatDate(logs.first.date),
          endLabel: _formatDate(logs.last.date),
        ),
        const SizedBox(height: 12),
        _ProgressChartCard(
          title: context.l10n.habitsScore,
          subtitle:
              context.l10n.chartHabitsSubtitle(averageWater.toStringAsFixed(1), averageSleep.toStringAsFixed(1)),
          values: _buildHabitsScoreSeries(waterValues, sleepValues),
          lineColor: const Color(0xFF6366F1),
          chartVisualType: ChartVisualType.bar,
          minYOverride: 0,
          maxYOverride: 5,
          startLabel: _formatDate(logs.first.date),
          endLabel: _formatDate(logs.last.date),
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

class _RangeSelector extends StatelessWidget {
  final ChartRange selectedRange;
  final ValueChanged<ChartRange> onChanged;

  const _RangeSelector({
    required this.selectedRange,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ChartRange.values.map((range) {
          final isSelected = range == selectedRange;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(range),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  range.localizedLabel(context.l10n),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? colorScheme.secondary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProgressChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<double> values;
  final Color lineColor;
  final String startLabel;
  final String endLabel;
  final double? minYOverride;
  final double? maxYOverride;
  final ChartVisualType chartVisualType;

  const _ProgressChartCard({
    required this.title,
    required this.subtitle,
    required this.values,
    required this.lineColor,
    required this.startLabel,
    required this.endLabel,
    this.chartVisualType = ChartVisualType.line,
    this.minYOverride,
    this.maxYOverride,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: lineColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: values.length < 2
                ? Center(
                    child: Text(
                      context.l10n.notEnoughData,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: chartVisualType == ChartVisualType.bar
                        ? _BarChartPainter(
                            values: values,
                            color: lineColor,
                            minYOverride: minYOverride,
                            maxYOverride: maxYOverride,
                          )
                        : _SparklinePainter(
                            values: values,
                            color: lineColor,
                            minYOverride: minYOverride,
                            maxYOverride: maxYOverride,
                          ),
                    child: const SizedBox.expand(),
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(startLabel, style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              Text(endLabel, style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double? minYOverride;
  final double? maxYOverride;

  _BarChartPainter({
    required this.values,
    required this.color,
    this.minYOverride,
    this.maxYOverride,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final minValue = minYOverride ?? values.reduce(math.min);
    final maxValue = maxYOverride ?? values.reduce(math.max);
    final range = (maxValue - minValue).abs() < 0.0001 ? 1.0 : (maxValue - minValue);

    final paint = Paint()..color = color.withOpacity(0.9);
    const spacing = 4.0;
    final barWidth = (((size.width - (values.length - 1) * spacing) / values.length)
            .clamp(3.0, 18.0))
        .toDouble();

    for (var i = 0; i < values.length; i++) {
      final normalized = ((values[i] - minValue) / range).clamp(0.0, 1.0);
      final barHeight = normalized * (size.height - 8);
      final x = i * (barWidth + spacing);
      final y = size.height - barHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.minYOverride != minYOverride ||
        oldDelegate.maxYOverride != maxYOverride;
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double? minYOverride;
  final double? maxYOverride;

  _SparklinePainter({
    required this.values,
    required this.color,
    this.minYOverride,
    this.maxYOverride,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minValue = minYOverride ?? values.reduce(math.min);
    final maxValue = maxYOverride ?? values.reduce(math.max);
    final range = (maxValue - minValue).abs() < 0.0001 ? 1.0 : (maxValue - minValue);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.22),
          color.withOpacity(0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final dx = size.width / (values.length - 1);
    for (var i = 0; i < values.length; i++) {
      final x = i * dx;
      final normalized = ((values[i] - minValue) / range).clamp(0.0, 1.0);
      final y = size.height - (normalized * (size.height - 8)) - 4;

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
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.minYOverride != minYOverride ||
        oldDelegate.maxYOverride != maxYOverride;
  }
}
