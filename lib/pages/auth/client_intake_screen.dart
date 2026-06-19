import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:valence/l10n/enum_labels.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/models/enums.dart';
import 'package:valence/models/target_macros.dart';
import 'package:valence/pages/client/client_persistant_tabs.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/theme/app_theme.dart';

/// Step-by-step first-run onboarding. One question per screen with a single,
/// coherent input language (premium option cards + one unified numeric input)
/// → an analyzing moment → an animated plan reveal with auto-calculated targets
/// (Mifflin-St Jeor BMR → activity TDEE → goal split).
class ClientIntakeScreen extends StatefulWidget {
  const ClientIntakeScreen({super.key});

  @override
  State<ClientIntakeScreen> createState() => _ClientIntakeScreenState();
}

class _ClientIntakeScreenState extends State<ClientIntakeScreen>
    with TickerProviderStateMixin {
  static const int _questions = 7;
  static const int _analyzing = 7;
  static const int _result = 8;

  final _pageController = PageController();
  final _firestoreService = FirestoreService();
  int _step = 0;
  bool _saving = false;

  FitnessGoal? _goal;
  BiologicalSex? _sex;
  ActivityLevel? _activity;
  final _ageController = TextEditingController(text: '25');
  final _heightController = TextEditingController(text: '170');
  final _weightController = TextEditingController(text: '70');
  final _targetController = TextEditingController(text: '68');

  late final AnimationController _analyze = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed && _step == _analyzing) _goToResult();
    });
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
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
      case 2:
        return _inRange(_age, 13, 100);
      case 3:
        return _inRange(_height, 120, 230);
      case 4:
        return _inRange(_weight, 30, 300);
      case 5:
        return _inRange(_target, 30, 300);
      default:
        return true;
    }
  }

  TargetMacros? get _targets {
    if (!_inRange(_age, 13, 100) ||
        !_inRange(_height, 120, 230) ||
        !_inRange(_weight, 30, 300) ||
        _sex == null ||
        _activity == null ||
        _goal == null) {
      return null;
    }
    final bmr = 10 * _weight! + 6.25 * _height! - 5 * _age! + (_sex == BiologicalSex.male ? 5 : -161);
    final tdee = bmr * _activity!.multiplier;
    final calories = switch (_goal!) {
      FitnessGoal.lose => tdee * 0.80,
      FitnessGoal.maintain => tdee,
      FitnessGoal.gain => tdee * 1.10,
    };
    final protein = (1.8 * _weight!).round();
    final fat = ((calories * 0.25) / 9).round();
    final carbs = ((calories - protein * 4 - fat * 9) / 4).round().clamp(0, 100000);
    return TargetMacros(calories: calories.round(), protein: protein, carbs: carbs, fat: fat);
  }

  String _fmtNum(double v, int decimals) {
    if (decimals == 0 || v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(1);
  }

  void _goTo(int step) => _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );

  void _next() {
    FocusScope.of(context).unfocus();
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
    final targets = _targets;
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (targets == null || user == null || _saving) return;

    setState(() => _saving = true);
    try {
      await _firestoreService.saveClientIntake(
        user.uid,
        age: _age!,
        heightCm: _height!,
        currentWeight: _weight!,
        targetWeight: _target!,
        sex: _sex!.name,
        activityLevel: _activity!.name,
        goal: _goal!.name,
        macros: targets,
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
    final showHeader = _step < _questions;

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
                  child: showHeader
                      ? _Header(theme: theme, step: _step, total: _questions, onBack: _back)
                      : const SizedBox(height: 8, width: double.infinity),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _StepFade(key: const ValueKey(0), active: _step == 0, child: _goalStep(theme)),
                      _StepFade(key: const ValueKey(1), active: _step == 1, child: _sexStep(theme)),
                      _StepFade(key: const ValueKey(2), active: _step == 2, child: _ageStep(theme)),
                      _StepFade(key: const ValueKey(3), active: _step == 3, child: _heightStep(theme)),
                      _StepFade(key: const ValueKey(4), active: _step == 4, child: _weightStep(theme)),
                      _StepFade(key: const ValueKey(5), active: _step == 5, child: _targetStep(theme)),
                      _StepFade(key: const ValueKey(6), active: _step == 6, child: _activityStep(theme)),
                      _analyzingStep(theme),
                      _resultStep(theme),
                    ],
                  ),
                ),
                if (_step >= 2 && _step <= 5)
                  _bottomBar(theme, label: context.l10n.continueLabel, enabled: _canAdvance, onTap: _next)
                else if (_step == _result)
                  _bottomBar(theme,
                      label: context.l10n.startTracking,
                      icon: PhosphorIconsFill.check,
                      enabled: _targets != null && !_saving,
                      loading: _saving,
                      onTap: _finish),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Step scaffold (with a thematic emblem per screen)
  // -------------------------------------------------------------------------

  Widget _stepScaffold(
    ThemeData theme,
    IconData emblem,
    String title,
    String subtitle,
    List<Widget> children,
  ) {
    final textTheme = theme.textTheme;
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.secondaryColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(emblem, color: AppColors.secondaryColor, size: 24),
        ),
        SizedBox(height: AppSpacing.p16),
        Text(
          title,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.15,
          ),
        ),
        SizedBox(height: AppSpacing.p8),
        Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
        ),
        SizedBox(height: AppSpacing.p24),
      ],
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.p24, AppSpacing.p16, AppSpacing.p24, AppSpacing.p16),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [header, ...children],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Steps
  // -------------------------------------------------------------------------

  Widget _goalStep(ThemeData theme) {
    return _stepScaffold(theme, PhosphorIconsFill.flagBanner, context.l10n.intakeGoalTitle,
        context.l10n.intakeGoalSubtitle, [
      _bigOption(theme, context.l10n.goalLoseTitle, context.l10n.goalLoseSubtitle, PhosphorIconsFill.trendDown,
          selected: _goal == FitnessGoal.lose, onTap: () {
        setState(() => _goal = FitnessGoal.lose);
        _next();
      }),
      _bigOption(theme, context.l10n.goalMaintainTitle, context.l10n.goalMaintainSubtitle, PhosphorIconsFill.equals,
          selected: _goal == FitnessGoal.maintain, onTap: () {
        setState(() => _goal = FitnessGoal.maintain);
        _next();
      }),
      _bigOption(theme, context.l10n.goalGainTitle, context.l10n.goalGainSubtitle, PhosphorIconsFill.trendUp,
          selected: _goal == FitnessGoal.gain, onTap: () {
        setState(() => _goal = FitnessGoal.gain);
        _next();
      }),
    ]);
  }

  Widget _sexStep(ThemeData theme) {
    return _stepScaffold(theme, PhosphorIconsFill.user, context.l10n.intakeSexTitle,
        context.l10n.intakeSexSubtitle, [
      _bigOption(theme, context.l10n.sexMale, null, PhosphorIconsFill.genderMale,
          selected: _sex == BiologicalSex.male, onTap: () {
        setState(() => _sex = BiologicalSex.male);
        _next();
      }),
      _bigOption(theme, context.l10n.sexFemale, null, PhosphorIconsFill.genderFemale,
          selected: _sex == BiologicalSex.female, onTap: () {
        setState(() => _sex = BiologicalSex.female);
        _next();
      }),
    ]);
  }

  Widget _ageStep(ThemeData theme) {
    return _stepScaffold(theme, PhosphorIconsFill.calendarBlank, context.l10n.intakeAgeTitle,
        context.l10n.intakeAgeSubtitle, [
      SizedBox(height: AppSpacing.p8),
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
    ]);
  }

  Widget _heightStep(ThemeData theme) {
    return _stepScaffold(theme, PhosphorIconsFill.ruler, context.l10n.intakeHeightTitle,
        context.l10n.intakeHeightSubtitle, [
      SizedBox(height: AppSpacing.p8),
      _MetricInput(
        min: 120,
        max: 230,
        step: 1,
        initial: _height ?? 170,
        unit: context.l10n.unitCm,
        decimals: 0,
        onChanged: (v) {
          _heightController.text = _fmtNum(v, 0);
          setState(() {});
        },
      ),
    ]);
  }

  Widget _weightStep(ThemeData theme) {
    return _stepScaffold(theme, PhosphorIconsFill.scales, context.l10n.intakeWeightTitle,
        context.l10n.intakeWeightSubtitle, [
      SizedBox(height: AppSpacing.p8),
      _MetricInput(
        min: 30,
        max: 250,
        step: 0.5,
        initial: _weight ?? 70,
        unit: context.l10n.unitKg,
        decimals: 1,
        onChanged: (v) {
          _weightController.text = _fmtNum(v, 1);
          setState(() {});
        },
      ),
    ]);
  }

  Widget _targetStep(ThemeData theme) {
    final current = _weight ?? 70;
    return _stepScaffold(theme, PhosphorIconsFill.target, context.l10n.intakeTargetTitle,
        context.l10n.intakeTargetSubtitle, [
      SizedBox(height: AppSpacing.p8),
      _MetricInput(
        key: ValueKey('target_$current'),
        min: (current - 40).clamp(30, 250).toDouble(),
        max: (current + 40).clamp(30, 250).toDouble(),
        step: 0.5,
        initial: _target ?? (current - 2),
        unit: context.l10n.unitKg,
        decimals: 1,
        deltaFrom: current,
        onChanged: (v) {
          _targetController.text = _fmtNum(v, 1);
          setState(() {});
        },
      ),
    ]);
  }

  Widget _activityStep(ThemeData theme) {
    return _stepScaffold(theme, PhosphorIconsFill.pulse, context.l10n.intakeActivityTitle,
        context.l10n.intakeActivitySubtitle, [
      ...ActivityLevel.values.map((a) => _bigOption(theme, a.localizedLabel(context.l10n), a.localizedHint(context.l10n), PhosphorIconsFill.pulse,
              selected: _activity == a, onTap: () {
            setState(() => _activity = a);
            _startAnalyzing();
          })),
    ]);
  }

  // -------------------------------------------------------------------------
  // Analyzing — the "working for you" moment
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
  // Plan reveal — animated
  // -------------------------------------------------------------------------

  Widget _resultStep(ThemeData theme) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final t = _targets;
    final name = context.read<AuthProvider>().currentUser?.name.trim().split(' ').first ?? '';
    final cal = t?.calories ?? 0;

    double iv(double start, double end) =>
        CurvedAnimation(parent: _reveal, curve: Interval(start, end, curve: Curves.easeOutCubic)).value;

    return AnimatedBuilder(
      animation: Listenable.merge([_reveal, _pulse]),
      builder: (context, _) {
        final headT = iv(0.0, 0.45);
        final calT = iv(0.25, 0.75);
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
                    decoration: BoxDecoration(
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
                    ),
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
                                cs.primaryContainer, cs.onPrimaryContainer, iv(0.5, 0.8)),
                            SizedBox(width: AppSpacing.p8),
                            _macroPill(theme, context.l10n.macroCarbs.toUpperCase(), t?.carbs ?? 0,
                                cs.secondaryContainer, cs.onSecondaryContainer, iv(0.62, 0.92)),
                            SizedBox(width: AppSpacing.p8),
                            _macroPill(theme, context.l10n.macroFat.toUpperCase(), t?.fat ?? 0,
                                cs.tertiaryContainer, cs.onTertiaryContainer, iv(0.74, 1.0)),
                          ],
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

  // -------------------------------------------------------------------------
  // Pieces
  // -------------------------------------------------------------------------

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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.secondaryColor.withValues(alpha: 0.18)
                      : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 22, color: selected ? AppColors.secondaryColor : cs.onSurfaceVariant),
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

  const _Header({required this.theme, required this.step, required this.total, required this.onBack});

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
// Unified numeric input — one coherent control for age / height / weight /
// goal weight. Big value readout + gold slider + ± fine-tune. Optional delta
// badge (goal weight vs. current).
// ===========================================================================

class _MetricInput extends StatefulWidget {
  final double min;
  final double max;
  final double step;
  final double initial;
  final String unit;
  final int decimals;
  final double? deltaFrom;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _fmt(_value),
              style: textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
                color: cs.onSurface,
                height: 1,
              ),
            ),
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
        ),
        if (widget.deltaFrom != null) ...[
          SizedBox(height: AppSpacing.p16),
          _DeltaBadge(theme: theme, delta: _value - widget.deltaFrom!),
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
              Text('${_fmt(widget.min)} ${widget.unit}', style: _hintStyle(textTheme, cs)),
              Text('${_fmt(widget.max)} ${widget.unit}', style: _hintStyle(textTheme, cs)),
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

  const _DeltaBadge({required this.theme, required this.delta});

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.textTheme;
    final maintain = delta.abs() < 0.25;
    final losing = delta < 0;
    final color = losing ? AppColors.statusGreen : AppColors.secondaryColor;
    final l10n = context.l10n;
    final label = maintain
        ? l10n.deltaMaintain
        : (losing
            ? l10n.weightToLose(delta.abs().toStringAsFixed(1))
            : l10n.weightToGain(delta.abs().toStringAsFixed(1)));
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
