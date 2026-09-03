/// The beat right after a coach pays.
///
/// WHY THIS EXISTS.
///
/// Buying was three unrelated mechanisms stacked on each other: a Material
/// `CircularProgressIndicator` inside a `showDialog`, then a toast, then the
/// paywall popping itself. On device it read as a hang — the spinner sat there
/// while RevenueCat, the Firestore write and the auth refresh all resolved, and
/// a stock spinner says nothing about how long that is or whether it worked.
///
/// Three things were wrong, and they compounded.
///
/// 1. A Material spinner is the one widget in the app that could have come from
///    anywhere. §5.16 calls the paywall a MOMENT (§4-D); the screen that
///    follows paying cannot be the least designed surface in the product.
/// 2. The success was a TOAST — the same transient bar used for "note saved".
///    Committing money is the highest-stakes action the app has and it got the
///    lowest-weight confirmation available.
/// 3. Nothing named what they bought. The toast said "You're upgraded"; the
///    plan, and what it actually unlocks, went unspoken at the exact instant
///    the coach most wants to hear it.
///
/// SO THE SHAPE IS BORROWED, NOT INVENTED. This is the sibling of the coach
/// intake's welcome reveal (`coach_intake_screen._resultStep`): a tinted gold
/// circle carrying the tier's own glyph, a serif statement, then a real surface
/// card holding the substance — staggered off one controller so it assembles
/// rather than appears. The coach has met that screen once already; meeting it
/// again when they pay is continuity, not repetition.
///
/// The gold circle is the screen's ONE signature detail (§6.9). The card is
/// `surface`, never gold (§6.4).
library;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'v_atmosphere.dart';
import 'v_buttons.dart';
import 'v_icon.dart';

enum VPurchasePhase { working, done }

class VPurchaseMoment extends StatefulWidget {
  const VPurchaseMoment({
    super.key,
    required this.phase,
    required this.workingLabel,
    required this.welcomeLabel,
    required this.planName,
    required this.planIcon,
    required this.unlockedLabel,
    required this.benefits,
    required this.ctaLabel,
    required this.onContinue,
  });

  /// Driven by the caller: flips to [VPurchasePhase.done] only once the
  /// entitlement is granted AND written, so the reveal never lands ahead of
  /// the truth.
  final ValueListenable<VPurchasePhase> phase;

  final String workingLabel;
  final String welcomeLabel;
  final String planName;
  final IconData planIcon;
  final String unlockedLabel;
  final List<String> benefits;
  final String ctaLabel;

  /// The coach leaves on their own tap. An auto-dismiss timer would put a
  /// stopwatch on the one screen they might actually want to sit with.
  final VoidCallback onContinue;

  @override
  State<VPurchaseMoment> createState() => _VPurchaseMomentState();
}

class _VPurchaseMomentState extends State<VPurchaseMoment>
    with TickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
  )..repeat();

  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  );

  @override
  void initState() {
    super.initState();
    widget.phase.addListener(_onPhase);
    if (widget.phase.value == VPurchasePhase.done) _onPhase();
  }

  void _onPhase() {
    if (widget.phase.value != VPurchasePhase.done) return;
    _sweep.stop();
    _reveal.forward();
  }

  @override
  void dispose() {
    widget.phase.removeListener(_onPhase);
    _sweep.dispose();
    _reveal.dispose();
    super.dispose();
  }

  double _iv(double start, double end) => CurvedAnimation(
    parent: _reveal,
    curve: Interval(start, end, curve: Curves.easeOutCubic),
  ).value;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Material, not ColoredBox. `showGeneralDialog` inserts no Material, and
    // Flutter marks every Text without one by underlining it in yellow — the
    // whole reveal came up scribbled on until this was here.
    return Material(
      color: t.canvas,
      child: Stack(
        children: [
          Positioned.fill(child: VSkyGlow(alpha: 0.12)),
          SafeArea(
            child: ValueListenableBuilder<VPurchasePhase>(
              valueListenable: widget.phase,
              builder: (context, phase, _) =>
                  phase == VPurchasePhase.done ? _done(t) : _working(t),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Working — a sweep, not a ring. The house shape for "in progress" is a bar.
  // ---------------------------------------------------------------------

  Widget _working(ValenceTokens t) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(VRadius.pill),
            child: SizedBox(
              width: 132,
              height: 3,
              child: Stack(
                children: [
                  Container(color: t.surfaceSubtle),
                  AnimatedBuilder(
                    animation: _sweep,
                    builder: (context, _) => Align(
                      alignment: AlignmentDirectional(-1 + 2 * _sweep.value, 0),
                      child: FractionallySizedBox(
                        widthFactor: 0.36,
                        child: Container(color: t.gold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          VTextScaleCap(
            child: Text(
              widget.workingLabel,
              textAlign: TextAlign.center,
              style: VType.serifTitle.copyWith(color: t.ink),
            ),
          ),
        ],
      ),
    ),
  );

  // ---------------------------------------------------------------------
  // Done — the welcome reveal, assembled in three beats.
  // ---------------------------------------------------------------------

  Widget _done(ValenceTokens t) => AnimatedBuilder(
    animation: _reveal,
    builder: (context, _) {
      final headT = _iv(0.0, 0.45);
      final cardT = _iv(0.25, 0.8);
      final ctaT = _iv(0.55, 1.0);
      return Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: headT,
                      child: Transform.scale(
                        scale: 0.8 + 0.2 * headT,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: t.tintFill(t.gold),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: VIcon(
                              widget.planIcon,
                              size: 36,
                              color: t.legibleTint(t.gold),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Opacity(
                      opacity: headT,
                      child: Column(
                        children: [
                          VTextScaleCap(
                            child: Text(
                              widget.welcomeLabel,
                              textAlign: TextAlign.center,
                              style: VType.subhead.copyWith(
                                color: t.inkSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          VTextScaleCap(
                            child: Text(
                              widget.planName,
                              textAlign: TextAlign.center,
                              style: VType.serifDisplay.copyWith(color: t.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Transform.translate(
                      offset: Offset(0, 24 * (1 - cardT)),
                      child: Opacity(opacity: cardT, child: _card(t)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Opacity(
            opacity: ctaT,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: VPillButton.primary(
                label: widget.ctaLabel,
                onPressed: ctaT > 0.9 ? widget.onContinue : null,
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _card(ValenceTokens t) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: t.surface,
      borderRadius: BorderRadius.circular(VRadius.card),
      boxShadow: t.cardShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.unlockedLabel,
          style: VType.caption.copyWith(color: t.inkSecondary),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < widget.benefits.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(height: 12),
            Divider(height: 1, thickness: 1, color: t.hairline),
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 2),
                child: VIcon(
                  PhosphorIconsBold.check,
                  size: 16,
                  color: t.goldDeep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.benefits[i],
                  style: VType.subhead.copyWith(
                    color: t.ink,
                    fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}
