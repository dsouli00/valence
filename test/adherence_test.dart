// Unit tests for THE adherence model (pure Dart, no Firebase) — the scoring
// that decides what a coach sees about a client on the roster.
//
// These exist because a regression here does not crash: it silently tells a
// coach the wrong thing about a human being, which is the one bug that would
// actually destroy trust in the product. Each test names the RULE it protects
// (design intent), not just the arithmetic — if you are here because a test
// went red, decide whether you meant to change the rule before touching them.

import 'package:flutter_test/flutter_test.dart';
import 'package:valence/services/adherence.dart';

/// A fixed "today" so tests never depend on the wall clock.
final today = DateTime(2026, 7, 15);

/// Key for the day [i] days before [today] (i=1 is yesterday).
String dayBack(int i) => dateKeyFor(today.subtract(Duration(days: i)));

/// A day where everything was logged: nutrition + all three habit pillars.
Map<String, dynamic> fullDay() => {
      'meals': [
        {'id': '1'}
      ],
      'totalCalories': 2000,
      'waterLiters': 2.5,
      'sleepRating': 4,
      'weightKg': 78.0,
    };

Map<String, dynamic> nutritionOnly() => {
      'meals': [
        {'id': '1'}
      ],
      'totalCalories': 2000,
    };

Map<String, dynamic> workout({required bool done}) => {'isCompleted': done};

/// Builds `{dayKey: value}` for the given days-back indices.
Map<String, Map<String, dynamic>> onDays(
  List<int> daysBack,
  Map<String, dynamic> Function() make,
) =>
    {for (final i in daysBack) dayBack(i): make()};

AdherenceResult score({
  Map<String, Map<String, dynamic>> logs = const {},
  Map<String, Map<String, dynamic>> workouts = const {},
  DateTime? createdAt,
  int windowDays = kAdherenceWindowDays,
}) =>
    computeAdherence(
      normalizedToday: today,
      createdAt: createdAt,
      logsByDay: logs,
      workoutsByDay: workouts,
      windowDays: windowDays,
    );

