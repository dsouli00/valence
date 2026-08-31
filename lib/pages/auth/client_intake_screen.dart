import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/l10n/enum_labels.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/models/client_intake_draft.dart';
import 'package:valence/models/enums.dart';
import 'package:valence/pages/auth/signup_screen.dart';
import 'package:valence/pages/client/client_persistant_tabs.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/ui/ui.dart';
import 'package:valence/utils/units.dart';

/// The client personalization journey — a one-question-per-screen quiz (with an
/// inline metric/imperial unit choice on the body-measurement steps) → a build
/// moment → an animated plan reveal with an honest, deficit-derived timeline.
///
/// The emotional/benefit intro lives in the role intro that precedes this
/// (see [RoleIntroScreen]); this screen is the personalization itself.
///
/// Runs in two modes:
///  • [newUser] = true  → reached from the intro *before* an account exists.
///    The reveal CTA carries the collected [ClientIntakeDraft] into signup,
///    which persists it once authenticated.
///  • [newUser] = false → an already-signed-in client who still needs a plan
///    (routed here from splash/signup). The reveal CTA saves directly.
class ClientIntakeScreen extends StatefulWidget {
  final bool newUser;

  const ClientIntakeScreen({super.key, this.newUser = false});

  @override
  State<ClientIntakeScreen> createState() => _ClientIntakeScreenState();
}

