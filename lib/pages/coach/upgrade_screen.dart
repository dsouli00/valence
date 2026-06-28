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
import 'package:valence/theme/app_theme.dart';

/// Coach paywall. Lists the tiers and lets the coach pick one. Online checkout
/// is wired later (Paddle / LemonSqueezy); for now choosing a paid plan opens an
/// interim "contact us" path so the action is real, not a dead handler.
class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  static const _supportEmail = 'support@valence.app';

  String _planName(BuildContext context, PlanTier tier) {
    final l10n = context.l10n;
    switch (tier) {
      case PlanTier.pro:
        return l10n.planPro;
      case PlanTier.studio:
        return l10n.planStudio;
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
      case PlanTier.studio:
        return l10n.planStudioTagline;
    }
  }

  List<String> _features(BuildContext context, PlanTier tier) {
    final l10n = context.l10n;
    switch (tier) {
      case PlanTier.free:
        return [l10n.featureMonitoring, l10n.featureWorkoutLibrary, l10n.featureAiMeal];
      case PlanTier.pro:
        return [
          l10n.featureEverythingFree,
          l10n.featureRecurring,
          l10n.featureCustomHabits,
          l10n.featureAnalytics,
        ];
      case PlanTier.studio:
        return [l10n.featureEverythingPro, l10n.featurePrioritySupport];
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final coach = context.watch<AuthProvider>().currentUser;
    final current = effectivePlanTier(
      tierId: coach?.subscriptionTier,
      expiry: coach?.subscriptionExpiryDate,
    );

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsBold.arrowLeft, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          l10n.plansTitle,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.p16,
          AppSpacing.p8,
          AppSpacing.p16,
          AppSpacing.p32,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              l10n.plansSubtitle,
              style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          for (final tier in kPlanOrder) ...[
            _PlanCard(
              def: planDefFor(tier),
              name: _planName(context, tier),
              tagline: _tagline(context, tier),
              features: _features(context, tier),
              isCurrent: tier == current,
              isRecommended: tier == PlanTier.pro,
              onChoose: () => _choosePlan(context, tier),
            ),
            SizedBox(height: AppSpacing.p16),
          ],
          if (RevenueCatConfig.configured) ...[
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () => _restore(context),
                style: TextButton.styleFrom(foregroundColor: cs.onSurfaceVariant),
                child: Text(l10n.restorePurchases),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Free tier needs no action. Paid tiers go through the native purchase when
  /// RevenueCat is live; otherwise they fall back to the interim contact path.
  void _choosePlan(BuildContext context, PlanTier tier) {
    if (tier == PlanTier.free) return;
    if (RevenueCatConfig.configured && PurchaseService.instance.isReady) {
      _purchase(context, tier);
    } else {
      _requestUpgrade(context, _planName(context, tier));
    }
  }

  Future<void> _purchase(BuildContext context, PlanTier tier) async {
    HapticFeedback.lightImpact();
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider>();
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final tierId = await PurchaseService.instance.purchase(tier);
    if (tierId != null) {
      try {
        await FirestoreService().setSubscriptionTier(uid, tierId);
        await auth.refreshCurrentUser();
      } catch (_) {}
    }

    if (!context.mounted) return;
    Navigator.of(context).pop(); // close the loading spinner
    if (tierId != null) {
      Navigator.of(context).maybePop(); // leave the paywall
      messenger.showSnackBar(SnackBar(content: Text(l10n.purchaseSuccess)));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l10n.purchaseFailed)));
    }
  }

  Future<void> _restore(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider>();
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final tierId = await PurchaseService.instance.restore();
    if (tierId != null) {
      try {
        await FirestoreService().setSubscriptionTier(uid, tierId);
        await auth.refreshCurrentUser();
      } catch (_) {}
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text(tierId != null ? l10n.purchaseSuccess : l10n.purchaseFailed)),
    );
  }

  Future<void> _requestUpgrade(BuildContext context, String planName) async {
    HapticFeedback.lightImpact();
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final tt = Theme.of(ctx).textTheme;
        return Dialog(
          backgroundColor: cs.surface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.secondaryColor.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(PhosphorIconsFill.crown, color: AppColors.secondaryColor, size: 20),
                    ),
                    SizedBox(width: AppSpacing.p12),
                    Expanded(
                      child: Text(
                        l10n.upgradeContactTitle,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.p12),
                Text(
                  l10n.upgradeContactBody(planName),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                ),
                SizedBox(height: AppSpacing.p20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l10n.close),
                      ),
                    ),
                    SizedBox(width: AppSpacing.p12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(ctx);
                          final navigator = Navigator.of(ctx);
                          await Clipboard.setData(const ClipboardData(text: _supportEmail));
                          navigator.pop();
                          messenger.showSnackBar(
                            SnackBar(content: Text(l10n.supportEmailCopied)),
                          );
                        },
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            l10n.contactUs,
                            style: tt.titleSmall?.copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PlanDef def;
  final String name;
  final String tagline;
  final List<String> features;
  final bool isCurrent;
  final bool isRecommended;
  final VoidCallback onChoose;

  const _PlanCard({
    required this.def,
    required this.name,
    required this.tagline,
    required this.features,
    required this.isCurrent,
    required this.isRecommended,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;
    const accent = AppColors.secondaryColor;
    final clientsLine = def.isUnlimited
        ? l10n.planClientsUnlimited
        : l10n.planClientsUpTo(def.maxClients!);
    final showRibbon = isCurrent || isRecommended;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent
              ? accent.withValues(alpha: 0.5)
              : cs.outlineVariant.withValues(alpha: 0.28),
          width: isCurrent ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showRibbon)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: accent.withValues(alpha: isCurrent ? 0.16 : 0.1),
              child: Center(
                child: Text(
                  (isCurrent ? l10n.planCurrent : l10n.planMostPopular).toUpperCase(),
                  style: tt.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(def.icon, size: 20, color: accent),
                    ),
                    SizedBox(width: AppSpacing.p12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            tagline,
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          def.isFree ? l10n.planFree : '\$${def.priceMonthlyUsd}',
                          style: tt.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            color: cs.onSurface,
                          ),
                        ),
                        if (!def.isFree)
                          Text(
                            l10n.planPerMonth,
                            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.p16),
                _FeatureLine(text: clientsLine, bold: true),
                for (final f in features) ...[
                  SizedBox(height: AppSpacing.p8 + 2),
                  _FeatureLine(text: f),
                ],
                SizedBox(height: AppSpacing.p20),
                if (isCurrent)
                  Container(
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      l10n.planCurrent,
                      style: tt.titleSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: onChoose,
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        l10n.planChoose(name),
                        style: tt.titleSmall?.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  final String text;
  final bool bold;

  const _FeatureLine({required this.text, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(PhosphorIconsBold.check, size: 15, color: AppColors.secondaryColor),
        SizedBox(width: AppSpacing.p8),
        Expanded(
          child: Text(
            text,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
