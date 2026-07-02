// Unit tests for Valence's subscription-plan logic (pure Dart, no Firebase).
// Replaces the default Flutter counter template (which referenced a widget that
// doesn't exist in this app and required Firebase init, so it always failed).

import 'package:flutter_test/flutter_test.dart';
import 'package:valence/config/plans.dart';

void main() {
  group('plan tier resolution', () {
    test('maps stored ids (and unknowns) to a tier', () {
      expect(planTierFromId('free'), PlanTier.free);
      expect(planTierFromId('pro'), PlanTier.pro);
      expect(planTierFromId('studio'), PlanTier.studio);
      expect(planTierFromId('team'), PlanTier.studio);
      expect(planTierFromId(null), PlanTier.free);
      expect(planTierFromId('something-unknown'), PlanTier.free);
    });

    test('an expired paid subscription falls back to free', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      final future = DateTime.now().add(const Duration(days: 30));
      expect(effectivePlanTier(tierId: 'pro', expiry: past), PlanTier.free);
      expect(effectivePlanTier(tierId: 'pro', expiry: future), PlanTier.pro);
      expect(effectivePlanTier(tierId: 'pro', expiry: null), PlanTier.pro);
    });
  });

  group('client-limit gating', () {
    test('free tier caps at 3 clients', () {
      expect(canAddClient(PlanTier.free, 2), isTrue);
      expect(canAddClient(PlanTier.free, 3), isFalse);
    });

    test('pro tier caps at 30 clients', () {
      expect(canAddClient(PlanTier.pro, 29), isTrue);
      expect(canAddClient(PlanTier.pro, 30), isFalse);
    });

    test('studio tier is unlimited', () {
      expect(planDefFor(PlanTier.studio).isUnlimited, isTrue);
      expect(canAddClient(PlanTier.studio, 100000), isTrue);
    });
  });
}
