import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../config/plans.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/client_analysis.dart';
import '../../models/enums.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/client_analysis_service.dart';
import '../../services/firestore_service.dart';
import '../../ui/ui.dart';
import 'upgrade_screen.dart';

/// The coach's AI read of one client — top of the Analytics tab (§4-A working
/// screen, NOT a Moment: a coach wants the answer, not atmosphere, so this is
/// a flat card with a shimmer while it runs, no skyGlow).
///
/// It sits directly above the charts on purpose: the charts ARE the evidence
/// surface. Every point carries the numbers it came from, so the coach reads a
/// claim and can confirm it one scroll down (Yassine's requirement — the AI
/// proposes, the coach verifies).
///
/// GATING: this is the feature coaches pay for, so free coaches see it LOCKED
/// rather than hidden — a hidden feature sells nothing. Tapping the lock routes
/// to the paywall. Entitlement is read the same way the invite gate reads it
/// (`effectivePlanTier`), so an expired subscription falls back to free with no
/// extra logic here.
class ClientAnalysisCard extends StatefulWidget {
  const ClientAnalysisCard({super.key, required this.client});

  final AppUser client;

  @override
  State<ClientAnalysisCard> createState() => _ClientAnalysisCardState();
}

class _ClientAnalysisCardState extends State<ClientAnalysisCard> {
  final _firestore = FirestoreService();
  final _ai = ClientAnalysisService();

  ClientAnalysis? _analysis;
  bool _loading = true;
  bool _running = false;
  String? _error;

  /// Fingerprint of the CURRENT data, computed on demand. Drives the "nothing
  /// new since the last analysis" hint — a hint only, never a lock.
  String? _liveFingerprint;
  bool _enoughData = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final existing = await _firestore.getClientAnalysis(widget.client.uid);
      if (!mounted) return;
      setState(() {
        _analysis = existing;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// Reads the window, then asks Gemini. Explicitly triggered — never on open —
  /// so a coach browsing 30 clients doesn't fire 30 model calls.
  Future<void> _run() async {
    final coach = context.read<AuthProvider>().currentUser;
    if (coach == null || _running) return;

    // Captured before any await: reading it after the gap is a real bug (the
    // widget may be gone, and locale is needed to tell Gemini which language
    // to write in).
    final locale = Localizations.localeOf(context).languageCode;

    setState(() {
      _running = true;
      _error = null;
    });

    try {
      final logs = await _firestore
          .streamRecentLogs(widget.client.uid, days: ClientAnalysisService.contextDays)
          .first;
      final workouts = await _firestore
          .getRecentWorkouts(widget.client.uid, days: ClientAnalysisService.contextDays);

      final digest = _ai.buildDigest(
        client: widget.client,
        logs: logs,
        workouts: workouts,
        today: DateTime.now(),
      );
      _liveFingerprint = digest.fingerprint;

      // Guard BEFORE spending a call: a confident read of two days of logs is
      // noise dressed as insight.
      if (!digest.hasEnoughData) {
        if (!mounted) return;
        setState(() {
          _enoughData = false;
          _running = false;
        });
        return;
      }

      final result = await _ai.analyze(
        client: widget.client,
        coachId: coach.uid,
        digest: digest,
        locale: locale,
        now: DateTime.now(),
      );
      await _firestore.saveClientAnalysis(result);

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _analysis = result;
        _running = false;
        _enoughData = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _running = false;
        _error = context.l10n.aiInsightsError;
      });
    }
  }

  void _openPaywall() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UpgradeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coach = context.watch<AuthProvider>().currentUser;
    final tier = effectivePlanTier(
      tierId: coach?.subscriptionTier,
      expiry: coach?.subscriptionExpiryDate,
    );

    if (tier == PlanTier.free) return _LockedCard(onTap: _openPaywall);
    if (_loading) return const _CardShell(child: _LoadingBody());
    return _CardShell(child: _body(context));
  }

  Widget _body(BuildContext context) {
    if (_running) return const _LoadingBody();

    final l10n = context.l10n;
    final a = _analysis;

    if (!_enoughData) {
      return _EmptyBody(
        message: l10n.aiInsightsNoData,
        cta: null,
        onCta: null,
      );
    }
    if (a == null) {
      return _EmptyBody(
        message: l10n.aiInsightsTease,
        cta: l10n.analyzeWithAI,
        onCta: _run,
        error: _error,
      );
    }
    return _ResultBody(
      analysis: a,
      error: _error,
      // A hint, not a lock — re-analyzing is always allowed.
      isFresh: _liveFingerprint != null && _liveFingerprint == a.fingerprint,
      onRefresh: _run,
    );
  }
}

