// Unit tests for what a macro target means (pure Dart).
//
// One rule used to serve all four macros — `current > target` painted the
// number and the whole bar red. A client who ate 142g of protein against a
// 130g target had done exactly what her coach asked, and every figure on her
// dashboard told her she had failed.
//
// These tests exist so nobody re-flattens the four macros back into one rule.

import 'package:flutter_test/flutter_test.dart';
import 'package:valence/utils/macro_status.dart';

MacroTone tone(MacroTargetKind kind, num current, num target) =>
    macroTone(kind: kind, current: current, target: target);

void main() {
  group('protein is a floor — reaching it is the win', () {
    test('RULE: over target is GOOD, never alert', () {
      // The exact case from the sweep.
      expect(tone(MacroTargetKind.floor, 142, 130), MacroTone.good);
      expect(tone(MacroTargetKind.floor, 400, 130), MacroTone.good);
    });

    test('hitting it exactly counts', () {
      expect(tone(MacroTargetKind.floor, 130, 130), MacroTone.good);
    });

    test('short of it is neutral, not a scolding', () {
      expect(tone(MacroTargetKind.floor, 129, 130), MacroTone.neutral);
      expect(tone(MacroTargetKind.floor, 0, 130), MacroTone.neutral);
    });
  });

  group('carbs and fat are soft ceilings — food does not land on a number', () {
    test('under target is neutral', () {
      expect(tone(MacroTargetKind.softCeiling, 150, 190), MacroTone.neutral);
      expect(tone(MacroTargetKind.softCeiling, 190, 190), MacroTone.neutral);
    });

    test('RULE: a modest overshoot stays neutral', () {
      // 190 + 10% = 209.
      expect(tone(MacroTargetKind.softCeiling, 195, 190), MacroTone.neutral);
      expect(tone(MacroTargetKind.softCeiling, 209, 190), MacroTone.neutral);
    });

    test('RULE: past the band it DRIFTS before it fails', () {
      // 190 +10% = 209, +25% = 237.5. Between the two is `watch` — the step
      // that used to be missing, so carbs jumped from fine to red in one gram.
      expect(tone(MacroTargetKind.softCeiling, 210, 190), MacroTone.watch);
      expect(tone(MacroTargetKind.softCeiling, 237, 190), MacroTone.watch);
      expect(tone(MacroTargetKind.softCeiling, 238, 190), MacroTone.alert);
      expect(tone(MacroTargetKind.softCeiling, 300, 190), MacroTone.alert);
    });

    test('both band edges are exactly the documented constants', () {
      const target = 100;
      final warn = target * (1 + kMacroCeilingTolerance);
      final fail = target * (1 + kMacroCeilingAlert);
      expect(tone(MacroTargetKind.softCeiling, warn, target), MacroTone.neutral);
      expect(tone(MacroTargetKind.softCeiling, warn + 0.01, target),
          MacroTone.watch);
      expect(tone(MacroTargetKind.softCeiling, fail, target), MacroTone.watch);
      expect(tone(MacroTargetKind.softCeiling, fail + 0.01, target),
          MacroTone.alert);
    });


  });

  group('calories is the hard ceiling — deliberately unchanged', () {
    test('RULE: one over the target is already an alert', () {
      expect(tone(MacroTargetKind.hardCeiling, 1851, 1850), MacroTone.alert);
    });

    test('on or under is neutral', () {
      expect(tone(MacroTargetKind.hardCeiling, 1850, 1850), MacroTone.neutral);
      expect(tone(MacroTargetKind.hardCeiling, 900, 1850), MacroTone.neutral);
    });
  });

  group('no target set is not a judgement', () {
    test('RULE: a client still in setup is never told they failed', () {
      // targetMacros is null until the coach configures the plan, and
      // TargetMacros() defaults can leave a macro at zero.
      for (final kind in MacroTargetKind.values) {
        expect(tone(kind, 200, 0), MacroTone.neutral, reason: '$kind');
        expect(tone(kind, 0, 0), MacroTone.neutral, reason: '$kind');
      }
    });
  });
}
