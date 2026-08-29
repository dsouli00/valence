import 'dart:io';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:valence/config/plans.dart';
import 'package:valence/config/revenuecat_config.dart';

/// Thin wrapper around RevenueCat for coach subscriptions.
///
/// Entirely inert until [RevenueCatConfig.configured] is true, so the app ships
/// unchanged until keys exist. Entitlements are re-read from RevenueCat after
/// each action (rather than trusting a method's return value), which keeps this
/// robust to SDK version changes.
class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  bool _ready = false;
  bool get isReady => _ready;

  /// True when this build is talking to the RevenueCat Test Store rather than a
  /// real store. Useful for a "test purchase" hint in dev builds; never true in
  /// a release build.
  bool _usingTestStore = false;
  bool get usingTestStore => _usingTestStore;

  /// Cached current offering, so the paywall can render real localized prices
  /// without a round trip per card.
  Offering? _offering;

  /// Which key this build talks to.
  ///
  /// The Test Store wins in debug and profile builds because it is the only way
  /// to transact before real store products exist. It is HARD-GATED on
  /// `kReleaseMode`: RevenueCat deliberately crashes a release build that boots
  /// with a Test Store key, so a release build never even reads that constant.
  ///
  /// Profile mode is deliberately included — it gives near-release animation
  /// smoothness AND a working purchase, which is exactly what you want when
  /// screen-recording the paywall.
  static String? _apiKey() {
    if (!kReleaseMode && RevenueCatConfig.testStoreApiKey.isNotEmpty) {
      return RevenueCatConfig.testStoreApiKey;
    }
    final key = Platform.isIOS
        ? RevenueCatConfig.iosApiKey
        : RevenueCatConfig.androidApiKey;
    return key.isEmpty ? null : key;
  }

  Future<void> init() async {
    if (_ready) return;
    final key = _apiKey();
    if (key == null) return;
    try {
      await Purchases.configure(PurchasesConfiguration(key));
      _ready = true;
      _usingTestStore = key == RevenueCatConfig.testStoreApiKey;
      // Warm the offering cache so the paywall paints real prices on first
      // open. Best effort — a failure here just falls back to the static price.
      await _refreshOffering();
    } catch (_) {
      _ready = false;
    }
  }

  /// Ties RevenueCat's identity to our Firebase uid so a coach's entitlement
  /// follows them across devices.
  Future<void> login(String uid) async {
    if (!_ready) return;
    try {
      await Purchases.logIn(uid);
      await _refreshOffering();
    } catch (_) {}
  }

  Future<void> logout() async {
    if (!_ready) return;
    try {
      await Purchases.logOut();
    } catch (_) {}
  }

  Future<void> _refreshOffering() async {
    try {
      _offering = (await Purchases.getOfferings()).current;
    } catch (_) {
      _offering = null;
    }
  }

  /// The store's own localized price for [tier] (e.g. "19,99 €", "$19.00"), or
  /// null when unavailable.
  ///
  /// Rendering the STORE's string rather than a hardcoded USD number matters:
  /// the store charges the buyer's local price, and a paywall that says "$19"
  /// while billing something else is both dishonest and an App Review flag.
  String? priceString(PlanTier tier) {
    final offering = _offering;
    if (offering == null) return null;
    return _packageFor(offering, tier)?.storeProduct.priceString;
  }

  /// Picks the package to buy for [tier].
  ///
  /// Exact product-id match first. The two fuzzy fallbacks exist for the Test
  /// Store, where products are named by hand in the dashboard and rarely match
  /// the constants — without them a demo build would silently find no package
  /// and the purchase would look broken on camera.
  Package? _packageFor(Offering offering, PlanTier tier) {
    final wanted = tier == PlanTier.studio
        ? RevenueCatConfig.studioProductId
        : RevenueCatConfig.proProductId;
    final packages = offering.availablePackages;

    for (final p in packages) {
      if (p.storeProduct.identifier == wanted) return p;
    }
    for (final p in packages) {
      if (p.storeProduct.identifier.toLowerCase().contains(tier.name)) return p;
    }
    for (final p in packages) {
      if (p.identifier.toLowerCase().contains(tier.name)) return p;
    }
    return null;
  }

  /// Maps RevenueCat's active entitlements to one of our stored tier ids
  /// ('studio' / 'pro'), or null when the coach has no paid entitlement.
  String? _tierFromInfo(CustomerInfo info) {
    final active = info.entitlements.active.keys;
    if (active.contains(RevenueCatConfig.studioEntitlement)) {
      return planDefFor(PlanTier.studio).id;
    }
    if (active.contains(RevenueCatConfig.proEntitlement)) {
      return planDefFor(PlanTier.pro).id;
    }
    return null;
  }

  /// The tier the coach is currently entitled to, read fresh from RevenueCat.
  Future<String?> currentTierId() async {
    if (!_ready) return null;
    try {
      return _tierFromInfo(await Purchases.getCustomerInfo());
    } catch (_) {
      return null;
    }
  }

  /// Buys the subscription for [tier]. Returns the granted tier id, or null if
  /// cancelled / unavailable.
  Future<String?> purchase(PlanTier tier) async {
    if (!_ready) return null;
    try {
      if (_offering == null) await _refreshOffering();
      final offering = _offering;
      if (offering == null) return null;
      final package = _packageFor(offering, tier);
      if (package == null) return null;
      await Purchases.purchase(PurchaseParams.package(package));
      return _tierFromInfo(await Purchases.getCustomerInfo());
    } catch (_) {
      // Cancel or failure — the caller treats null as "not purchased".
      return null;
    }
  }

  /// Restores prior purchases; returns the entitled tier id, or null.
  Future<String?> restore() async {
    if (!_ready) return null;
    try {
      await Purchases.restorePurchases();
      return _tierFromInfo(await Purchases.getCustomerInfo());
    } catch (_) {
      return null;
    }
  }
}