class _ClientIntakeScreenState extends State<ClientIntakeScreen>
    with TickerProviderStateMixin {
  // Step indices (a single PageView; one screen per beat).
  static const int _kGoal = 0;
  static const int _kSex = 1;
  static const int _kAge = 2;
  static const int _kHeight = 3;
  static const int _kWeight = 4;
  static const int _kTarget = 5;
  static const int _kActivity = 6;
  static const int _kPrior = 7;
  static const int _kCommit = 8;
  static const int _kAnalyzing = 9;
  static const int _kResult = 10;
  static const int _kQuestionCount = _kCommit - _kGoal + 1;

  final _pageController = PageController();
  final _firestoreService = FirestoreService();
  int _step = 0;
  bool _saving = false;

  /// Display preference. Body values are always stored canonically in metric.
  bool _metric = true;

  FitnessGoal? _goal;
  BiologicalSex? _sex;
  ActivityLevel? _activity;
  String? _priorAnswer;
  // Controllers always hold canonical metric values (kg / cm).
  final _ageController = TextEditingController(text: '25');
  final _heightController = TextEditingController(text: '170');
  final _weightController = TextEditingController(text: '70');
  final _targetController = TextEditingController(text: '68');

  late final AnimationController _analyze = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed && _step == _kAnalyzing) _goToResult();
    });
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void dispose() {
    _analyze.dispose();
    _reveal.dispose();
    _pageController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  int? get _age => int.tryParse(_ageController.text.trim());
  double? get _height => double.tryParse(_heightController.text.trim());
  double? get _weight => double.tryParse(_weightController.text.trim());
  double? get _target => double.tryParse(_targetController.text.trim());

  bool _inRange(num? v, num lo, num hi) => v != null && v >= lo && v <= hi;

  bool get _canAdvance {
    switch (_step) {
      case _kAge:
        return _inRange(_age, 13, 100);
      case _kHeight:
        return _inRange(_height, 120, 230);
      case _kWeight:
        return _inRange(_weight, 30, 250);
      case _kTarget:
        return _inRange(_target, 30, 250);
      default:
        return true;
    }
  }

  /// The complete draft, or null while any required answer is missing/invalid.
  ClientIntakeDraft? get _draft {
    if (_goal == null || _sex == null || _activity == null) return null;
    if (!_inRange(_age, 13, 100) ||
        !_inRange(_height, 120, 230) ||
        !_inRange(_weight, 30, 250) ||
        !_inRange(_target, 30, 250)) {
      return null;
    }
    return ClientIntakeDraft(
      goal: _goal!,
      sex: _sex!,
      age: _age!,
      heightCm: _height!,
      currentWeight: _weight!,
      targetWeight: _target!,
      activity: _activity!,
      priorTracking: _priorAnswer,
      metric: _metric,
    );
  }

  String _fmtNum(double v, int decimals) {
    if (decimals == 0 || v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(1);
  }

  /// Weight as a display string in the user's chosen unit.
  String _weightLabel(double kg) => _metric
      ? '${_fmtNum(kg, 1)} ${context.l10n.unitKg}'
      : '${kgToLb(kg).round()} ${context.l10n.unitLb}';

  void _setMetric(bool v) {
    if (v == _metric) return;
    HapticFeedback.selectionClick();
    setState(() => _metric = v);
  }

  void _goTo(int step) => _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );

  void _advance() {
    FocusScope.of(context).unfocus();
    if (_step >= _kCommit) return; // commit hands off to the build moment
    HapticFeedback.selectionClick();
    setState(() => _step++);
    _goTo(_step);
  }

  void _back() {
    if (_step >= _kAnalyzing) return; // no going back once the plan is building
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _step--);
    _goTo(_step);
  }

  void _startAnalyzing() {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    setState(() => _step = _kAnalyzing);
    _goTo(_kAnalyzing);
    _analyze.forward(from: 0);
  }

  void _goToResult() {
    setState(() => _step = _kResult);
    _goTo(_kResult);
    _reveal.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  Future<void> _finish() async {
    final draft = _draft;
    if (draft == null || _saving) return;

    // Pre-signup: carry the built plan into account creation, which persists it.
    if (widget.newUser) {
      HapticFeedback.lightImpact();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SignupScreen(userRole: UserRole.client, intakeDraft: draft),
        ),
      );
      return;
    }

    // Already authenticated (existing unconfigured client): save directly.
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await _firestoreService.saveClientIntake(
        user.uid,
        age: draft.age,
        heightCm: draft.heightCm,
        currentWeight: draft.currentWeight,
        targetWeight: draft.targetWeight,
        sex: draft.sex.name,
        activityLevel: draft.activity.name,
        goal: draft.goal.name,
        macros: draft.macros,
        priorTracking: draft.priorTracking,
        weightUnit: draft.weightUnit,
      );
      await auth.refreshCurrentUser();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ClientPersistantTabs()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showVToast(context, context.l10n.intakeSaveError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final inQuestions = _step >= _kGoal && _step <= _kCommit;

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
                  child: inQuestions
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
                                child: VProgressSegments(
                                  count: _kQuestionCount,
                                  index: _step - _kGoal,
                                ),
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
                      _StepFade(key: const ValueKey(0), active: _step == _kGoal, child: _goalStep()),
                      _StepFade(key: const ValueKey(1), active: _step == _kSex, child: _sexStep()),
                      _StepFade(key: const ValueKey(2), active: _step == _kAge, child: _ageStep()),
                      _StepFade(key: const ValueKey(3), active: _step == _kHeight, child: _heightStep()),
                      _StepFade(key: const ValueKey(4), active: _step == _kWeight, child: _weightStep()),
                      _StepFade(key: const ValueKey(5), active: _step == _kTarget, child: _targetStep()),
                      _StepFade(key: const ValueKey(6), active: _step == _kActivity, child: _activityStep()),
                      _StepFade(key: const ValueKey(7), active: _step == _kPrior, child: _priorStep()),
                      _StepFade(key: const ValueKey(8), active: _step == _kCommit, child: _commitStep()),
                      _analyzingStep(),
                      _resultStep(),
                    ],
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final l10n = context.l10n;
    if (_step == _kAge || _step == _kHeight || _step == _kWeight || _step == _kTarget) {
      return _barWrap(VPillButton.primary(
        label: l10n.continueLabel,
        onPressed: _canAdvance ? _advance : null,
      ));
    }
    if (_step == _kCommit) {
      return _barWrap(VPillButton.primary(
        label: l10n.onboardCommitCta,
        icon: PhosphorIconsFill.fire,
        onPressed: _startAnalyzing,
      ));
    }
    if (_step == _kResult) {
      return _barWrap(VPillButton.hero(
        label: widget.newUser ? l10n.createAccountSavePlan : l10n.startTracking,
        loading: _saving,
        onPressed: (_draft != null && !_saving) ? _finish : null,
      ));
    }
    return const SizedBox.shrink();
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

  /// A quiet "gives something back" line under a question — never a boxed card.
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
          {required bool selected, required VoidCallback onTap, Color? tint}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: VOptionCard(
          icon: icon,
          label: title,
          subtitle: subtitle,
          tint: tint,
          selected: selected,
          onTap: onTap,
        ),
      );

  /// Numeric steps get a centred, focused composition — the serif question
  /// leads, then the control (stepper or dial). Varied controls (not an emblem)
  /// keep the four beats distinct.
  Widget _numericStep(
    String title,
    String subtitle,
    List<Widget> children, {
    IconData? insightIcon,
    String? insightText,
  }) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            VTextScaleCap(
              child: Text(title,
                  textAlign: TextAlign.center,
                  style: VType.serifDisplay.copyWith(color: t.ink)),
            ),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: VType.subhead.copyWith(color: t.inkSecondary)),
            const SizedBox(height: 28),
            ...children,
            if (insightText != null) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(insightIcon ?? PhosphorIconsFill.sparkle, size: 14, color: t.goldDeep),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(insightText,
                        style: VType.caption.copyWith(color: t.inkSecondary)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Question steps
  // -------------------------------------------------------------------------

  Widget _goalStep() {
    final l10n = context.l10n;
    return _stepScaffold(l10n.intakeGoalTitle, l10n.intakeGoalSubtitle, [
      _option(l10n.goalLoseTitle, l10n.goalLoseSubtitle, noMirrorIcon(PhosphorIconsFill.trendDown),
          selected: _goal == FitnessGoal.lose, onTap: () {
        setState(() => _goal = FitnessGoal.lose);
        _advance();
      }),
      _option(l10n.goalMaintainTitle, l10n.goalMaintainSubtitle, PhosphorIconsFill.equals,
          selected: _goal == FitnessGoal.maintain, onTap: () {
        setState(() => _goal = FitnessGoal.maintain);
        _advance();
      }),
      _option(l10n.goalGainTitle, l10n.goalGainSubtitle, noMirrorIcon(PhosphorIconsFill.trendUp),
          selected: _goal == FitnessGoal.gain, onTap: () {
        setState(() => _goal = FitnessGoal.gain);
        _advance();
      }),
    ]);
  }

  Widget _sexStep() {
    final l10n = context.l10n;
    return _stepScaffold(l10n.intakeSexTitle, l10n.intakeSexSubtitle, [
      _option(l10n.sexMale, null, PhosphorIconsFill.genderMale,
          selected: _sex == BiologicalSex.male, onTap: () {
        setState(() => _sex = BiologicalSex.male);
        _advance();
      }),
      _option(l10n.sexFemale, null, PhosphorIconsFill.genderFemale,
          selected: _sex == BiologicalSex.female, onTap: () {
        setState(() => _sex = BiologicalSex.female);
        _advance();
      }),
    ]);
  }

  Widget _ageStep() {
    final l10n = context.l10n;
    return _numericStep(l10n.intakeAgeTitle, l10n.intakeAgeSubtitle, [
      VStepper(
        min: 13,
        max: 100,
        step: 1,
        value: (_age ?? 25).toDouble(),
        unit: l10n.unitYears,
        decimals: 0,
        onChanged: (v) {
          _ageController.text = _fmtNum(v, 0);
          setState(() {});
        },
      ),
    ], insightIcon: PhosphorIconsFill.fire, insightText: l10n.intakeAgeInsight);
  }

  Widget _heightStep() {
    final l10n = context.l10n;
    final cm = _height ?? 170;
    return _numericStep(l10n.intakeHeightTitle, l10n.intakeHeightSubtitle, [
      Center(child: _unitToggle()),
      const SizedBox(height: 24),
      VRulerDial(
        key: ValueKey('height_$_metric'),
        min: _metric ? 120 : 47,
        max: _metric ? 230 : 91,
        step: 1,
        value: _metric ? cm : cmToInches(cm),
        unit: _metric ? l10n.unitCm : '',
        decimals: 0,
        displayFormatter: _metric
            ? null
            : (inches) {
                final ti = inches.round();
                return "${ti ~/ 12}'${ti % 12}\"";
              },
        onChanged: (v) {
          final canonical = _metric ? v : inchesToCm(v);
          _heightController.text = _fmtNum(canonical, 0);
          setState(() {});
        },
      ),
    ], insightIcon: PhosphorIconsFill.ruler, insightText: l10n.intakeHeightInsight);
  }

  Widget _weightStep() {
    final l10n = context.l10n;
    final kg = _weight ?? 70;
    return _numericStep(l10n.intakeWeightTitle, l10n.intakeWeightSubtitle, [
      Center(child: _unitToggle()),
      const SizedBox(height: 24),
      VRulerDial(
        key: ValueKey('weight_$_metric'),
        min: _metric ? 30 : 66,
        max: _metric ? 250 : 550,
        step: _metric ? 0.5 : 1,
        value: _metric ? kg : kgToLb(kg),
        unit: _metric ? l10n.unitKg : l10n.unitLb,
        decimals: _metric ? 1 : 0,
        onChanged: (v) {
          final canonical = _metric ? v : lbToKg(v);
          _weightController.text = _fmtNum(canonical, 1);
          setState(() {});
        },
      ),
    ], insightIcon: PhosphorIconsFill.flagBanner, insightText: l10n.intakeWeightInsight);
  }

  Widget _targetStep() {
    final l10n = context.l10n;
    final currentKg = _weight ?? 70;
    final loKg = (currentKg - 40).clamp(30, 250).toDouble();
    final hiKg = (currentKg + 40).clamp(30, 250).toDouble();
    final tgtKg = _target ?? (currentKg - 2);
    return _numericStep(l10n.intakeTargetTitle, l10n.intakeTargetSubtitle, [
      Center(child: _unitToggle()),
      const SizedBox(height: 24),
      VStepper(
        key: ValueKey('target_${_metric}_$currentKg'),
        min: _metric ? loKg : kgToLb(loKg),
        max: _metric ? hiKg : kgToLb(hiKg),
        step: _metric ? 0.5 : 1,
        value: _metric ? tgtKg : kgToLb(tgtKg),
        unit: _metric ? l10n.unitKg : l10n.unitLb,
        decimals: _metric ? 1 : 0,
        onChanged: (v) {
          final canonical = _metric ? v : lbToKg(v);
          _targetController.text = _fmtNum(canonical, 1);
          setState(() {});
        },
      ),
      const SizedBox(height: 20),
      Center(child: _deltaBadge(currentKg)),
    ], insightIcon: noMirrorIcon(PhosphorIconsFill.trendDown), insightText: l10n.intakeTargetInsight);
  }

  Widget _activityStep() {
    final l10n = context.l10n;
    return _stepScaffold(l10n.intakeActivityTitle, l10n.intakeActivitySubtitle, [
      // One glyph per level, not the same pulse five times. Five identical
      // icons carry no information and sit directly after the goal step, which
      // gives each of its options a meaningful one — so the repetition reads as
      // unfinished rather than restrained.
      ...ActivityLevel.values.map((a) => _option(
            a.localizedLabel(l10n),
            a.localizedHint(l10n),
            noMirrorIcon(switch (a) {
              ActivityLevel.sedentary => PhosphorIconsFill.armchair,
              ActivityLevel.light => PhosphorIconsFill.personSimpleWalk,
              ActivityLevel.moderate => PhosphorIconsFill.personSimpleBike,
              ActivityLevel.active => PhosphorIconsFill.personSimpleRun,
              ActivityLevel.veryActive => PhosphorIconsFill.barbell,
            }),
            selected: _activity == a,
            onTap: () {
              setState(() => _activity = a);
              _advance();
            },
          )),
    ], insightIcon: PhosphorIconsFill.pulse, insightText: l10n.intakeActivityInsight);
  }

  Widget _priorStep() {
    final l10n = context.l10n;
    void pick(String key) {
      setState(() => _priorAnswer = key);
      _advance();
    }

    return _stepScaffold(l10n.intakePriorTitle, l10n.intakePriorSubtitle, [
      _option(l10n.priorNever, null, PhosphorIconsFill.sparkle,
          selected: _priorAnswer == 'never', onTap: () => pick('never')),
      _option(l10n.priorStopped, null, PhosphorIconsFill.arrowsClockwise,
          selected: _priorAnswer == 'stopped', onTap: () => pick('stopped')),
      _option(l10n.priorCurrent, null, PhosphorIconsFill.checkCircle,
          selected: _priorAnswer == 'current', onTap: () => pick('current')),
    ]);
  }

  Widget _unitToggle() => VSegmented<bool>(
        segments: [
          VSegment(true, context.l10n.unitsMetric),
          VSegment(false, context.l10n.unitsImperial),
        ],
        selected: _metric,
        onChanged: _setMetric,
      );

  Widget _deltaBadge(double currentKg) {
    final t = context.tokens;
    final l10n = context.l10n;
    final tgtKg = _target ?? currentKg;
    final deltaKg = tgtKg - currentKg;
    final displayDelta = _metric ? deltaKg : kgToLb(deltaKg);
    final maintain = displayDelta.abs() < (_metric ? 0.25 : 0.5);
    final losing = displayDelta < 0;
    final unit = _metric ? l10n.unitKg : l10n.unitLb;
    final amount = displayDelta.abs().toStringAsFixed(_metric ? 1 : 0);
    final base = maintain ? t.inkSecondary : (losing ? t.good : t.gold);
    final color = t.legibleTint(base);
    final label = maintain
        ? l10n.deltaMaintain
        : (losing ? l10n.weightToLoseU(amount, unit) : l10n.weightToGainU(amount, unit));
    final icon = maintain
        ? PhosphorIconsFill.equals
        : (losing ? noMirrorIcon(PhosphorIconsFill.trendDown) : noMirrorIcon(PhosphorIconsFill.trendUp));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: VType.subhead.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Micro-commitment — a small "I'm in" beat before the plan is built (Moment)
  // -------------------------------------------------------------------------

  Widget _commitStep() {
    final t = context.tokens;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: t.tintFill(t.gold), shape: BoxShape.circle),
              child: Icon(PhosphorIconsFill.handshake, color: t.legibleTint(t.gold), size: 40),
            ),
            const SizedBox(height: 24),
            Text(l10n.onboardCommitTitle,
                textAlign: TextAlign.center,
                style: VType.serifTitle.copyWith(color: t.ink)),
            const SizedBox(height: 12),
            Text(l10n.onboardCommitSubtitle,
                textAlign: TextAlign.center,
                style: VType.body.copyWith(color: t.inkSecondary)),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build moment — one gold ring fill + one quiet rotating line (Moment)
  // -------------------------------------------------------------------------

  Widget _analyzingStep() {
    final t = context.tokens;
    final l10n = context.l10n;
    final messages = [
      l10n.intakeAnalyzing1,
      l10n.intakeAnalyzing2,
      l10n.intakeAnalyzing3,
      l10n.intakeAnalyzing4,
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
                  // Sequential, not simultaneous. AnimatedSwitcher's default
                  // stacks the outgoing and incoming child centre-aligned for
                  // the WHOLE duration, so both strings paint at once and the
                  // line is briefly illegible — photographed on the meal-scan
                  // moment as "Estimating portions" printed over a fading
                  // "Counting calories". Intervals split the window: the old
                  // line is gone by the halfway point, the new one starts
                  // there.
                  switchOutCurve: const Interval(0.5, 1.0),
                  switchInCurve: const Interval(0.5, 1.0),
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
  // Plan reveal — a Moment: serif greeting, count-up calories, macros, timeline
  // -------------------------------------------------------------------------

  Widget _resultStep() {
    final t = context.tokens;
    final l10n = context.l10n;
    final draft = _draft;
    final macros = draft?.macros;
    final name = context.read<AuthProvider>().currentUser?.name.trim().split(' ').first ?? '';
    final cal = macros?.calories ?? 0;

    double iv(double start, double end) =>
        CurvedAnimation(parent: _reveal, curve: Interval(start, end, curve: Curves.easeOutCubic))
            .value;

    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, _) {
        final headT = iv(0.0, 0.40);
        final calT = iv(0.22, 0.68);
        final timeT = iv(0.6, 1.0);
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Opacity(
                opacity: headT,
                child: Column(
                  children: [
                    VTextScaleCap(
                      child: Text(
                        name.isEmpty ? l10n.intakePlanReady : l10n.intakePlanReadyNamed(name),
                        textAlign: TextAlign.center,
                        style: VType.serifTitle.copyWith(color: t.ink),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(l10n.intakePlanSubtitle,
                        textAlign: TextAlign.center,
                        style: VType.subhead.copyWith(color: t.inkSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Transform.translate(
                offset: Offset(0, 24 * (1 - calT)),
                child: Opacity(
                  opacity: calT,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(VRadius.card),
                      boxShadow: t.cardShadow,
                    ),
                    child: Column(
                      children: [
                        Text(l10n.dailyCalories,
                            style: VType.caption.copyWith(color: t.inkSecondary)),
                        const SizedBox(height: 8),
                        VTextScaleCap(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text('${(cal * calT).round()}',
                                  style: VType.display.copyWith(color: t.ink)),
                              const SizedBox(width: 6),
                              Text(l10n.kcal,
                                  style: VType.subhead.copyWith(color: t.inkSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: VStatColumn(
                                icon: PhosphorIconsFill.barbell,
                                tint: t.sage,
                                value: '${((macros?.protein ?? 0) * iv(0.45, 0.75)).round()}g',
                                label: l10n.macroProtein,
                              ),
                            ),
                            Expanded(
                              child: VStatColumn(
                                icon: PhosphorIconsFill.lightning,
                                tint: t.gold,
                                value: '${((macros?.carbs ?? 0) * iv(0.55, 0.85)).round()}g',
                                label: l10n.macroCarbs,
                              ),
                            ),
                            Expanded(
                              child: VStatColumn(
                                icon: PhosphorIconsFill.drop,
                                tint: t.clay,
                                value: '${((macros?.fat ?? 0) * iv(0.65, 0.95)).round()}g',
                                label: l10n.macroFat,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (draft?.projectedDate != null) ...[
                const SizedBox(height: 12),
                Transform.translate(
                  offset: Offset(0, 24 * (1 - timeT)),
                  child: Opacity(opacity: timeT, child: _timelineCard(draft!)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _timelineCard(ClientIntakeDraft draft) {
    final t = context.tokens;
    final l10n = context.l10n;
    final losing = draft.targetWeight < draft.currentWeight;
    final monthYear = MaterialLocalizations.of(context).formatMonthYear(draft.projectedDate!);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        boxShadow: t.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: t.tintFill(t.good), shape: BoxShape.circle),
            child: Icon(
              losing ? noMirrorIcon(PhosphorIconsFill.trendDown) : noMirrorIcon(PhosphorIconsFill.trendUp),
              color: t.good,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.planGoalLabel,
                    style: VType.caption.copyWith(color: t.inkTertiary)),
                const SizedBox(height: 3),
                Text(
                  l10n.planReachBy(_weightLabel(draft.targetWeight), monthYear),
                  style: VType.headline.copyWith(color: t.ink),
                ),
              ],
            ),
          ),
        ],
      ),
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
