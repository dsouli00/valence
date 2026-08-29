/// RevenueCat configuration for coach subscriptions.
///
/// There are TWO ways this app can talk to RevenueCat, and which one it uses is
/// decided by the build type (see `PurchaseService._apiKey`):
///
///  • **Test Store** — a RevenueCat-hosted store that needs NO App Store
///    Connect, NO Play Console and NO paid developer account. Products and
///    entitlements are created in the RevenueCat dashboard and purchases behave
///    like real ones: they update `CustomerInfo`, grant entitlements and show up
///    in the dashboard. This is how the paywall transacts before real store
///    products exist. **Debug and profile builds only** — RevenueCat
///    deliberately crashes a release build that boots with a Test Store key, so
///    it is gated on `kReleaseMode` and can never ship.
///
///  • **Platform stores** — the real Apple/Google keys, used by release builds
///    once store accounts and products exist.
///
/// Until at least one key below is filled in, [configured] is false and the app
/// behaves exactly as it always has: no native purchases, and the paywall falls
/// back to the interim "contact us" path.
///
/// SETUP FOR THE TEST STORE (no money, ~10 minutes):
///  1. Create a RevenueCat project.
///  2. Dashboard → the project's Test Store → create two products. Name them
///     anything; [proProductId] / [studioProductId] are tried first but the
///     matcher falls back to a fuzzy match on "pro" / "studio", so a demo build
///     still transacts if your names differ.
///  3. Create one Entitlement per paid tier, with the ids below.
///  4. Attach the products to the project's current Offering.
///  5. Paste the Test Store API key into [testStoreApiKey]. Done.
///
/// SETUP FOR REAL STORES (later, needs paid accounts): create the same products
/// in App Store Connect / Play Console, attach them to the Offering, and paste
/// the platform SDK keys into [androidApiKey] / [iosApiKey].
class RevenueCatConfig {
  RevenueCatConfig._();

  /// RevenueCat Test Store API key (RevenueCat → Project → API keys → Test
  /// Store). Debug + profile builds only; never used by a release build.
  static const String testStoreApiKey = ''; // e.g. 'test_xxxxx'

  /// Public platform SDK API keys (RevenueCat → Project → API keys).
  static const String androidApiKey = ''; // e.g. 'goog_xxxxx'
  static const String iosApiKey = ''; // e.g. 'appl_xxxxx'

  /// Entitlement identifiers configured in RevenueCat — one per paid tier.
  /// These must match exactly; they are what `CustomerInfo` reports back.
  static const String proEntitlement = 'pro';
  static const String studioEntitlement = 'studio';

  /// Preferred store product identifiers, tried first when picking which
  /// package to buy. A fuzzy fallback covers Test Store products named
  /// differently in the dashboard.
  static const String proProductId = 'valence_pro_monthly';
  static const String studioProductId = 'valence_studio_monthly';

  /// True once ANY key is present. Gates all native-purchase code so the app
  /// runs unchanged until you're ready.
  static bool get configured =>
      testStoreApiKey.isNotEmpty ||
      androidApiKey.isNotEmpty ||
      iosApiKey.isNotEmpty;
}
