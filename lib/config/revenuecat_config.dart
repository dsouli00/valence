/// RevenueCat configuration for coach subscriptions.
///
/// Fill these in once you have a RevenueCat project, paid store accounts, and
/// subscription products created in App Store Connect / Play Console. Until
/// [configured] is true the app behaves exactly as before — no native purchases,
/// and the paywall falls back to the interim "contact us" path.
///
/// Setup later:
///  1. Create the Apple/Google developer accounts + a monthly subscription
///     product per paid tier (ids below).
///  2. In RevenueCat: add the apps, attach the products to an Offering, and
///     create one Entitlement per paid tier (ids below).
///  3. Paste the public SDK API keys here. That's it — the app goes live.
class RevenueCatConfig {
  RevenueCatConfig._();

  /// Public SDK API keys (RevenueCat → Project → API keys).
  static const String androidApiKey = ''; // e.g. 'goog_xxxxx'
  static const String iosApiKey = ''; // e.g. 'appl_xxxxx'

  /// Entitlement identifiers configured in RevenueCat — one per paid tier.
  static const String proEntitlement = 'pro';
  static const String studioEntitlement = 'studio';

  /// Store product identifiers — one per paid tier (created in the stores and
  /// attached to the RevenueCat offering). Used to pick the right package to buy.
  static const String proProductId = 'valence_pro_monthly';
  static const String studioProductId = 'valence_studio_monthly';

  /// True once real API keys are present. Gates all native-purchase code so the
  /// app runs unchanged until you're ready to go live.
  static bool get configured => androidApiKey.isNotEmpty || iosApiKey.isNotEmpty;
}