// ---------------------------------------------------------------------------
// Shell + states
// ---------------------------------------------------------------------------

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VSpace.cardPaddingHero),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        boxShadow: t.cardShadow,
      ),
      child: child,
    );
  }
}

/// Title row: gold sparkle glyph (gold = brand identity, §1.1) + the name.
class _CardTitle extends StatelessWidget {
  const _CardTitle({this.trailing});
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: t.tintFill(t.gold),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(PhosphorIconsFill.sparkle, size: 16, color: t.legibleTint(t.gold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(context.l10n.aiInsightsTitle,
              style: VType.title2.copyWith(color: t.ink)),
        ),
        ?trailing,
      ],
    );
  }
}

/// Free tier: visible but locked. This is the app's main upgrade moment.
class _LockedCard extends StatelessWidget {
  const _LockedCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;
    return VPressable(
      onTap: onTap,
      child: _CardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTitle(
              trailing: Icon(PhosphorIconsFill.lock, size: 16, color: t.legibleTint(t.gold)),
            ),
            const SizedBox(height: 10),
            Text(l10n.aiInsightsTease,
                style: VType.body.copyWith(color: t.inkSecondary)),
            const SizedBox(height: 14),
            VMiniPill(
              label: l10n.aiInsightsUnlock,
              icon: PhosphorIconsFill.crown,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeletons mirroring the real layout (§1.7-⑤ — the one allowed
/// loading animation).
class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CardTitle(),
        const SizedBox(height: 14),
        const VSkeleton(height: 18, width: 260),
        const SizedBox(height: 10),
        const VSkeleton(height: 14, width: 200),
        const SizedBox(height: 16),
        const VSkeleton(height: 14, width: 240),
        const SizedBox(height: 8),
        const VSkeleton(height: 14, width: 180),
        const SizedBox(height: 14),
        Text(
          context.l10n.aiInsightsReading,
          style: VType.caption.copyWith(color: context.tokens.inkTertiary),
        ),
      ],
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({
    required this.message,
    required this.cta,
    required this.onCta,
    this.error,
  });

  final String message;
  final String? cta;
  final VoidCallback? onCta;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CardTitle(),
        const SizedBox(height: 10),
        Text(message, style: VType.body.copyWith(color: t.inkSecondary)),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: VType.caption.copyWith(color: t.alert)),
        ],
        if (cta != null) ...[
          const SizedBox(height: 14),
          VMiniPill(label: cta!, icon: PhosphorIconsFill.sparkle, onTap: onCta),
        ],
      ],
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({
    required this.analysis,
    required this.isFresh,
    required this.onRefresh,
    this.error,
  });

  final ClientAnalysis analysis;
  final bool isFresh;
  final VoidCallback onRefresh;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardTitle(
          trailing: VTextAction(label: l10n.aiInsightsRefresh, onTap: onRefresh),
        ),
        const SizedBox(height: 12),

        // The headline is the whole point — the one sentence a coach reads.
        Text(analysis.headline, style: VType.headline.copyWith(color: t.ink)),
        const SizedBox(height: 10),

        _Freshness(analysis: analysis, isFresh: isFresh),

        if (analysis.wins.isNotEmpty) ...[
          const SizedBox(height: 18),
          _Group(
            label: l10n.aiInsightsWins,
            points: analysis.wins,
            dot: t.good,
          ),
        ],
        if (analysis.risks.isNotEmpty) ...[
          const SizedBox(height: 18),
          _Group(
            label: l10n.aiInsightsRisks,
            points: analysis.risks,
            dot: null, // per-point severity colour
          ),
        ],
        if (analysis.actions.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(l10n.aiInsightsActions.toUpperCase(),
              style: VType.label.copyWith(color: t.inkTertiary)),
          const SizedBox(height: 8),
          ...analysis.actions.map(
            (a) => Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 5, end: 8),
                    child: Icon(PhosphorIconsBold.caretRight,
                        size: 12, color: t.inkTertiary),
                  ),
                  Expanded(child: Text(a, style: VType.body.copyWith(color: t.ink))),
                ],
              ),
            ),
          ),
        ],

        if (error != null) ...[
          const SizedBox(height: 10),
          Text(error!, style: VType.caption.copyWith(color: t.alert)),
        ],

        const SizedBox(height: 16),
        Divider(height: 1, thickness: 1, color: t.hairline),
        const SizedBox(height: 10),
        Text(
          l10n.aiInsightsDisclaimer,
          style: VType.caption.copyWith(color: t.inkTertiary),
        ),
      ],
    );
  }
}

