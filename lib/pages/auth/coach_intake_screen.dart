import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/l10n/enum_labels.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/models/coach_intake_draft.dart';
import 'package:valence/models/enums.dart';
import 'package:valence/pages/auth/signup_screen.dart';
import 'package:valence/pages/coach/coach_persistant_tabs.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/ui/ui.dart';

/// Coach onboarding. A few quick questions that build the coach's profile and
/// business context (specialties, experience, roster size, current tooling) → a
/// brief setup moment → a welcome reveal.
///
/// Runs in two modes (mirrors the client flow):
///  • [newUser] = true  → reached from the intro *before* an account exists;
///    the reveal CTA carries the [CoachIntakeDraft] into signup, which persists it.
///  • [newUser] = false → an already-signed-in coach who hasn't onboarded yet
///    (routed here from splash); the reveal CTA saves directly.
class CoachIntakeScreen extends StatefulWidget {
  final bool newUser;

  const CoachIntakeScreen({super.key, this.newUser = false});

  @override
  State<CoachIntakeScreen> createState() => _CoachIntakeScreenState();
}

class _CoachIntakeScreenState extends State<CoachIntakeScreen>
    with TickerProviderStateMixin {
  static const int _questions = 4;
  static const int _analyzing = 4;
  static const int _result = 5;

  final _pageController = PageController();
  final _firestoreService = FirestoreService();
  int _step = 0;
  bool _saving = false;

  final Set<CoachSpecialty> _specialties = {};
  CoachExperience? _experience;
  RosterBand? _roster;
  CoachPriorTool? _prior;

  late final AnimationController _analyze = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed && _step == _analyzing) _goToResult();
    });
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void dispose() {
    _analyze.dispose();
    _reveal.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool get _canFinish =>
      _specialties.isNotEmpty && _experience != null && _roster != null && _prior != null && !_saving;

  void _goTo(int step) => _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );

  void _next() {
    if (_step >= _questions - 1) return;
    HapticFeedback.selectionClick();
    setState(() => _step++);
    _goTo(_step);
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _step--);
    _goTo(_step);
  }

  void _startAnalyzing() {
    HapticFeedback.selectionClick();
    setState(() => _step = _analyzing);
    _goTo(_analyzing);
    _analyze.forward(from: 0);
  }

  void _goToResult() {
    setState(() => _step = _result);
    _goTo(_result);
    _reveal.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  Future<void> _finish() async {
    if (!_canFinish) return;

    // Pre-signup: carry the answers into account creation, which persists them.
    if (widget.newUser) {
      HapticFeedback.lightImpact();
      final draft = CoachIntakeDraft(
        specialties: _specialties.toList(),
        experience: _experience!,
        rosterBand: _roster!,
        priorTool: _prior!,
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SignupScreen(userRole: UserRole.coach, coachDraft: draft),
        ),
      );
      return;
    }

    // Already authenticated (existing coach who hasn't onboarded): save directly.
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await _firestoreService.saveCoachIntake(
        user.uid,
        specialties: _specialties.map((e) => e.name).toList(),
        experience: _experience!.name,
        rosterBand: _roster!.name,
        priorTool: _prior!.name,
      );
      await auth.refreshCurrentUser();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CoachPersistantTabs()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showVToast(context, context.l10n.coachIntakeSaveError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final showHeader = _step < _questions;

    return Scaffold(
      backgroundColor: t.canvas,
      body: Stack(
        children: [
          const Positioned.fill(child: VSkyGlow(alpha: 0.10)),
          SafeArea(
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: VDuration.standard,
                  transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
                  child: showHeader
                      ? Padding(
                          key: const ValueKey('progress'),
                          padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 8),
                          child: Row(
                            children: [
                              VIconCircle(
                                icon: PhosphorIconsBold.caretLeft,
                                onTap: _back,
                                semanticLabel: context.l10n.back,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: VProgressSegments(count: _questions, index: _step),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(key: ValueKey('blank'), height: 8, width: double.infinity),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _StepFade(key: const ValueKey(0), active: _step == 0, child: _specialtiesStep()),
                      _StepFade(key: const ValueKey(1), active: _step == 1, child: _experienceStep()),
                      _StepFade(key: const ValueKey(2), active: _step == 2, child: _rosterStep()),
                      _StepFade(key: const ValueKey(3), active: _step == 3, child: _priorStep()),
                      _analyzingStep(),
                      _resultStep(),
                    ],
                  ),
                ),
                if (_step == 0)
                  _barWrap(VPillButton.primary(
                    label: context.l10n.continueLabel,
                    onPressed: _specialties.isNotEmpty ? _next : null,
                  ))
                else if (_step == _result)
                  _barWrap(VPillButton.hero(
                    label: context.l10n.enterValence,
                    loading: _saving,
                    onPressed: _canFinish ? _finish : null,
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _barWrap(Widget child) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 16),
        child: child,
      );

  // -------------------------------------------------------------------------
  // Step scaffold — serif question + "why we ask" + body + quiet insight
  // -------------------------------------------------------------------------

  Widget _stepScaffold(
    String title,
    String subtitle,
    List<Widget> children, {
    IconData? insightIcon,
    String? insightText,
  }) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VTextScaleCap(
              child: Text(title, style: VType.serifDisplay.copyWith(color: t.ink)),
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: VType.subhead.copyWith(color: t.inkSecondary)),
            const SizedBox(height: 28),
            ...children,
            if (insightText != null) ...[
              const SizedBox(height: 20),
              _insight(insightIcon ?? PhosphorIconsFill.sparkle, insightText),
            ],
          ],
        ),
      ),
    );
  }

  Widget _insight(IconData icon, String text) {
    final t = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 1),
          child: Icon(icon, size: 14, color: t.goldDeep),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: VType.caption.copyWith(color: t.inkSecondary)),
        ),
      ],
    );
  }

  Widget _option(String title, String? subtitle, IconData icon,
          {required bool selected, required VoidCallback onTap}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: VOptionCard(
          icon: icon,
          label: title,
          subtitle: subtitle,
          selected: selected,
          onTap: onTap,
        ),
      );

  // -------------------------------------------------------------------------
  // Steps
  // -------------------------------------------------------------------------

  static const Map<CoachSpecialty, IconData> _specialtyIcons = {
    CoachSpecialty.weightLoss: PhosphorIconsFill.trendDown,
    CoachSpecialty.muscleGain: PhosphorIconsFill.barbell,
    CoachSpecialty.strength: PhosphorIconsFill.lightning,
    CoachSpecialty.nutrition: PhosphorIconsFill.forkKnife,
    CoachSpecialty.recomp: PhosphorIconsFill.arrowsClockwise,
    CoachSpecialty.generalFitness: PhosphorIconsFill.heartbeat,
    CoachSpecialty.endurance: PhosphorIconsFill.timer,
    CoachSpecialty.mobility: PhosphorIconsFill.pulse,
  };

  Widget _specialtiesStep() {
    final l10n = context.l10n;
    return _stepScaffold(l10n.ciSpecialtiesTitle, l10n.ciSpecialtiesSubtitle, [
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: CoachSpecialty.values.map((s) {
          final selected = _specialties.contains(s);
          return _specialtyChip(s.localizedLabel(l10n), _specialtyIcons[s]!, selected: selected,
              onTap: () {
            HapticFeedback.selectionClick();
            setState(() => selected ? _specialties.remove(s) : _specialties.add(s));
          });
        }).toList(),
      ),
    ], insightIcon: PhosphorIconsFill.target, insightText: l10n.ciSpecialtiesInsight);
  }

  Widget _experienceStep() {
    final l10n = context.l10n;
    const icons = {
      CoachExperience.justStarting: PhosphorIconsFill.sparkle,
      CoachExperience.oneToThree: PhosphorIconsFill.trendUp,
      CoachExperience.threeToFive: PhosphorIconsFill.medal,
      CoachExperience.fivePlus: PhosphorIconsFill.crown,
    };
    return _stepScaffold(l10n.ciExperienceTitle, l10n.ciExperienceSubtitle, [
      ...CoachExperience.values.map((e) => _option(
            e.localizedLabel(l10n),
            e.localizedHint(l10n),
            icons[e]!,
            selected: _experience == e,
            onTap: () {
              setState(() => _experience = e);
              _next();
            },
          )),
    ], insightIcon: PhosphorIconsFill.sparkle, insightText: l10n.ciExperienceInsight);
  }

  Widget _rosterStep() {
    final l10n = context.l10n;
    const icons = {
      RosterBand.solo: PhosphorIconsFill.user,
      RosterBand.small: PhosphorIconsFill.users,
      RosterBand.growing: PhosphorIconsFill.usersThree,
      RosterBand.established: PhosphorIconsFill.usersThree,
    };
    return _stepScaffold(l10n.ciRosterTitle, l10n.ciRosterSubtitle, [
      ...RosterBand.values.map((r) => _option(
            r.localizedLabel(l10n),
            null,
            icons[r]!,
            selected: _roster == r,
            onTap: () {
              setState(() => _roster = r);
              _next();
            },
          )),
    ], insightIcon: PhosphorIconsFill.users, insightText: l10n.ciRosterInsight);
  }

  Widget _priorStep() {
    final l10n = context.l10n;
    const icons = {
      CoachPriorTool.whatsapp: PhosphorIconsFill.chatCircle,
      CoachPriorTool.spreadsheets: PhosphorIconsFill.table,
      CoachPriorTool.otherApp: PhosphorIconsFill.deviceMobile,
      CoachPriorTool.penPaper: PhosphorIconsFill.pencilSimple,
      CoachPriorTool.mix: PhosphorIconsFill.stack,
    };
    return _stepScaffold(l10n.ciPriorTitle, l10n.ciPriorSubtitle, [
      ...CoachPriorTool.values.map((tool) => _option(
            tool.localizedLabel(l10n),
            null,
            icons[tool]!,
            selected: _prior == tool,
            onTap: () {
              setState(() => _prior = tool);
              _startAnalyzing();
            },
          )),
    ], insightIcon: PhosphorIconsFill.stack, insightText: l10n.ciPriorInsight);
  }

  Widget _specialtyChip(String label, IconData icon,
      {required bool selected, required VoidCallback onTap}) {
    final t = context.tokens;
    return VPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: VDuration.micro,
        curve: VMotion.curve,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? Color.alphaBlend(t.selectedWash, t.surface) : t.surfaceSubtle,
          borderRadius: BorderRadius.circular(VRadius.input),
          border: Border.all(
            color: selected ? t.gold : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? t.goldDeep : t.inkTertiary),
            const SizedBox(width: 8),
            Text(
              label,
              style: VType.subhead.copyWith(
                color: selected ? t.ink : t.inkSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Setting up — one gold ring fill + one quiet rotating line (Moment)
  // -------------------------------------------------------------------------

  Widget _analyzingStep() {
    final t = context.tokens;
    final l10n = context.l10n;
    final messages = [
      l10n.ciAnalyzing1,
      l10n.ciAnalyzing2,
      l10n.ciAnalyzing3,
      l10n.ciAnalyzing4,
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: AnimatedBuilder(
          animation: _analyze,
          builder: (context, _) {
            final v = _analyze.value;
            final idx = (v * messages.length).floor().clamp(0, messages.length - 1);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 5,
                          valueColor: AlwaysStoppedAnimation(t.surfaceSubtle),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: v,
                          strokeWidth: 5,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation(t.gold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                AnimatedSwitcher(
                  duration: VDuration.standard,
                  transitionBuilder: (c, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                          .animate(a),
                      child: c,
                    ),
                  ),
                  child: Text(
                    '${messages[idx]}…',
                    key: ValueKey(idx),
                    style: VType.subhead.copyWith(color: t.inkSecondary),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Result — welcome reveal (Moment)
  // -------------------------------------------------------------------------

  Widget _resultStep() {
    final t = context.tokens;
    final l10n = context.l10n;
    final name = context.read<AuthProvider>().currentUser?.name.trim().split(' ').first ?? '';

    double iv(double start, double end) =>
        CurvedAnimation(parent: _reveal, curve: Interval(start, end, curve: Curves.easeOutCubic))
            .value;

    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, _) {
        final headT = iv(0.0, 0.45);
        final cardT = iv(0.25, 0.75);
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Opacity(
                opacity: headT,
                child: Transform.scale(
                  scale: 0.8 + 0.2 * iv(0.0, 0.5),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: t.tintFill(t.gold), shape: BoxShape.circle),
                    child: Icon(PhosphorIconsFill.confetti, color: t.legibleTint(t.gold), size: 34),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Opacity(
                opacity: headT,
                child: Column(
                  children: [
                    VTextScaleCap(
                      child: Text(
                        name.isEmpty ? l10n.ciAllSet : l10n.ciWelcomeName(name),
                        textAlign: TextAlign.center,
                        style: VType.serifTitle.copyWith(color: t.ink),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(l10n.coachSetupReady,
                        textAlign: TextAlign.center,
                        style: VType.subhead.copyWith(color: t.inkSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Transform.translate(
                offset: Offset(0, 24 * (1 - cardT)),
                child: Opacity(
                  opacity: cardT,
                  child: Container(
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
                        Text(l10n.ciYourFocus,
                            style: VType.caption.copyWith(color: t.inkSecondary)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _specialties.map((s) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: t.tintFill(t.gold),
                                borderRadius: BorderRadius.circular(VRadius.pill),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_specialtyIcons[s]!, size: 13, color: t.goldDeep),
                                  const SizedBox(width: 6),
                                  Text(
                                    s.localizedLabel(l10n),
                                    style: VType.subhead
                                        .copyWith(color: t.goldDeep, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ===========================================================================
// Per-step entrance (fade + rise when it becomes the active page)
// ===========================================================================

class _StepFade extends StatefulWidget {
  final bool active;
  final Widget child;
  const _StepFade({super.key, required this.active, required this.child});

  @override
  State<_StepFade> createState() => _StepFadeState();
}

class _StepFadeState extends State<_StepFade> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: VDuration.entrance,
  );
  late final Animation<double> _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _slide =
      Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
          .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.forward();
  }

  @override
  void didUpdateWidget(covariant _StepFade old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _fade, child: SlideTransition(position: _slide, child: widget.child));
  }
}
