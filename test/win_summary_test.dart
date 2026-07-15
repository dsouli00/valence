// Unit tests for the shareable progress card's numbers (pure Dart).
//
// This card gets POSTED PUBLICLY with the client's name and their coach's name
// on it. Every number has to be a fact they can point at — an invented or
// flattering figure is worse here than anywhere else in the app, because it
// goes on the internet under someone's real identity.

import 'package:flutter_test/flutter_test.dart';
import 'package:valence/models/daily_log_model.dart';
import 'package:valence/models/workout_models.dart';
import 'package:valence/services/win_summary.dart';

final today = DateTime(2026, 7, 15);
final longAgo = DateTime(2026, 1, 1);

DailyLog log(int daysBack, {int calories = 0, double water = 0, double weight = 0}) {
  final d = today.subtract(Duration(days: daysBack));
  return DailyLog(
    id: 'x',
    clientId: 'c1',
    coachId: 'coach1',
    date: d,
    meals: const [],
    totalCalories: calories,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    waterLiters: water,
    sleepRating: 0,
    weightKg: weight,
  );
}

AssignedWorkout workout(int daysBack, {bool done = true}) => AssignedWorkout(
      id: 'w',
      clientId: 'c1',
      coachId: 'coach1',
      date: today.subtract(Duration(days: daysBack)),
      title: 'Session',
      exercises: const [],
      isCompleted: done,
    );

WinSummary compute({
  List<DailyLog> logs = const [],
  List<AssignedWorkout> workouts = const [],
  String? goal = 'lose',
  DateTime? joined,
  int streak = 0,
  int windowDays = 30,
}) =>
    computeWinSummary(
      logs: logs,
      workouts: workouts,
      today: today,
      windowDays: windowDays,
      goal: goal,
      joined: joined ?? longAgo,
      streak: streak,
    );

