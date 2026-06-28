import 'dart:io';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:valence/config/plans.dart';
import 'package:valence/config/revenuecat_config.dart';

/// Thin wrapper around RevenueCat for coach subscriptions.
///
/// Entirely inert until [RevenueCatConfig.configured] is true, so the app ships
/// unchanged today and "comes alive" once the store accounts + products + API
/// keys are in place. Entitlements are re-read from RevenueCat after each action
/// (rather than relying on a method's return type), which keeps this robust to
/// SDK version changes.
class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  bool _ready = false;
  bool get isReady => _ready;

  Future<void> init() async {
    if (!RevenueCatConfig.configured || _ready) return;
    final key = Platform.isIOS ? RevenueCatConfig.iosApiKey : RevenueCatConfig.androidApiKey;
    if (key.isEmpty) return;
    try {
      await Purchases.configure(PurchasesConfiguration(key));
      _ready = true;
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
    } catch (_) {}
  }

  Future<void> logout() async {
    if (!_ready) return;
    try {
      await Purchases.logOut();
    } catch (_) {}
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
    final productId = tier == PlanTier.studio
        ? RevenueCatConfig.studioProductId
        : RevenueCatConfig.proProductId;
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current;
      if (offering == null) return null;
      Package? package;
      for (final p in offering.availablePackages) {
        if (p.storeProduct.identifier == productId) {
          package = p;
          break;
        }
      }
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
