// Unit tests for DailyLog's parse boundary (pure Dart).
//
// These exist because of one live bug: a day document is created the moment a
// client opens the app, that create seeded `weightKg: 0`, and the weight chart
// plotted it. On a real account the Progress tab read "66.0 → 0.0 kg" — the
// client appeared to have lost 66 kilograms overnight.
//
// The zeros are already written to Firestore, so the fix has to hold at the
// point where documents become objects, not at any one reader. Every test below
// is about that boundary.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valence/models/daily_log_model.dart';

Map<String, dynamic> doc({dynamic weightKg = 'absent'}) => {
      'clientId': 'c1',
      'coachId': 'coach1',
      'date': Timestamp.fromDate(DateTime(2026, 8, 30)),
      'meals': const [],
      'totalCalories': 0,
      'waterLiters': 0,
      'sleepRating': 0,
      if (weightKg != 'absent') 'weightKg': weightKg,
    };

void main() {
  group('weight is a measurement, not a counter', () {
    test('RULE: a written zero reads back as "not recorded"', () {
      // The exact shape of every day doc created before its client weighs in.
      expect(DailyLog.fromJson(doc(weightKg: 0), 'id').weightKg, isNull);
      expect(DailyLog.fromJson(doc(weightKg: 0.0), 'id').weightKg, isNull);
    });

    test('a missing field is still null', () {
      expect(DailyLog.fromJson(doc(), 'id').weightKg, isNull);
      expect(DailyLog.fromJson(doc(weightKg: null), 'id').weightKg, isNull);
    });

    test('a real weigh-in survives untouched', () {
      expect(DailyLog.fromJson(doc(weightKg: 65.6), 'id').weightKg, 65.6);
      // Firestore hands back ints for whole numbers.
      expect(DailyLog.fromJson(doc(weightKg: 66), 'id').weightKg, 66.0);
      // Nothing rounds a small but genuine value away.
      expect(DailyLog.fromJson(doc(weightKg: 0.5), 'id').weightKg, 0.5);
    });

    test('a negative weight is treated as absent, not plotted', () {
      expect(DailyLog.fromJson(doc(weightKg: -5), 'id').weightKg, isNull);
    });

    test('zero water and zero sleep are TRUE statements and are kept', () {
      // Only weight gets this treatment: a fresh day genuinely has 0 litres and
      // 0 stars, and the UI says so. Nobody weighs 0 kg.
      final log = DailyLog.fromJson(doc(weightKg: 0), 'id');
      expect(log.waterLiters, 0);
      expect(log.sleepRating, 0);
    });
  });
}
