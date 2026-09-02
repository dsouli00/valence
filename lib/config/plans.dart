import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Subscription plan definitions for coaches.
///
/// Provider-agnostic: this only describes the tiers, their limits and prices,
/// plus the entitlement helpers the app uses to gate features. Wiring an actual
/// checkout (Paddle / LemonSqueezy / native IAP) happens later and only needs to
/// write [PlanDef.id] into the user's `subscriptionTier` field (+ an optional
/// `subscriptionExpiryDate`). Everything here works on the free Firebase plan.
///
/// Prices are in USD/month and intentionally live in ONE place — change them
/// here and the paywall, plan row and gates all follow.
enum PlanTier { free, pro, elite }

class PlanDef {
  final PlanTier tier;

  /// Stored verbatim in the user's `subscriptionTier` field.
  final String id;

  /// Max active clients allowed. `null` means unlimited.
  final int? maxClients;

  /// Monthly price in USD. `0` for the free tier.
  final int priceMonthlyUsd;

  final IconData icon;

  const PlanDef({
    required this.tier,
    required this.id,
    required this.maxClients,
    required this.priceMonthlyUsd,
    required this.icon,
  });

  bool get isUnlimited => maxClients == null;
  bool get isFree => priceMonthlyUsd == 0;
}

const Map<PlanTier, PlanDef> kPlans = {
  PlanTier.free: PlanDef(
    tier: PlanTier.free,
    id: 'free',
    maxClients: 3,
    priceMonthlyUsd: 0,
    icon: PhosphorIconsFill.leaf,
  ),
  PlanTier.pro: PlanDef(
    tier: PlanTier.pro,
    id: 'pro',
    maxClients: 30,
    priceMonthlyUsd: 19,
    icon: PhosphorIconsFill.crown,
  ),
  PlanTier.elite: PlanDef(
    tier: PlanTier.elite,
    id: 'elite',
    maxClients: null,
    priceMonthlyUsd: 39,
    icon: PhosphorIconsFill.medal,
  ),
};

/// Display order for the paywall.
const List<PlanTier> kPlanOrder = [PlanTier.free, PlanTier.pro, PlanTier.elite];

PlanDef planDefFor(PlanTier tier) => kPlans[tier]!;

/// Maps a stored `subscriptionTier` string to a [PlanTier]. Unknown/null → free.
PlanTier planTierFromId(String? id) {
  switch (id?.toLowerCase()) {
    case 'pro':
      return PlanTier.pro;
    case 'elite':
    // LEGACY ids. The top tier was called Studio (and before that Team) and
    // real `subscriptionTier` docs still hold those strings — they were never
    // migrated, so they must keep resolving or a paying coach silently drops
    // to free.
    case 'studio':
    case 'team':
      return PlanTier.elite;
    default:
      return PlanTier.free;
  }
}

/// The tier the coach is actually entitled to right now. A paid tier whose
/// `subscriptionExpiryDate` is in the past falls back to free.
PlanTier effectivePlanTier({String? tierId, DateTime? expiry}) {
  final tier = planTierFromId(tierId);
  if (tier == PlanTier.free) return PlanTier.free;
  if (expiry != null && expiry.isBefore(DateTime.now())) return PlanTier.free;
  return tier;
}

/// Whether a coach on [tier] may add one more client given [currentCount].
bool canAddClient(PlanTier tier, int currentCount) {
  final max = planDefFor(tier).maxClients;
  return max == null || currentCount < max;
}
