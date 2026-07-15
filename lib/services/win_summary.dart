/// The client's REAL wins, computed from their own logs — the payload behind
/// the shareable progress card.
///
/// Why this exists: the old "daily win" copied a line of text about one day
/// ("hit 92% of calories"). Nobody brags about that, and nobody shares text.
/// A win worth posting is PROGRESS — weight moved toward the goal, a streak
/// that survived, weeks of consistency. That needs history, so this reads a
/// window of logs rather than today's.
///
/// Pure and deterministic (no I/O, no clock) so it can be unit-tested and can
/// never invent a number that isn't in the data. Everything here is a fact the
/// client can point at; nothing is estimated.
library;

import '../models/daily_log_model.dart';
import '../models/workout_models.dart';

/// Which fact earned the hero slot on the card.
enum WinHero {
  /// Weight moved toward their goal — the classic brag.
  weight,

  /// A run of consecutive logged days.
  streak,

  /// Showed up on most days in the window.
  consistency,
}

class WinSummary {
  /// Signed weight change over the window in canonical kg (negative = lost).
  /// Null when there aren't two weigh-ins to compare.
  final double? weightDeltaKg;

  /// Days between the first and last weigh-in — the honest span for the
  /// weight claim. Saying "in 8 weeks" when they only logged twice a month
  /// apart would be a lie the card can't back up.
  final int weightSpanDays;

  final int streak;

  /// Days in the window with any logged activity, out of days that existed.
  final int daysLogged;
  final int daysPossible;

  final int workoutsDone;

  /// Whether the weight movement counts as progress for THIS client's goal.
  /// Losing 4kg is a win when cutting and a problem when bulking.
  final bool weightIsProgress;

  const WinSummary({
    required this.weightDeltaKg,
    required this.weightSpanDays,
    required this.streak,
    required this.daysLogged,
    required this.daysPossible,
    required this.workoutsDone,
    required this.weightIsProgress,
  });

  /// Movement smaller than this is noise (scale drift, water weight) and is not
  /// worth putting on a card as an achievement.
  static const double _meaningfulKg = 0.5;

  /// Whether there is anything real to brag about at all. A card that says
  /// "0 days, no progress" is worse than no card.
  bool get hasAnything =>
      (weightDeltaKg != null && weightDeltaKg!.abs() >= _meaningfulKg && weightIsProgress) ||
      streak >= 2 ||
      daysLogged >= 2;

  /// The biggest true thing, in the order a human would brag about it.
  WinHero get hero {
    if (weightDeltaKg != null &&
        weightDeltaKg!.abs() >= _meaningfulKg &&
        weightIsProgress &&
        weightSpanDays >= 7) {
      return WinHero.weight;
    }
    if (streak >= 3) return WinHero.streak;
    return WinHero.consistency;
  }

  /// Consistency as a whole percentage, 0 when nothing was possible.
  int get consistencyPct =>
      daysPossible <= 0 ? 0 : ((daysLogged / daysPossible) * 100).round();
}

/// Reads [logs] (any order) + [workouts] into a [WinSummary].
///
/// [goal] is the client's `goal` field ('lose' | 'gain' | 'maintain') and
/// decides whether their weight movement is progress or a problem.
/// [joined] bounds the window so a new client's pre-signup days are never
/// counted as days they failed to show up (same rule as the adherence engine
/// and the AI digest).
WinSummary computeWinSummary({
  required List<DailyLog> logs,
  required List<AssignedWorkout> workouts,
  required DateTime today,
  required int windowDays,
  required String? goal,
  required DateTime joined,
  required int streak,
}) {
  final midnight = DateTime(today.year, today.month, today.day);
  final joinedDay = DateTime(joined.year, joined.month, joined.day);
  final start = midnight.subtract(Duration(days: windowDays - 1));
  final from = start.isBefore(joinedDay) ? joinedDay : start;

  bool inWindow(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return !day.isBefore(from) && !day.isAfter(midnight);
  }

  final windowed = logs.where((l) => inWindow(l.date)).toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  // Weigh-ins only — a day without a weight tells us nothing about the trend.
  final weighIns = windowed.where((l) => (l.weightKg ?? 0) > 0).toList();
  double? delta;
  var span = 0;
  if (weighIns.length >= 2) {
    delta = weighIns.last.weightKg! - weighIns.first.weightKg!;
    span = DateTime(weighIns.last.date.year, weighIns.last.date.month,
            weighIns.last.date.day)
        .difference(DateTime(weighIns.first.date.year,
            weighIns.first.date.month, weighIns.first.date.day))
        .inDays;
  }

  // 'maintain' has no direction to move in, so weight can never be the brag.
  final progress = switch (goal) {
    'lose' => delta != null && delta < 0,
    'gain' => delta != null && delta > 0,
    _ => false,
  };

  final logged = windowed.where((l) {
    final ate = l.meals.isNotEmpty || l.totalCalories > 0;
    final habit = (l.waterLiters ?? 0) > 0 ||
        (l.sleepRating ?? 0) > 0 ||
        (l.weightKg ?? 0) > 0;
    return ate || habit;
  }).length;

  final possible = midnight.difference(from).inDays + 1;

  final done = workouts
      .where((w) => w.isCompleted && inWindow(w.date))
      .length;

  return WinSummary(
    weightDeltaKg: delta,
    weightSpanDays: span,
    streak: streak,
    daysLogged: logged,
    daysPossible: possible < 0 ? 0 : possible,
    workoutsDone: done,
    weightIsProgress: progress,
  );
}
