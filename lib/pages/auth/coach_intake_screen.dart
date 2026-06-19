import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:valence/l10n/enum_labels.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/models/enums.dart';
import 'package:valence/pages/coach/coach_persistant_tabs.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/theme/app_theme.dart';

/// Coach first-run onboarding. A few quick questions that build the coach's
/// profile and business context (specialties, experience, roster size, current
/// tooling) → a brief setup moment → a welcome reveal into the app.
class CoachIntakeScreen extends StatefulWidget {
  const CoachIntakeScreen({super.key});

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
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null || !_canFinish) return;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.coachIntakeSaveError)),
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
                      _StepFade(key: const ValueKey(0), active: _step == 0, child: _specialtiesStep(theme)),
                      _StepFade(key: const ValueKey(1), active: _step == 1, child: _experienceStep(theme)),
                      _StepFade(key: const ValueKey(2), active: _step == 2, child: _rosterStep(theme)),
                      _StepFade(key: const ValueKey(3), active: _step == 3, child: _priorStep(theme)),
                      _analyzingStep(theme),
                      _resultStep(theme),
                    ],
                  ),
                ),
                if (_step == 0)
                  _bottomBar(theme,
                      label: context.l10n.continueLabel, enabled: _specialties.isNotEmpty, onTap: _next)
                else if (_step == _result)
                  _bottomBar(theme,
                      label: context.l10n.enterValence,
                      icon: PhosphorIconsFill.arrowRight,
                      enabled: _canFinish,
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
  // Step scaffold
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

  Widget _specialtiesStep(ThemeData theme) {
    return _stepScaffold(theme, PhosphorIconsFill.barbell, context.l10n.ciSpecialtiesTitle,
        context.l10n.ciSpecialtiesSubtitle, [
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: CoachSpecialty.values.map((s) {
          final selected = _specialties.contains(s);
          return _chip(theme, s.localizedLabel(context.l10n), _specialtyIcons[s]!, selected: selected, onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              selected ? _specialties.remove(s) : _specialties.add(s);
            });
          });
        }).toList(),
      ),
    ]);
  }

  Widget _experienceStep(ThemeData theme) {
    const icons = {
      CoachExperience.justStarting: PhosphorIconsFill.sparkle,
      CoachExperience.oneToThree: PhosphorIconsFill.trendUp,
      CoachExperience.threeToFive: PhosphorIconsFill.medal,
      CoachExperience.fivePlus: PhosphorIconsFill.crown,
    };
    return _stepScaffold(theme, PhosphorIconsFill.medal, context.l10n.ciExperienceTitle,
        context.l10n.ciExperienceSubtitle, [
      ...CoachExperience.values.map((e) => _bigOption(theme, e.localizedLabel(context.l10n), e.localizedHint(context.l10n), icons[e]!,
              selected: _experience == e, onTap: () {
            setState(() => _experience = e);
            _next();
          })),
    ]);
  }

  Widget _rosterStep(ThemeData theme) {
    const icons = {
      RosterBand.solo: PhosphorIconsFill.user,
      RosterBand.small: PhosphorIconsFill.users,
      RosterBand.growing: PhosphorIconsFill.usersThree,
      RosterBand.established: PhosphorIconsFill.usersThree,
    };
    return _stepScaffold(theme, PhosphorIconsFill.usersThree, context.l10n.ciRosterTitle,
        context.l10n.ciRosterSubtitle, [
      ...RosterBand.values.map((r) => _bigOption(theme, r.localizedLabel(context.l10n), null, icons[r]!,
              selected: _roster == r, onTap: () {
            setState(() => _roster = r);
            _next();
          })),
    ]);
  }

  Widget _priorStep(ThemeData theme) {
    const icons = {
      CoachPriorTool.whatsapp: PhosphorIconsFill.chatCircle,
      CoachPriorTool.spreadsheets: PhosphorIconsFill.table,
      CoachPriorTool.otherApp: PhosphorIconsFill.deviceMobile,
      CoachPriorTool.penPaper: PhosphorIconsFill.pencilSimple,
      CoachPriorTool.mix: PhosphorIconsFill.stack,
    };
    return _stepScaffold(theme, PhosphorIconsFill.chatsCircle, context.l10n.ciPriorTitle,
        context.l10n.ciPriorSubtitle, [
      ...CoachPriorTool.values.map((t) => _bigOption(theme, t.localizedLabel(context.l10n), null, icons[t]!,
              selected: _prior == t, onTap: () {
            setState(() => _prior = t);
            _startAnalyzing();
          })),
    ]);
  }

  // -------------------------------------------------------------------------
  // Analyzing
  // -------------------------------------------------------------------------

  Widget _analyzingStep(ThemeData theme) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final msgL10n = context.l10n;
    final messages = [
      msgL10n.ciAnalyzing1,
      msgL10n.ciAnalyzing2,
      msgL10n.ciAnalyzing3,
      msgL10n.ciAnalyzing4,
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
                          child: const Icon(PhosphorIconsFill.barbell,
                              color: AppColors.secondaryColor, size: 38),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.p24),
                Text(
                  context.l10n.ciSettingUp.toUpperCase(),
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
  // Result — welcome reveal
  // -------------------------------------------------------------------------

  Widget _resultStep(ThemeData theme) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final name = context.read<AuthProvider>().currentUser?.name.trim().split(' ').first ?? '';

    double iv(double start, double end) =>
        CurvedAnimation(parent: _reveal, curve: Interval(start, end, curve: Curves.easeOutCubic)).value;

    return AnimatedBuilder(
      animation: Listenable.merge([_reveal, _pulse]),
      builder: (context, _) {
        final headT = iv(0.0, 0.45);
        final cardT = iv(0.25, 0.75);
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
                    child: const Icon(PhosphorIconsFill.confetti, color: AppColors.secondaryColor, size: 34),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.p16),
              Opacity(
                opacity: headT,
                child: Column(
                  children: [
                    Text(
                      name.isEmpty ? context.l10n.ciAllSet : context.l10n.ciWelcomeName(name),
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: AppSpacing.p4),
                    Text(
                      context.l10n.ciStudioReady,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.p24),
              Transform.translate(
                offset: Offset(0, 24 * (1 - cardT)),
                child: Opacity(
                  opacity: cardT,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.ciYourFocus.toUpperCase(),
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.secondaryColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            fontSize: 10,
                          ),
                        ),
                        SizedBox(height: AppSpacing.p12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _specialties.map((s) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: cs.secondaryContainer.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_specialtyIcons[s]!, size: 13, color: cs.onSecondaryContainer),
                                  const SizedBox(width: 6),
                                  Text(
                                    s.localizedLabel(context.l10n),
                                    style: textTheme.labelMedium?.copyWith(
                                      color: cs.onSecondaryContainer,
                                      fontWeight: FontWeight.w700,
                                    ),
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

  // -------------------------------------------------------------------------
  // Pieces
  // -------------------------------------------------------------------------

  Widget _chip(
    ThemeData theme,
    String label,
    IconData icon, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    return _Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondaryColor.withValues(alpha: 0.12) : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.secondaryColor.withValues(alpha: 0.5)
                : cs.outlineVariant.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? AppColors.secondaryColor : cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.secondaryColor : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
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
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (icon != null) ...[
                        SizedBox(width: AppSpacing.p8),
                        Icon(icon, size: 18, color: AppColors.primaryColor),
                      ],
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
// Per-step entrance + press-scale
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