void main() {
  group('weight — the headline brag', () {
    test('measures first to last weigh-in in the window', () {
      final s = compute(logs: [log(28, weight: 82.0), log(2, weight: 77.8)]);
      expect(s.weightDeltaKg, closeTo(-4.2, 0.001));
      expect(s.weightSpanDays, 26);
      expect(s.weightIsProgress, isTrue);
      expect(s.hero, WinHero.weight);
    });

    test('RULE: losing is only a win if the goal is to lose', () {
      // Same 4kg drop. For someone bulking this is a PROBLEM, and putting it on
      // a card as an achievement would be absurd.
      final logs = [log(28, weight: 82.0), log(2, weight: 77.8)];
      expect(compute(logs: logs, goal: 'lose').weightIsProgress, isTrue);
      expect(compute(logs: logs, goal: 'gain').weightIsProgress, isFalse);
      expect(compute(logs: logs, goal: 'maintain').weightIsProgress, isFalse);
    });

    test('gaining is the win when the goal is to gain', () {
      final s = compute(logs: [log(28, weight: 70.0), log(2, weight: 73.0)], goal: 'gain');
      expect(s.weightIsProgress, isTrue);
      expect(s.hero, WinHero.weight);
    });

    test('RULE: sub-0.5kg movement is noise, not an achievement', () {
      // Scale drift and water weight. Never the hero.
      final s = compute(
        logs: [log(28, weight: 78.0), log(2, weight: 77.7)],
        streak: 5,
      );
      expect(s.hero, isNot(WinHero.weight));
    });

    test('RULE: one weigh-in proves no trend', () {
      final s = compute(logs: [log(2, weight: 78.0)]);
      expect(s.weightDeltaKg, isNull);
      expect(s.hero, isNot(WinHero.weight));
    });

    test('RULE: the span is the weigh-ins, not the window', () {
      // Weighed twice 3 days apart inside a 30-day window. Claiming "in 4
      // weeks" would be a lie the data cannot back.
      final s = compute(logs: [log(5, weight: 82.0), log(2, weight: 81.0)]);
      expect(s.weightSpanDays, 3);
      // Too short a span to headline, even though the drop is real.
      expect(s.hero, isNot(WinHero.weight));
    });
  });

  group('hero selection — the biggest TRUE thing', () {
    test('weight outranks streak when both are real', () {
      final s = compute(
        logs: [log(28, weight: 82.0), log(2, weight: 77.8)],
        streak: 12,
      );
      expect(s.hero, WinHero.weight);
    });

    test('streak takes over when there is no weight story', () {
      expect(compute(streak: 12, logs: [log(1, calories: 2000)]).hero, WinHero.streak);
    });

    test('consistency is the fallback', () {
      final s = compute(streak: 1, logs: [log(1, calories: 2000), log(2, water: 2)]);
      expect(s.hero, WinHero.consistency);
    });
  });

  group('nothing to brag about', () {
    test('RULE: an empty client gets no card at all', () {
      // A card saying "0 days, no progress" is worse than no card.
      expect(compute().hasAnything, isFalse);
    });

    test('two logged days is enough to have something', () {
      expect(compute(logs: [log(1, calories: 2000), log(2, water: 2)]).hasAnything, isTrue);
    });

    test('a wrong-direction weight change alone is not a brag', () {
      // Gained 4kg while trying to lose, nothing else logged.
      final s = compute(logs: [log(28, weight: 78.0), log(27, weight: 82.0)], goal: 'lose');
      expect(s.weightIsProgress, isFalse);
      // Those two weigh-ins are still logged days, so it has SOMETHING — but
      // the gain must never be the hero.
      expect(s.hero, isNot(WinHero.weight));
    });
  });

  group('the month grid — the card signature', () {
    test('RULE: missed days occupy a cell, they do not vanish', () {
      // The gaps are the whole point: a grid that quietly omitted empty days
      // would be bragging, not proof, and a full grid would mean nothing.
      final s = compute(
        joined: today.subtract(const Duration(days: 4)),
        logs: [log(4, calories: 2000), log(1, calories: 2000)],
      );
      expect(s.dayLevels.length, 5); // one cell per day since joining
      expect(s.dayLevels.where((l) => l == 0).length, 3); // the misses are there
    });

    test('one cell per day since joining, oldest first, newest last', () {
      final s = compute(
        joined: today.subtract(const Duration(days: 2)),
        logs: [log(2, calories: 2000)], // the OLDEST of the three days
      );
      expect(s.dayLevels.length, 3);
      expect(s.dayLevels.first, greaterThan(0)); // oldest is the logged one
      expect(s.dayLevels.last, 0); // today, nothing yet
    });

    test('intensity rises with how much of the day they actually did', () {
      // nothing
      expect(compute(joined: today, logs: []).dayLevels.first, 0);
      // ate only -> something
      expect(compute(joined: today, logs: [log(0, calories: 2000)]).dayLevels.first, 1);
      // ate + 2 habits -> a solid day
      expect(
        computeWinSummary(
          logs: [
            DailyLog(
              id: 'x', clientId: 'c1', coachId: 'coach1', date: today,
              meals: const [], totalCalories: 2000, totalProtein: 0,
              totalCarbs: 0, totalFat: 0,
              waterLiters: 2, sleepRating: 4, weightKg: 0,
            )
          ],
          workouts: const [],
          today: today, windowDays: 30, goal: 'lose', joined: today, streak: 0,
        ).dayLevels.first,
        2,
      );
      // ate + 2 habits + trained -> the full set
      expect(
        computeWinSummary(
          logs: [
            DailyLog(
              id: 'x', clientId: 'c1', coachId: 'coach1', date: today,
              meals: const [], totalCalories: 2000, totalProtein: 0,
              totalCarbs: 0, totalFat: 0,
              waterLiters: 2, sleepRating: 4, weightKg: 0,
            )
          ],
          workouts: [workout(0)],
          today: today, windowDays: 30, goal: 'lose', joined: today, streak: 0,
        ).dayLevels.first,
        3,
      );
    });

    test('RULE: a new client gets a short grid, not a month of failure', () {
      // Joined 2 days ago. 30 mostly-empty cells would read as a disaster for
      // someone who has done nothing wrong.
      final s = compute(joined: today.subtract(const Duration(days: 1)));
      expect(s.dayLevels.length, 2);
    });

    test('the grid never runs longer than the window', () {
      final s = compute(joined: DateTime(2020, 1, 1), windowDays: 30);
      expect(s.dayLevels.length, 30);
    });
  });

  group('counting', () {
    test('counts logged days and completed sessions in the window', () {
      final s = compute(
        logs: [log(1, calories: 2000), log(2, water: 2), log(3, calories: 1800)],
        workouts: [workout(1), workout(3), workout(5, done: false)],
      );
      expect(s.daysLogged, 3);
      expect(s.workoutsDone, 2); // the skipped one does not count
    });

    test('ignores anything outside the window', () {
      final s = compute(
        logs: [log(1, calories: 2000), log(40, calories: 2000)],
        workouts: [workout(40)],
      );
      expect(s.daysLogged, 1);
      expect(s.workoutsDone, 0);
    });

    test('RULE: a new client is not judged on days before they joined', () {
      // Joined 5 days ago, logged 4 of them. That is 80%, not 13% of a month —
      // the pre-signup days were never theirs to miss.
      final s = compute(
        joined: today.subtract(const Duration(days: 4)),
        logs: [
          log(0, calories: 2000),
          log(1, calories: 2000),
          log(2, calories: 2000),
          log(3, calories: 2000),
        ],
      );
      expect(s.daysPossible, 5);
      expect(s.daysLogged, 4);
      expect(s.consistencyPct, 80);
    });

    test('consistency is 0 when nothing was possible', () {
      expect(compute().consistencyPct, 0);
    });
  });
}