/// "Analyzed today · Medium confidence" — plus the two honest caveats: nothing
/// new since last time, or written in another language.
class _Freshness extends StatelessWidget {
  const _Freshness({required this.analysis, required this.isFresh});
  final ClientAnalysis analysis;
  final bool isFresh;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;
    final days = DateTime.now().difference(analysis.createdAt).inDays;
    final when = days <= 0
        ? l10n.aiAnalyzedToday
        : days == 1
            ? l10n.aiAnalyzedYesterday
            : l10n.aiAnalyzedDaysAgo(days);

    final confWord = switch (analysis.confidence) {
      AnalysisConfidence.high => l10n.confHigh,
      AnalysisConfidence.medium => l10n.confMedium,
      AnalysisConfidence.low => l10n.confLow,
    };
    final confTint = switch (analysis.confidence) {
      AnalysisConfidence.high => t.good,
      AnalysisConfidence.medium => t.watch,
      AnalysisConfidence.low => t.inkTertiary,
    };

    final localeNow = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(when, style: VType.caption.copyWith(color: t.inkTertiary)),
            const SizedBox(width: 8),
            Container(width: 6, height: 6,
                decoration: BoxDecoration(color: confTint, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l10n.aiInsightsConfidence(confWord),
                style: VType.caption.copyWith(color: t.inkTertiary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        // An analysis older than the week it reports on is describing a week
        // that no longer exists. Saying "Analyzed 10 days ago" quietly is not
        // enough — a coach could act on a stale read, so this is stated in
        // `watch` and outranks the "nothing new" hint.
        if (analysis.isOutdated(DateTime.now())) ...[
          const SizedBox(height: 6),
          Text(l10n.aiInsightsOutdated,
              style: VType.caption.copyWith(color: t.watch)),
        ] else if (isFresh) ...[
          const SizedBox(height: 4),
          Text(l10n.aiInsightsUpToDate,
              style: VType.caption.copyWith(color: t.inkTertiary)),
        ],
        // The prose is baked in the language it was generated in — say so
        // rather than showing a coach the wrong language silently.
        if (analysis.isStaleForLocale(localeNow)) ...[
          const SizedBox(height: 4),
          Text(
            l10n.aiInsightsOtherLanguage(_languageName(localeNow)),
            style: VType.caption.copyWith(color: t.inkTertiary),
          ),
        ],
      ],
    );
  }
}

/// The current language's own native name ("العربية", "Français"), reusing the
/// language picker's list rather than keeping a second copy in sync.
String _languageName(String code) {
  for (final l in kAppLanguages) {
    if (l.code == code) return l.nativeName;
  }
  return code.toUpperCase();
}

/// A labelled group of points. Status colour appears ONCE per row as a dot
/// (§6-1: status lives in dots, said once per row) — the text stays ink so the
/// card never turns into a traffic light.
class _Group extends StatelessWidget {
  const _Group({required this.label, required this.points, required this.dot});

  final String label;
  final List<AnalysisPoint> points;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: VType.label.copyWith(color: t.inkTertiary)),
        const SizedBox(height: 8),
        ...points.map((p) {
          final c = dot ??
              switch (p.severity) {
                AnalysisSeverity.alert => t.alert,
                AnalysisSeverity.watch => t.watch,
                _ => t.inkTertiary,
              };
          return Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 6, end: 8),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.text, style: VType.body.copyWith(color: t.ink)),
                      if (p.evidence.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        // The receipt. Quiet, but always present — this is what
                        // the coach checks against the charts below.
                        Text(
                          p.evidence,
                          style: VType.caption.copyWith(color: t.inkTertiary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
