import 'dart:math' as math;
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
import 'package:valence/theme/app_theme.dart';
import 'package:valence/utils/units.dart';

/// The client personalization journey — a one-question-per-screen quiz (with an
/// inline metric/imperial unit choice on the body-measurement steps) → a build
/// moment → an animated plan reveal with an honest, deficit-derived timeline.
///
/// The emotional/benefit intro lives in the product carousel that precedes this
/// (see [OnboardingCarousel]); this screen is the personalization itself.
///
/// Runs in two modes:
///  • [newUser] = true  → reached from the carousel *before* an account exists.
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
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _analyze.dispose();
    _reveal.dispose();
    _pulse.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.intakeSaveError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final inQuestions = _step >= _kGoal && _step <= _kCommit;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 340,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondaryColor.withValues(alpha: 0.12),
                      AppColors.secondaryColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
                  child: inQuestions
                      ? _Header(
                          key: const ValueKey('progress'),
                          theme: theme,
                          step: _step - _kGoal,
                          total: _kQuestionCount,
                          onBack: _back,
                        )
                      : const SizedBox(key: ValueKey('blank'), height: 8, width: double.infinity),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _StepFade(key: const ValueKey(0), active: _step == _kGoal, child: _goalStep(theme)),
                      _StepFade(key: const ValueKey(1), active: _step == _kSex, child: _sexStep(theme)),
                      _StepFade(key: const ValueKey(2), active: _step == _kAge, child: _ageStep(theme)),
                      _StepFade(key: const ValueKey(3), active: _step == _kHeight, child: _heightStep(theme)),
                      _StepFade(key: const ValueKey(4), active: _step == _kWeight, child: _weightStep(theme)),
                      _StepFade(key: const ValueKey(5), active: _step == _kTarget, child: _targetStep(theme)),
                      _StepFade(key: const ValueKey(6), active: _step == _kActivity, child: _activityStep(theme)),
                      _StepFade(key: const ValueKey(7), active: _step == _kPrior, child: _priorStep(theme)),
                      _StepFade(key: const ValueKey(8), active: _step == _kCommit, child: _commitStep(theme)),
                      _analyzingStep(theme),
                      _resultStep(theme),
                    ],
                  ),
                ),
                _buildBottomBar(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    final l10n = context.l10n;
    if (_step == _kAge || _step == _kHeight || _step == _kWeight || _step == _kTarget) {
      return _bottomBar(theme, label: l10n.continueLabel, enabled: _canAdvance, onTap: _advance);
    }
    if (_step == _kCommit) {
      return _bottomBar(
        theme,
        label: l10n.onboardCommitCta,
        icon: PhosphorIconsFill.fire,
        enabled: true,
        onTap: _startAnalyzing,
      );
    }
    if (_step == _kResult) {
      return _bottomBar(
        theme,
        label: widget.newUser ? l10n.createAccountSavePlan : l10n.startTracking,
        icon: PhosphorIconsFill.check,
        enabled: _draft != null && !_saving,
        loading: _saving,
        onTap: _finish,
      );
    }
    return const SizedBox.shrink();
  }

  // -------------------------------------------------------------------------
  // Step scaffold (with a thematic emblem per screen)
  // -------------------------------------------------------------------------

  Widget _stepScaffold(
    ThemeData theme,
    String title,
    String subtitle,
    List<Widget> children, {
    IconData? insightIcon,
    String? insightText,
  }) {
    final textTheme = theme.textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.p24, AppSpacing.p20, AppSpacing.p24, AppSpacing.p16),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.15,
              ),
            ),
            SizedBox(height: AppSpacing.p8),
            Text(
              subtitle,
              style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.45),
            ),
            SizedBox(height: AppSpacing.p24),
            ...children,
            if (insightText != null) ...[
              SizedBox(height: AppSpacing.p20),
              _insightChip(theme, insightIcon ?? PhosphorIconsFill.sparkle, insightText),
            ],
          ],
        ),
      ),
    );
  }

  /// A subtle "gives something back" line — real evidence, a benefit, or
  /// reassurance — shown under a question so it never feels like a bare form.
  /// Styled as a quiet hint (no card), not a boxed surface.
  Widget _insightChip(ThemeData theme, IconData icon, String text) {
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 13, color: AppColors.secondaryColor.withValues(alpha: 0.9)),
          ),
          SizedBox(width: AppSpacing.p8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                height: 1.35,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Question steps
  // -------------------------------------------------------------------------

  Widget _goalStep(ThemeData theme) {
    return _stepScaffold(theme, context.l10n.intakeGoalTitle,
        context.l10n.intakeGoalSubtitle, [
      _bigOption(theme, context.l10n.goalLoseTitle, context.l10n.goalLoseSubtitle, PhosphorIconsFill.trendDown,
          selected: _goal == FitnessGoal.lose, onTap: () {
        setState(() => _goal = FitnessGoal.lose);
        _advance();
      }),
      _bigOption(theme, context.l10n.goalMaintainTitle, context.l10n.goalMaintainSubtitle, PhosphorIconsFill.equals,
          selected: _goal == FitnessGoal.maintain, onTap: () {
        setState(() => _goal = FitnessGoal.maintain);
        _advance();
      }),
      _bigOption(theme, context.l10n.goalGainTitle, context.l10n.goalGainSubtitle, PhosphorIconsFill.trendUp,
          selected: _goal == FitnessGoal.gain, onTap: () {
        setState(() => _goal = FitnessGoal.gain);
        _advance();
      }),
    ]);
  }

  Widget _sexStep(ThemeData theme) {
    return _stepScaffold(theme, context.l10n.intakeSexTitle,
        context.l10n.intakeSexSubtitle, [
      _bigOption(theme, context.l10n.sexMale, null, PhosphorIconsFill.genderMale,
          selected: _sex == BiologicalSex.male, onTap: () {
        setState(() => _sex = BiologicalSex.male);
        _advance();
      }),
      _bigOption(theme, context.l10n.sexFemale, null, PhosphorIconsFill.genderFemale,
          selected: _sex == BiologicalSex.female, onTap: () {
        setState(() => _sex = BiologicalSex.female);
        _advance();
      }),
    ]);
  }

  Widget _ageStep(ThemeData theme) {
    return _stepScaffold(theme, context.l10n.intakeAgeTitle, context.l10n.intakeAgeSubtitle, [
      _MetricInput(
        min: 13,
        max: 100,
        step: 1,
        initial: (_age ?? 25).toDouble(),
        unit: context.l10n.unitYears,
        decimals: 0,
        onChanged: (v) {
          _ageController.text = _fmtNum(v, 0);
          setState(() {});
        },
      ),
    ], insightIcon: PhosphorIconsFill.fire, insightText: context.l10n.intakeAgeInsight);
  }

  Widget _heightStep(ThemeData theme) {
    final l10n = context.l10n;
    final cm = _height ?? 170;
    return _stepScaffold(theme, l10n.intakeHeightTitle, l10n.intakeHeightSubtitle, [
      Center(child: _UnitToggle(metric: _metric, onChanged: _setMetric)),
      SizedBox(height: AppSpacing.p24),
      _MetricInput(
        key: ValueKey('height_$_metric'),
        min: _metric ? 120 : 47,
        max: _metric ? 230 : 91,
        step: 1,
        initial: _metric ? cm : cmToInches(cm),
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

  Widget _weightStep(ThemeData theme) {
    final l10n = context.l10n;
    final kg = _weight ?? 70;
    return _stepScaffold(theme, l10n.intakeWeightTitle, l10n.intakeWeightSubtitle, [
      Center(child: _UnitToggle(metric: _metric, onChanged: _setMetric)),
      SizedBox(height: AppSpacing.p24),
      _MetricInput(
        key: ValueKey('weight_$_metric'),
        min: _metric ? 30 : 66,
        max: _metric ? 250 : 550,
        step: _metric ? 0.5 : 1,
        initial: _metric ? kg : kgToLb(kg),
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

  Widget _targetStep(ThemeData theme) {
    final l10n = context.l10n;
    final currentKg = _weight ?? 70;
    final loKg = (currentKg - 40).clamp(30, 250).toDouble();
    final hiKg = (currentKg + 40).clamp(30, 250).toDouble();
    final tgtKg = _target ?? (currentKg - 2);
    return _stepScaffold(theme, l10n.intakeTargetTitle, l10n.intakeTargetSubtitle, [
      Center(child: _UnitToggle(metric: _metric, onChanged: _setMetric)),
      SizedBox(height: AppSpacing.p24),
      _MetricInput(
        key: ValueKey('target_${_metric}_$currentKg'),
        min: _metric ? loKg : kgToLb(loKg),
        max: _metric ? hiKg : kgToLb(hiKg),
        step: _metric ? 0.5 : 1,
        initial: _metric ? tgtKg : kgToLb(tgtKg),
        unit: _metric ? l10n.unitKg : l10n.unitLb,
        decimals: _metric ? 1 : 0,
        deltaFrom: _metric ? currentKg : kgToLb(currentKg),
        metric: _metric,
        onChanged: (v) {
          final canonical = _metric ? v : lbToKg(v);
          _targetController.text = _fmtNum(canonical, 1);
          setState(() {});
        },
      ),
    ], insightIcon: PhosphorIconsFill.trendDown, insightText: l10n.intakeTargetInsight);
  }

  Widget _activityStep(ThemeData theme) {
    return _stepScaffold(theme, context.l10n.intakeActivityTitle, context.l10n.intakeActivitySubtitle, [
      ...ActivityLevel.values.map((a) => _bigOption(
              theme, a.localizedLabel(context.l10n), a.localizedHint(context.l10n), PhosphorIconsFill.pulse,
              selected: _activity == a, onTap: () {
            setState(() => _activity = a);
            _advance();
          })),
    ], insightIcon: PhosphorIconsFill.pulse, insightText: context.l10n.intakeActivityInsight);
  }

  Widget _priorStep(ThemeData theme) {
    void pick(String key) {
      setState(() => _priorAnswer = key);
      _advance();
    }

    return _stepScaffold(theme, context.l10n.intakePriorTitle,
        context.l10n.intakePriorSubtitle, [
      _bigOption(theme, context.l10n.priorNever, null, PhosphorIconsFill.sparkle,
          selected: _priorAnswer == 'never', onTap: () => pick('never')),
      _bigOption(theme, context.l10n.priorStopped, null, PhosphorIconsFill.arrowsClockwise,
          selected: _priorAnswer == 'stopped', onTap: () => pick('stopped')),
      _bigOption(theme, context.l10n.priorCurrent, null, PhosphorIconsFill.checkCircle,
          selected: _priorAnswer == 'current', onTap: () => pick('current')),
    ]);
  }

  // -------------------------------------------------------------------------
  // Micro-commitment — a small "I'm in" beat before the plan is built
  // -------------------------------------------------------------------------

  Widget _commitStep(ThemeData theme) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.p32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.secondaryColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIconsFill.handshake, color: AppColors.secondaryColor, size: 40),
            ),
            SizedBox(height: AppSpacing.p24),
            Text(
              context.l10n.onboardCommitTitle,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            SizedBox(height: AppSpacing.p12),
            Text(
              context.l10n.onboardCommitSubtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build moment — the "working for you" beat
  // -------------------------------------------------------------------------

  Widget _analyzingStep(ThemeData theme) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final msgL10n = context.l10n;
    final messages = [
      msgL10n.intakeAnalyzing1,
      msgL10n.intakeAnalyzing2,
      msgL10n.intakeAnalyzing3,
      msgL10n.intakeAnalyzing4,
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: AnimatedBuilder(
          animation: Listenable.merge([_analyze, _pulse]),
          builder: (context, _) {
            final v = _analyze.value;
            final idx = (v * messages.length).floor().clamp(0, messages.length - 1);
            final glow = 0.25 + 0.25 * _pulse.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 132,
                  height: 132,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 132,
                        height: 132,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondaryColor.withValues(alpha: glow * 0.5),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 116,
                        height: 116,
                        child: CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 6,
                          valueColor: AlwaysStoppedAnimation(cs.surfaceContainerHighest),
                        ),
                      ),
                      SizedBox(
                        width: 116,
                        height: 116,
                        child: CircularProgressIndicator(
                          value: v,
                          strokeWidth: 6,
                          strokeCap: StrokeCap.round,
                          valueColor: const AlwaysStoppedAnimation(AppColors.secondaryColor),
                        ),
                      ),
                      Transform.rotate(
                        angle: v * math.pi * 2,
                        child: Transform.scale(
                          scale: 0.9 + 0.1 * _pulse.value,
                          child: const Icon(PhosphorIconsFill.sparkle,
                              color: AppColors.secondaryColor, size: 40),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.p24),
                Text(
                  context.l10n.intakeBuildingPlan.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    fontSize: 10,
                  ),
                ),
                SizedBox(height: AppSpacing.p8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (c, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(a),
                      child: c,
                    ),
                  ),
                  child: Text(
                    '${messages[idx]}…',
                    key: ValueKey(idx),
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
  // Plan reveal — animated, with an honest deficit-derived timeline
  // -------------------------------------------------------------------------

  Widget _resultStep(ThemeData theme) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final draft = _draft;
    final t = draft?.macros;
    final name = context.read<AuthProvider>().currentUser?.name.trim().split(' ').first ?? '';
    final cal = t?.calories ?? 0;

    double iv(double start, double end) =>
        CurvedAnimation(parent: _reveal, curve: Interval(start, end, curve: Curves.easeOutCubic)).value;

    return AnimatedBuilder(
      animation: Listenable.merge([_reveal, _pulse]),
      builder: (context, _) {
        final headT = iv(0.0, 0.40);
        final calT = iv(0.22, 0.68);
        final timeT = iv(0.6, 1.0);
        final glow = 0.18 + 0.16 * _pulse.value;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(AppSpacing.p24, AppSpacing.p20, AppSpacing.p24, AppSpacing.p20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Opacity(
                opacity: headT,
                child: Transform.scale(
                  scale: 0.7 + 0.3 * iv(0.0, 0.5),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryColor.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondaryColor.withValues(alpha: glow),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(PhosphorIconsFill.sparkle, color: AppColors.secondaryColor, size: 34),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.p16),
              Opacity(
                opacity: headT,
                child: Column(
                  children: [
                    Text(
                      name.isEmpty ? context.l10n.intakePlanReady : context.l10n.intakePlanReadyNamed(name),
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: AppSpacing.p4),
                    Text(
                      context.l10n.intakePlanSubtitle,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.p24),
              Transform.translate(
                offset: Offset(0, 24 * (1 - calT)),
                child: Opacity(
                  opacity: calT,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: _premiumCardDecoration(theme),
                    child: Column(
                      children: [
                        Text(
                          context.l10n.dailyCalories.toUpperCase(),
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.secondaryColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            fontSize: 10,
                          ),
                        ),
                        SizedBox(height: AppSpacing.p8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Icon(PhosphorIconsFill.fire, color: AppColors.secondaryColor, size: 26),
                            SizedBox(width: AppSpacing.p8),
                            Text(
                              '${(cal * calT).round()}',
                              style: textTheme.displayMedium?.copyWith(
                                color: AppColors.secondaryColor,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -2,
                                height: 1,
                              ),
                            ),
                            Text(
                              ' ${context.l10n.kcal}',
                              style: textTheme.titleMedium?.copyWith(
                                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.p20),
                        Row(
                          children: [
                            _macroPill(theme, context.l10n.macroProtein.toUpperCase(), t?.protein ?? 0,
                                cs.primaryContainer, cs.onPrimaryContainer, iv(0.45, 0.75)),
                            SizedBox(width: AppSpacing.p8),
                            _macroPill(theme, context.l10n.macroCarbs.toUpperCase(), t?.carbs ?? 0,
                                cs.secondaryContainer, cs.onSecondaryContainer, iv(0.55, 0.85)),
                            SizedBox(width: AppSpacing.p8),
                            _macroPill(theme, context.l10n.macroFat.toUpperCase(), t?.fat ?? 0,
                                cs.tertiaryContainer, cs.onTertiaryContainer, iv(0.65, 0.95)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (draft?.projectedDate != null) ...[
                SizedBox(height: AppSpacing.p12),
                Transform.translate(
                  offset: Offset(0, 24 * (1 - timeT)),
                  child: Opacity(
                    opacity: timeT,
                    child: _timelineCard(theme, draft!),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _timelineCard(ThemeData theme, ClientIntakeDraft draft) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final losing = draft.targetWeight < draft.currentWeight;
    final monthYear = MaterialLocalizations.of(context).formatMonthYear(draft.projectedDate!);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _premiumCardDecoration(theme),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.statusGreen.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              losing ? PhosphorIconsFill.trendDown : PhosphorIconsFill.trendUp,
              color: AppColors.statusGreen,
              size: 22,
            ),
          ),
          SizedBox(width: AppSpacing.p16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.planGoalLabel.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.planReachBy(_weightLabel(draft.targetWeight), monthYear),
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Shared pieces
  // -------------------------------------------------------------------------

  BoxDecoration _premiumCardDecoration(ThemeData theme) {
    final cs = theme.colorScheme;
    return BoxDecoration(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      boxShadow: [
        BoxShadow(
          color: theme.shadowColor.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: AppColors.secondaryColor.withValues(alpha: 0.06),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget _bigOption(
    ThemeData theme,
    String title,
    String? subtitle,
    IconData icon, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.secondaryColor.withValues(alpha: 0.12) : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.secondaryColor.withValues(alpha: 0.5)
                  : cs.outlineVariant.withValues(alpha: 0.3),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.secondaryColor.withValues(alpha: 0.18)
                      : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: selected ? AppColors.secondaryColor : cs.onSurfaceVariant),
              ),
              SizedBox(width: AppSpacing.p16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected ? AppColors.secondaryColor : cs.onSurface,
                      ),
                    ),
                    if (subtitle != null)
                      Text(subtitle, style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(
                selected ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.caretRight,
                size: selected ? 22 : 18,
                color: selected ? AppColors.secondaryColor : cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _macroPill(ThemeData theme, String label, int grams, Color chip, Color onChip, double t) {
    return Expanded(
      child: Transform.translate(
        offset: Offset(0, 16 * (1 - t)),
        child: Opacity(
          opacity: t,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: chip.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: onChip.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Text(
                  '${(grams * t).round()}g',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: onChip,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 8,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: onChip.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(
    ThemeData theme, {
    required String label,
    IconData? icon,
    required bool enabled,
    bool loading = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.p24,
        AppSpacing.p8,
        AppSpacing.p24,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.p16,
      ),
      child: _Pressable(
        onTap: (enabled && !loading) ? onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : 0.5,
          child: Container(
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondaryColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.secondaryColor.withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primaryColor),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: AppColors.primaryColor),
                        SizedBox(width: AppSpacing.p8),
                      ],
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Header — back chevron + segmented progress
// ===========================================================================

class _Header extends StatelessWidget {
  final ThemeData theme;
  final int step;
  final int total;
  final VoidCallback onBack;

  const _Header({super.key, required this.theme, required this.step, required this.total, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.p12, AppSpacing.p8, AppSpacing.p20, AppSpacing.p8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(PhosphorIconsBold.caretLeft, size: 20, color: cs.onSurface),
            splashRadius: 22,
          ),
          Expanded(
            child: Row(
              children: List.generate(total, (i) {
                final filled = i <= step;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                      height: 5,
                      decoration: BoxDecoration(
                        color: filled
                            ? AppColors.secondaryColor
                            : cs.surfaceContainerHighest.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ===========================================================================
// Metric / imperial segmented toggle
// ===========================================================================

class _UnitToggle extends StatelessWidget {
  final bool metric;
  final ValueChanged<bool> onChanged;

  const _UnitToggle({required this.metric, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(theme, l10n.unitsMetric, metric, () => onChanged(true)),
          _segment(theme, l10n.unitsImperial, !metric, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _segment(ThemeData theme, String label, bool selected, VoidCallback onTap) {
    final cs = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondaryColor.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: selected ? AppColors.secondaryColor : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Unified numeric input — one coherent control for age / height / weight /
// goal weight. Big value readout + gold slider + ± fine-tune. Optional delta
// badge (goal weight vs. current) and an optional display formatter (e.g. ft/in).
// ===========================================================================

class _MetricInput extends StatefulWidget {
  final double min;
  final double max;
  final double step;
  final double initial;
  final String unit;
  final int decimals;
  final double? deltaFrom;
  final bool metric;
  final String Function(double)? displayFormatter;
  final ValueChanged<double> onChanged;

  const _MetricInput({
    super.key,
    required this.min,
    required this.max,
    required this.step,
    required this.initial,
    required this.unit,
    required this.decimals,
    required this.onChanged,
    this.deltaFrom,
    this.metric = true,
    this.displayFormatter,
  });

  @override
  State<_MetricInput> createState() => _MetricInputState();
}

class _MetricInputState extends State<_MetricInput> {
  late double _value = _snap(widget.initial);

  double _snap(double v) {
    final clamped = v.clamp(widget.min, widget.max);
    final stepped = (clamped / widget.step).round() * widget.step;
    return stepped.clamp(widget.min, widget.max).toDouble();
  }

  void _set(double v) {
    final next = _snap(v);
    if (next == _value) return;
    HapticFeedback.selectionClick();
    setState(() => _value = next);
    widget.onChanged(_value);
  }

  String _fmt(double v) =>
      widget.decimals == 0 || v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  String _display(double v) => widget.displayFormatter?.call(v) ?? _fmt(v);

  String _hint(double v) {
    if (widget.displayFormatter != null) return widget.displayFormatter!(v);
    return '${_fmt(v)} ${widget.unit}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final showUnit = widget.displayFormatter == null && widget.unit.isNotEmpty;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _display(_value),
              style: textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
                color: cs.onSurface,
                height: 1,
              ),
            ),
            if (showUnit) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  widget.unit,
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (widget.deltaFrom != null) ...[
          SizedBox(height: AppSpacing.p16),
          _DeltaBadge(theme: theme, delta: _value - widget.deltaFrom!, unit: widget.unit, metric: widget.metric),
        ],
        SizedBox(height: AppSpacing.p32),
        Row(
          children: [
            _StepButton(icon: PhosphorIconsBold.minus, onTap: () => _set(_value - widget.step)),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 8,
                  activeTrackColor: AppColors.secondaryColor,
                  inactiveTrackColor: cs.surfaceContainerHighest,
                  thumbColor: AppColors.secondaryColor,
                  overlayColor: AppColors.secondaryColor.withValues(alpha: 0.15),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  value: _value,
                  min: widget.min,
                  max: widget.max,
                  divisions: ((widget.max - widget.min) / widget.step).round(),
                  onChanged: _set,
                ),
              ),
            ),
            _StepButton(icon: PhosphorIconsBold.plus, onTap: () => _set(_value + widget.step)),
          ],
        ),
        SizedBox(height: AppSpacing.p8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_hint(widget.min), style: _hintStyle(textTheme, cs)),
              Text(_hint(widget.max), style: _hintStyle(textTheme, cs)),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle? _hintStyle(TextTheme t, ColorScheme cs) =>
      t.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.55));
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _Pressable(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  final ThemeData theme;
  final double delta;
  final String unit;
  final bool metric;

  const _DeltaBadge({required this.theme, required this.delta, required this.unit, required this.metric});

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.textTheme;
    final maintain = delta.abs() < (metric ? 0.25 : 0.5);
    final losing = delta < 0;
    final color = losing ? AppColors.statusGreen : AppColors.secondaryColor;
    final l10n = context.l10n;
    final amount = delta.abs().toStringAsFixed(metric ? 1 : 0);
    final label = maintain
        ? l10n.deltaMaintain
        : (losing ? l10n.weightToLoseU(amount, unit) : l10n.weightToGainU(amount, unit));
    final icon = maintain
        ? PhosphorIconsFill.equals
        : losing
            ? PhosphorIconsFill.trendDown
            : PhosphorIconsFill.trendUp;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w800),
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
    duration: const Duration(milliseconds: 420),
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

// ===========================================================================
// Press-scale wrapper for tactile feedback
// ===========================================================================

class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Pressable({required this.child, required this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
