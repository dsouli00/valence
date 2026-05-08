import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:valence/models/daily_log_model.dart';
import 'package:valence/models/target_macros.dart';
import 'package:valence/theme/app_theme.dart';

class ProgressChartsSection extends StatelessWidget {
  final List<DailyLog> logs;
  final TargetMacros targets;

  const ProgressChartsSection({
    super.key,
    required this.logs,
    required this.targets,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (logs.isEmpty) {
      return Center(
        child: Text(
          'No progress data yet.',
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
        _ProgressChartCard(
          title: 'Calories',
          subtitle: 'Avg ${averageCalories.toStringAsFixed(0)} kcal • Target ${targets.calories}',
          values: calorieValues,
          lineColor: colorScheme.secondary,
          minYOverride: 0,
          startLabel: _formatDate(logs.first.date),
          endLabel: _formatDate(logs.last.date),
        ),
        const SizedBox(height: 12),
        _ProgressChartCard(
          title: 'Weight',
          subtitle: weightValues.length >= 2
              ? '${weightValues.first.toStringAsFixed(1)} → ${weightValues.last.toStringAsFixed(1)}'
              : 'Add daily weigh-ins to see trend',
          values: weightValues,
          lineColor: const Color(0xFF10B981),
          startLabel: _formatDate(logs.first.date),
          endLabel: _formatDate(logs.last.date),
        ),
        const SizedBox(height: 12),
        _ProgressChartCard(
          title: 'Habits',
          subtitle:
              'Water avg ${averageWater.toStringAsFixed(1)}L • Sleep avg ${averageSleep.toStringAsFixed(1)}/5',
          values: _combineHabits(waterValues, sleepValues),
          lineColor: const Color(0xFF6366F1),
          minYOverride: 0,
          maxYOverride: 5,
          startLabel: _formatDate(logs.first.date),
          endLabel: _formatDate(logs.last.date),
        ),
      ],
    );
  }

  List<double> _combineHabits(List<double> waterValues, List<double> sleepValues) {
    final count = math.min(waterValues.length, sleepValues.length);
    if (count == 0) return const [];
    return List.generate(count, (i) {
      final waterNormalized = (waterValues[i] / 4.0).clamp(0.0, 1.0) * 5;
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

class _ProgressChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<double> values;
  final Color lineColor;
  final String startLabel;
  final String endLabel;
  final double? minYOverride;
  final double? maxYOverride;

  const _ProgressChartCard({
    required this.title,
    required this.subtitle,
    required this.values,
    required this.lineColor,
    required this.startLabel,
    required this.endLabel,
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
        color: colorScheme.surfaceContainer,
        borderRadius: AppTheme.defaultBorderRadius,
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
                      'Not enough data',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: _SparklinePainter(
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