void main() {
  group('the window', () {
    test('RULE: today is in-progress and is never counted against the client', () {
      // Only today has data; the 7 completed days are all silent. Today must be
      // ignored entirely, so this must score exactly like a fully silent week
      // rather than being rescued by today's logging.
      final onlyToday = {dateKeyFor(today): fullDay()};
      expect(score(logs: onlyToday).status, 'at_risk');
      expect(score(logs: onlyToday).summary,
          'Last 7d: nutrition 0/7 • habits 0/7 • workouts 0/0');
    });

    test('RULE: the window is exactly the 7 completed days behind today', () {
      // A day 8 back is outside the window and must not count toward the
      // denominators (which stay at 7).
      final result = score(logs: onDays([8], fullDay));
      expect(result.summary, 'Last 7d: nutrition 0/7 • habits 0/7 • workouts 0/0');
    });

    test('a perfectly logged week is on track', () {
      final result = score(logs: onDays([1, 2, 3, 4, 5, 6, 7], fullDay));
      expect(result.status, 'on_track');
      expect(result.summary, 'Last 7d: nutrition 7/7 • habits 7/7 • workouts 0/0');
    });
  });

  group('signup boundary', () {
    test('RULE: a brand-new client is on track, never at risk', () {
      // Signed up today: every day in the window predates them, so nothing is
      // expected. The naive read (7 silent days) would call this at_risk and
      // greet a new client with a red pill on their coach's roster.
      final result = score(logs: const {}, createdAt: today);
      expect(result.status, 'on_track');
      expect(result.summary, 'Last 7d: nutrition 0/0 • habits 0/0 • workouts 0/0');
    });

    test('RULE: pre-signup days are excluded from the denominators', () {
      // Signed up 3 days ago → only days 1..3 can be expected of them.
      final createdAt = today.subtract(const Duration(days: 3));
      final result = score(logs: onDays([1, 2, 3], fullDay), createdAt: createdAt);
      expect(result.status, 'on_track');
      expect(result.summary, 'Last 7d: nutrition 3/3 • habits 3/3 • workouts 0/0');
    });

    test('signup day itself counts (boundary is inclusive)', () {
      final createdAt = today.subtract(const Duration(days: 2));
      // Day 2 IS the signup day and was logged; day 1 was not.
      final result = score(logs: onDays([2], fullDay), createdAt: createdAt);
      expect(result.summary, 'Last 7d: nutrition 1/2 • habits 1/2 • workouts 0/0');
    });
  });

  group('recency signal (silence)', () {
    test('RULE: 3+ consecutive silent days = at risk', () {
      // Days 1-3 silent, 4-7 perfect.
      final result = score(logs: onDays([4, 5, 6, 7], fullDay));
      expect(result.status, 'at_risk');
    });

    test('RULE: exactly 2 silent days = slipping, not yet at risk', () {
      final result = score(logs: onDays([3, 4, 5, 6, 7], fullDay));
      expect(result.status, 'slipping');
    });

    test('RULE: one silent day does not move the needle', () {
      final result = score(logs: onDays([2, 3, 4, 5, 6, 7], fullDay));
      expect(result.status, 'on_track');
    });

    test('RULE: any single sign of life breaks a silence streak', () {
      // Days 1-3 would be a 3-day gap (at_risk on recency), but day 2 has a
      // lone glass of water. The gap becomes 1, so recency no longer fires and
      // the remaining verdict comes from consistency alone.
      final logs = {
        ...onDays([4, 5, 6, 7], fullDay),
        dayBack(2): {'waterLiters': 0.5},
      };
      expect(score(logs: logs).status, 'slipping');
    });
  });

  group('worst-of-two-signals', () {
    test('RULE: bad recency outranks tolerable consistency', () {
      // 3 silent days → recency says at_risk (rank 2). Consistency alone would
      // be 4/7 = 0.57 → slipping (rank 1). The worst signal must win.
      final result = score(logs: onDays([4, 5, 6, 7], fullDay));
      expect(result.status, 'at_risk');
    });

    test('RULE: bad consistency outranks perfect recency', () {
      // Logged yesterday (gap 0 → recency is clean), but only 1 of 7 days →
      // 0.14 consistency. Recent contact must not mask a bad week.
      final result = score(logs: onDays([1], fullDay));
      expect(result.status, 'at_risk');
    });
  });

  group('consistency thresholds', () {
    // Uses a 5-day window (4 completed days) so exact ratios are expressible.
    test('RULE: 0.75 adherence is still on track (boundary is inclusive)', () {
      // 3 of 4 days logged = 0.75. Silent day placed furthest back so the
      // recency signal stays clean and consistency is what is under test.
      final result = score(logs: onDays([1, 2, 3], fullDay), windowDays: 5);
      expect(result.status, 'on_track');
      expect(result.summary, 'Last 7d: nutrition 3/4 • habits 3/4 • workouts 0/0');
    });

    test('RULE: 0.5 adherence is slipping, below 0.5 is at risk', () {
      // 2 of 4 = 0.50 exactly → slipping (the cliff is strictly below 0.5).
      expect(score(logs: onDays([1, 2], fullDay), windowDays: 5).status, 'slipping');
      // 1 of 4 = 0.25 → at risk.
      expect(score(logs: onDays([1], fullDay), windowDays: 5).status, 'at_risk');
    });

    // The two tests below pin the threshold VALUES (0.75 and 0.5), not just
    // which side of them is which. They deliberately land BETWEEN plausible
    // alternatives, and the silent days are non-consecutive so the recency
    // signal stays clean and consistency is the only thing being measured.
    // Without these, moving 0.75 to 0.70 (or 0.5 to 0.4) passes every test.
    test('RULE: the slipping cliff is 0.75 — 5 of 7 days (0.71) is slipping', () {
      // Logged on 1,2,3,5,7; silent on 4 and 6 → 5/7 = 0.71, gap 0.
      final result = score(logs: onDays([1, 2, 3, 5, 7], fullDay));
      expect(result.status, 'slipping');
      expect(result.summary, 'Last 7d: nutrition 5/7 • habits 5/7 • workouts 0/0');
    });

    test('RULE: the at-risk cliff is 0.5 — 3 of 7 days (0.43) is at risk', () {
      // Logged on 1,4,7 → 3/7 = 0.43, gap 0 (yesterday was logged).
      final result = score(logs: onDays([1, 4, 7], fullDay));
      expect(result.status, 'at_risk');
      expect(result.summary, 'Last 7d: nutrition 3/7 • habits 3/7 • workouts 0/0');
    });
  });

  group('pillars', () {
    test('RULE: habits need 2 of 3 pillars — one alone is not enough', () {
      final waterOnly = {
        for (final i in [1, 2, 3, 4, 5, 6, 7]) dayBack(i): {'waterLiters': 2.0}
      };
      expect(score(logs: waterOnly).summary,
          'Last 7d: nutrition 0/7 • habits 0/7 • workouts 0/0');

      final waterAndSleep = {
        for (final i in [1, 2, 3, 4, 5, 6, 7])
          dayBack(i): {'waterLiters': 2.0, 'sleepRating': 4}
      };
      expect(score(logs: waterAndSleep).summary,
          'Last 7d: nutrition 0/7 • habits 7/7 • workouts 0/0');
    });

    test('nutrition counts from calories even with no meals array', () {
      final calsOnly = {
        for (final i in [1, 2, 3, 4, 5, 6, 7]) dayBack(i): {'totalCalories': 1800}
      };
      expect(score(logs: calsOnly).summary,
          'Last 7d: nutrition 7/7 • habits 0/7 • workouts 0/0');
    });

    test('RULE: training is only expected on days a workout was assigned', () {
      // Perfect nutrition + habits, no workouts assigned → nothing owed on
      // training, so the client is on track and the workout tally is 0/0.
      final result = score(logs: onDays([1, 2, 3, 4, 5, 6, 7], fullDay));
      expect(result.status, 'on_track');
      expect(result.summary, 'Last 7d: nutrition 7/7 • habits 7/7 • workouts 0/0');
    });

    test('RULE: an assigned-but-skipped workout drags the day down', () {
      // Same perfect nutrition + habits, but now a workout was assigned every
      // day and never done: each day scores 2/3 = 0.67 → slipping.
      final result = score(
        logs: onDays([1, 2, 3, 4, 5, 6, 7], fullDay),
        workouts: onDays([1, 2, 3, 4, 5, 6, 7], () => workout(done: false)),
      );
      expect(result.status, 'slipping');
      expect(result.summary, 'Last 7d: nutrition 7/7 • habits 7/7 • workouts 0/7');
    });

    test('assigned workouts that are completed keep the client on track', () {
      final result = score(
        logs: onDays([1, 2, 3, 4, 5, 6, 7], fullDay),
        workouts: onDays([1, 2, 3, 4, 5, 6, 7], () => workout(done: true)),
      );
      expect(result.status, 'on_track');
      expect(result.summary, 'Last 7d: nutrition 7/7 • habits 7/7 • workouts 7/7');
    });

    test('a completed workout alone counts as activity for recency', () {
      // No logs at all, but workouts completed on days 1-3: recency is clean,
      // so this must not read as silence even though nothing was logged.
      final result = score(
        workouts: onDays([1, 2, 3], () => workout(done: true)),
      );
      expect(result.summary, 'Last 7d: nutrition 0/7 • habits 0/7 • workouts 3/3');
    });
  });

  group('day keys', () {
    test('dateKeyFor zero-pads and ignores the time component', () {
      expect(dateKeyFor(DateTime(2026, 7, 5, 23, 59)), '2026-07-05');
      expect(dateKeyFor(DateTime(2026, 12, 31)), '2026-12-31');
    });
  });
}
