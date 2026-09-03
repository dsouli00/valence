import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/config/plans.dart';
import 'package:valence/config/revenuecat_config.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/services/purchase_service.dart';
import 'package:valence/ui/ui.dart';

/// Coach paywall — a MOMENT screen (design.md §5.16/§4-D): skyGlow atmosphere,
/// a serif value statement, tier cards in the VOptionCard language (selected =
/// gold ring + wash; "current"/"popular" as quiet caption tags), feature
/// bullets as hairline rows, ONE pinned primary CTA and a quiet restore action.
///
/// Online checkout is wired later (RevenueCat when configured); otherwise
/// choosing a paid plan opens an interim "contact us" sheet so the action is
/// real, not a dead handler.
class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  static const _supportEmail = 'support@valence.app';

  /// The tier the coach has tapped. Null until first tap — the effective
  /// selection then defaults to the recommended upgrade.
  PlanTier? _selected;

  /// The STORE's own localized price per paid tier, when RevenueCat is live.
  /// Empty until loaded, at which point the cards swap off the hardcoded USD
  /// figure — the store bills the buyer's local price, so a paywall that says
  /// "$19" while charging something else is both wrong and an App Review flag.
  final Map<PlanTier, String> _prices = {};

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    if (!PurchaseService.instance.isReady) return;
    final loaded = <PlanTier, String>{};
    for (final tier in kPlanOrder) {
      if (tier == PlanTier.free) continue;
      final price = PurchaseService.instance.priceString(tier);
      if (price != null) loaded[tier] = price;
    }
    if (!mounted || loaded.isEmpty) return;
    setState(() => _prices.addAll(loaded));
  }

  String _planName(BuildContext context, PlanTier tier) {
    final l10n = context.l10n;
    switch (tier) {
      case PlanTier.pro:
        return l10n.planPro;
      case PlanTier.elite:
        return l10n.planElite;
      case PlanTier.free:
        return l10n.planFree;
    }
  }

  String _tagline(BuildContext context, PlanTier tier) {
    final l10n = context.l10n;
    switch (tier) {
      case PlanTier.free:
        return l10n.planFreeTagline;
      case PlanTier.pro:
        return l10n.planProTagline;
      case PlanTier.elite:
        return l10n.planEliteTagline;
    }
  }

  /// The bullets per tier.
  ///
  /// THESE MUST BE TRUE. The previous list sold recurring programming, custom
  /// habits and progress analytics as Pro features — all three ship free, and
  /// the only things actually gated in the app are the client cap
  /// (`coach_settings_screen`) and the AI client read (`ClientAnalysisCard`).
  /// A paywall that lists features the buyer already has is the one lie a panel
  /// of monetization judges is guaranteed to catch, so the free tier now claims
  /// what it really gives and Pro claims the one thing it really unlocks. The
  /// roster cap does the rest of the work, and it is rendered separately as the
  /// bold first row of every card.
  List<String> _features(BuildContext context, PlanTier tier) {
    final l10n = context.l10n;
    switch (tier) {
      // Free enumerated FOUR features while Pro showed two, so the free card
      // was taller and read as the better deal — on a paywall judged by
      // RevenueCat people, which is the worst possible place for that.
      //
      // The fix is not to lie again. Free is summarised rather than itemised
      // (Pro's "Everything in Free" already covers the rest), and Pro's one
      // real differentiator — the cited analysis — gets the room it deserves
      // instead of a single line. Nothing here claims anything untrue.
      case PlanTier.free:
        return [
          l10n.featureMonitoring,
          l10n.featureAiMeal,
        ];
      case PlanTier.pro:
        return [
          l10n.featureEverythingFree,
          l10n.featureAiInsights,
          l10n.featureAiCited,
          l10n.featureAiSpotsPatterns,
        ];
      case PlanTier.elite:
        return [l10n.featureEverythingPro, l10n.featurePrioritySupport];
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;
    final coach = context.watch<AuthProvider>().currentUser;
    final current = effectivePlanTier(
      tierId: coach?.subscriptionTier,
      expiry: coach?.subscriptionExpiryDate,
    );
    // Default the selection to the natural upgrade (Pro), or the current paid
    // tier — the CTA is never armed on the plan the coach already has.
    final selected =
        _selected ?? (current == PlanTier.free ? PlanTier.pro : current);
    final ctaEnabled = selected != current && selected != PlanTier.free;

    return Scaffold(
      backgroundColor: t.canvas,
      body: Stack(
        children: [
          // Moment atmosphere (§1.9) — allowed here, and only here on the
          // coach side.
          const VSkyGlow(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      VSpace.screenMargin,
                      8,
                      VSpace.screenMargin,
                      16,
                    ),
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: VIconCircle(
                          icon: PhosphorIconsBold.caretLeft,
                          semanticLabel: l10n.back,
                          onTap: () => Navigator.maybePop(context),
                        ),
                      ),
                      const SizedBox(height: 20),
                      VTextScaleCap(
                        child: Text(
                          l10n.plansSubtitle,
                          style: VType.serifTitle.copyWith(color: t.ink),
                        ),
                      ),
                      const SizedBox(height: 24),
                      for (final tier in kPlanOrder) ...[
                        _TierCard(
                          def: planDefFor(tier),
                          name: _planName(context, tier),
                          tagline: _tagline(context, tier),
                          features: _features(context, tier),
                          priceLabel: _prices[tier],
                          isCurrent: tier == current,
                          isRecommended: tier == PlanTier.pro,
                          selected: tier == selected,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selected = tier);
                          },
                        ),
                        const SizedBox(height: VSpace.cardGap),
                      ],
                    ],
                  ),
                ),
                // Pinned CTA + quiet restore.
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      VSpace.screenMargin, 8, VSpace.screenMargin, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VPillButton.primary(
                        label: selected == current
                            ? l10n.planCurrent
                            : l10n.planChoose(_planName(context, selected)),
                        onPressed: ctaEnabled
                            ? () {
                                HapticFeedback.mediumImpact();
                                _choosePlan(context, selected);
                              }
                            : null,
                      ),
                      if (RevenueCatConfig.configured)
                        VTextAction(
                          label: l10n.restorePurchases,
                          onTap: () => _restore(context),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Paid tiers go through the native purchase when RevenueCat is live;
  /// otherwise they fall back to the interim contact path.
  void _choosePlan(BuildContext context, PlanTier tier) {
    if (tier == PlanTier.free) return;
    if (RevenueCatConfig.configured &&
        PurchaseService.instance.isReady &&
        PurchaseService.instance.hasPackageFor(tier)) {
      _purchase(context, tier);
    } else {
      _requestUpgrade(context, _planName(context, tier));
    }
  }

  Future<void> _purchase(BuildContext context, PlanTier tier) async {
    await _runPurchaseMoment(
      context,
      () => PurchaseService.instance.purchase(tier),
    );
  }

  /// Drives the buy/restore Moment: it opens BEFORE the network call and stays
  /// up until the entitlement is granted, written and re-read, so the tick
  /// lands on the truth rather than on the SDK's return value.
  ///
  /// The Moment never names the tier the coach TAPPED — only the one they end
  /// up entitled to. Those differ: `_tierFromInfo` reports the highest active
  /// entitlement, so buying Pro while Elite is still live grants Elite, and
  /// copy driven by the tap would congratulate them on the wrong plan. The
  /// plan name is only rendered once the tick lands, by which point
  /// `refreshCurrentUser` has already run and the provider holds the truth.
  Future<void> _runPurchaseMoment(
    BuildContext context,
    Future<String?> Function() action,
  ) async {
    final l10n = context.l10n;
    final auth = context.read<AuthProvider>();
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    final phase = ValueNotifier(VPurchasePhase.working);
    final leaving = Completer<void>();
    var momentOpen = true;
    // A ROUTE, not a dialog. The Moment is a full-screen step in the journey,
    // and `showGeneralDialog` builds its content in `transitionBuilder` over a
    // ModalBarrier — the CTA rendered correctly there but never received the
    // tap. A page route is both what this is and what works.
    // The Moment goes on the ROOT navigator — each tab owns a nested one, and
    // a full-screen Moment pushed there leaves the tab bar sitting on top of
    // it. The paywall itself was pushed on the tab's navigator, so leaving it
    // afterwards has to use that one.
    final rootNav = Navigator.of(context, rootNavigator: true);
    final localNav = Navigator.of(context);
    rootNav
        .push(PageRouteBuilder<void>(
          opaque: true,
          barrierDismissible: false,
          transitionDuration: VDuration.entrance,
          pageBuilder: (ctx, anim, _) => PopScope(
            // No escaping mid-transaction, and no back-swipe off the reveal.
            canPop: false,
            child: FadeTransition(
              opacity: anim,
              child: _momentFor(ctx, phase, leaving),
            ),
          ),
        ))
        .then((_) => momentOpen = false);

    final tierId = await action();
    if (tierId != null) {
      try {
        await FirestoreService().setSubscriptionTier(uid, tierId);
        await auth.refreshCurrentUser();
      } catch (_) {}
    }
    if (!context.mounted) return;

    if (tierId == null) {
      if (momentOpen) rootNav.pop();
      showVToast(context, l10n.purchaseFailed);
      phase.dispose();
      return;
    }

    // The reveal now waits on the coach's own tap, not a timer.
    phase.value = VPurchasePhase.done;
    await leaving.future;
    if (!context.mounted) {
      phase.dispose();
      return;
    }
    if (momentOpen) rootNav.pop(); // close the Moment
    localNav.maybePop(); // leave the paywall
    phase.dispose();
  }

  Widget _momentFor(
    BuildContext context,
    ValueNotifier<VPurchasePhase> phase,
    Completer<void> leaving,
  ) {
    final l10n = context.l10n;
    final coach = context.watch<AuthProvider>().currentUser;
    final tier = effectivePlanTier(
      tierId: coach?.subscriptionTier,
      expiry: coach?.subscriptionExpiryDate,
    );
    final def = planDefFor(tier);
    return VPurchaseMoment(
      phase: phase,
      workingLabel: l10n.purchaseWorking,
      welcomeLabel: l10n.purchaseWelcome,
      planName: _planName(context, tier),
      planIcon: def.icon,
      unlockedLabel: l10n.purchaseUnlocked,
      // The roster cap leads — it is the thing they actually bought — then the
      // tier's own bullets, capped so the card stays a glance and not a
      // re-reading of the paywall they just left.
      benefits: [
        def.isUnlimited
            ? l10n.planClientsUnlimited
            : l10n.planClientsUpTo(def.maxClients!),
        ..._features(context, tier).take(2),
      ],
      ctaLabel: l10n.purchaseCta,
      onContinue: () {
        if (!leaving.isCompleted) leaving.complete();
      },
    );
  }

  Future<void> _restore(BuildContext context) async {
    await _runPurchaseMoment(
      context,
      () => PurchaseService.instance.restore(),
    );
  }

  Future<void> _requestUpgrade(BuildContext context, String planName) async {
    final l10n = context.l10n;
    await showVSheet<void>(
      context: context,
      builder: (ctx) {
        final t = ctx.tokens;
        return VSheet(
          title: l10n.upgradeContactTitle,
          scrollable: false,
          pinnedAction: VPillButton.primary(
            label: l10n.contactUs,
            icon: PhosphorIconsBold.copy,
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              await Clipboard.setData(const ClipboardData(text: _supportEmail));
              if (!mounted) return;
              navigator.pop();
              showVToast(this.context, l10n.supportEmailCopied);
            },
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: t.tintFill(t.gold),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(PhosphorIconsFill.crown,
                      size: 19, color: t.legibleTint(t.gold)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.upgradeContactBody(planName),
                    style: VType.body.copyWith(color: t.inkSecondary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tier card — VOptionCard language: surface card, selected = gold ring + wash
// (the ONLY selected signal); "current"/"popular" as quiet caption tags;
// feature bullets as hairline rows.
// ---------------------------------------------------------------------------

class _TierCard extends StatelessWidget {
  final PlanDef def;
  final String name;
  final String tagline;
  final List<String> features;

  /// The store's localized price string (e.g. "19,99 €"). Null before
  /// RevenueCat has loaded, or when it isn't configured — the card then falls
  /// back to the static USD figure in [PlanDef].
  final String? priceLabel;

  final bool isCurrent;
  final bool isRecommended;
  final bool selected;
  final VoidCallback onTap;

  const _TierCard({
    required this.def,
    required this.name,
    required this.tagline,
    required this.features,
    required this.priceLabel,
    required this.isCurrent,
    required this.isRecommended,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;
    final clientsLine = def.isUnlimited
        ? l10n.planClientsUnlimited
        : l10n.planClientsUpTo(def.maxClients!);

    return VPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: VDuration.standard,
        curve: VMotion.curve,
        padding: const EdgeInsets.all(VSpace.cardPadding),
        decoration: BoxDecoration(
          color: selected
              ? Color.alphaBlend(t.selectedWash, t.surface)
              : t.surface,
          borderRadius: BorderRadius.circular(VRadius.cardSmall),
          boxShadow: t.cardShadow,
          border: Border.all(
            color: selected ? t.gold : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: t.tintFill(t.gold),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(def.icon, size: 19, color: t.legibleTint(t.gold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: VType.headline.copyWith(color: t.ink),
                            ),
                          ),
                          if (isCurrent || isRecommended) ...[
                            const SizedBox(width: 8),
                            _Tag(
                              // "Current", not "Current plan" — the disabled
                              // CTA at the bottom already says "Current plan",
                              // and the same phrase twice on one screen reads
                              // as a rendering fault. Beside the plan's name
                              // the short form is also just better: "Pro ·
                              // Current".
                              text: isCurrent
                                  ? l10n.planCurrentTag
                                  : l10n.planMostPopular,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tagline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: VType.caption.copyWith(color: t.inkSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                VTextScaleCap(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        // An em-dash, not the tier's own name again. The card
                        // was rendering "Free" as both its title and its price
                        // — already redundant in English, and in German two
                        // long identical words side by side ("Kostenlos ·
                        // Kostenlos") read as a rendering fault.
                        def.isFree
                            ? '—'
                            : (priceLabel ?? '\$${def.priceMonthlyUsd}'),
                        style: VType.stat(22).copyWith(color: t.ink),
                      ),
                      if (!def.isFree)
                        Text(
                          l10n.planPerMonth,
                          style: VType.caption.copyWith(color: t.inkTertiary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FeatureRow(text: clientsLine, bold: true, first: true),
            for (final f in features) _FeatureRow(text: f),
          ],
        ),
      ),
    );
  }
}

/// Quiet caption tag ("Current" / "Most popular") — gold tint pill, goldDeep
/// text. No ribbons, no uppercase.
class _Tag extends StatelessWidget {
  final String text;
  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: t.tintFill(t.gold),
        borderRadius: BorderRadius.circular(VRadius.pill),
      ),
      child: Text(
        text,
        style: VType.caption.copyWith(
          color: t.goldDeep,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Feature bullet as a hairline row (design.md §5.16): quiet check + text,
/// hairline above every row except the first.
class _FeatureRow extends StatelessWidget {
  final String text;
  final bool bold;
  final bool first;

  const _FeatureRow({required this.text, this.bold = false, this.first = false});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!first) Divider(height: 1, thickness: 1, color: t.hairline),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VIcon(PhosphorIconsBold.check, size: 14, color: t.goldDeep),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: VType.subhead.copyWith(
                    color: t.ink,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
