import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../l10n/l10n_ext.dart';
import '../../theme/app_theme.dart';

/// Which slice of the real product a slide previews. The hero shows an actual
/// Valence-style mock (like top apps do) instead of a generic glyph.
enum OnboardingPreview {
  coachRoster,
  coachWorkout,
  coachPulse,
  clientNutrition,
  clientHabits,
  clientNote,
}

class OnboardingSlide {
  final OnboardingPreview preview;
  final String title;
  final String body;
  const OnboardingSlide({
    required this.preview,
    required this.title,
    required this.body,
  });
}

/// A reusable, premium first-run carousel. Both the coach and client
/// "get started" screens delegate to this with role-specific [slides].
class OnboardingCarousel extends StatefulWidget {
  final List<OnboardingSlide> slides;
  final String finishLabel;
  final VoidCallback onFinish;

  const OnboardingCarousel({
    super.key,
    required this.slides,
    required this.onFinish,
    this.finishLabel = 'Get started',
  });

  @override
  State<OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends State<OnboardingCarousel>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _page = 0;

  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat();

  @override
  void dispose() {
    _float.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLast => _page == widget.slides.length - 1;

  void _next() {
    HapticFeedback.selectionClick();
    if (_isLast) {
      widget.onFinish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // Very soft top wash — restraint, not a halo.
          Positioned(
            top: -160,
            left: -40,
            right: -40,
            child: IgnorePointer(
              child: Container(
                height: 380,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondaryColor.withValues(alpha: 0.08),
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
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      AppSpacing.p20, AppSpacing.p8, AppSpacing.p12, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: SvgPicture.asset(
                          'assets/logo/valence_logo.svg',
                          colorFilter: const ColorFilter.mode(
                              AppColors.secondaryColor, BlendMode.srcIn),
                          fit: BoxFit.contain,
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onFinish,
                        child: Text(
                          context.l10n.skip,
                          style: textTheme.labelLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.slides.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, index) {
                      final slide = widget.slides[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.p24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _PreviewStage(preview: slide.preview, anim: _float),
                            SizedBox(height: AppSpacing.p32 + 4),
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                                height: 1.1,
                              ),
                            ),
                            SizedBox(height: AppSpacing.p12),
                            Text(
                              slide.body,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.slides.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: active ? 26 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: active
                            ? AppColors.secondaryColor
                            : cs.onSurface.withValues(alpha: 0.18),
                      ),
                    );
                  }),
                ),
                SizedBox(height: AppSpacing.p24),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      AppSpacing.p24, 0, AppSpacing.p24, AppSpacing.p20),
                  child: _PrimaryButton(
                    label: _isLast ? widget.finishLabel : context.l10n.next,
                    icon: _isLast ? PhosphorIconsFill.arrowRight : null,
                    onTap: _next,
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

// ===========================================================================
// Preview stage — floats a real-looking product card with a neutral shadow.
// ===========================================================================

class _PreviewStage extends StatelessWidget {
  final OnboardingPreview preview;
  final Animation<double> anim;

  const _PreviewStage({required this.preview, required this.anim});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: AnimatedBuilder(
          animation: anim,
          builder: (context, child) {
            final dy = math.sin(anim.value * 2 * math.pi) * 4;
            return Transform.translate(offset: Offset(0, dy), child: child);
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: _previewFor(preview),
          ),
        ),
      ),
    );
  }

  Widget _previewFor(OnboardingPreview p) {
    switch (p) {
      case OnboardingPreview.coachRoster:
        return const _RosterPreview();
      case OnboardingPreview.coachWorkout:
        return const _WorkoutPreview();
      case OnboardingPreview.coachPulse:
        return const _PulsePreview();
      case OnboardingPreview.clientNutrition:
        return const _NutritionPreview();
      case OnboardingPreview.clientHabits:
        return const _HabitsPreview();
      case OnboardingPreview.clientNote:
        return const _NotePreview();
    }
  }
}

// ---------------------------------------------------------------------------
// Shared mock building blocks
// ---------------------------------------------------------------------------

Widget _previewCard(BuildContext context, {required Widget child}) {
  final cs = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      boxShadow: [
        BoxShadow(
          color: cs.shadow.withValues(alpha: 0.10),
          blurRadius: 30,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: child,
  );
}

Widget _trackedLabel(BuildContext context, String text) {
  final theme = Theme.of(context);
  return Text(
    text,
    style: theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      fontWeight: FontWeight.w800,
      letterSpacing: 1.4,
      fontSize: 9.5,
    ),
  );
}

Widget _statusPill(BuildContext context, String label, Color color) {
  final theme = Theme.of(context);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
      ],
    ),
  );
}

Widget _avatar(BuildContext context, String initial, Color color) {
  final cs = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, color.withValues(alpha: 0.25)],
      ),
    ),
    child: CircleAvatar(
      radius: 16,
      backgroundColor: cs.surface,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Coach: roster
// ---------------------------------------------------------------------------

// Real adherence chip (mirrors clients_screen `_DayMetric`): gradient container
// + icon + big w900 % + label.
Widget _adherenceChip(BuildContext context, IconData icon, String label, int pct,
    Color color, Color onColor) {
  return Container(
    padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: 0.62), color.withValues(alpha: 0.4)],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: onColor.withValues(alpha: 0.1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Icon(icon, size: 12, color: onColor.withValues(alpha: 0.85)),
            const Spacer(),
            Text('$pct',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: onColor,
                    height: 1,
                    letterSpacing: -0.6)),
            Text('%',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: onColor.withValues(alpha: 0.6),
                    height: 1)),
          ],
        ),
        const SizedBox(height: 8),
        Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: onColor.withValues(alpha: 0.75),
                letterSpacing: 0.4)),
      ],
    ),
  );
}

class _RosterPreview extends StatelessWidget {
  const _RosterPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return _previewCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _avatar(context, 'S', AppColors.statusGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sara',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text('7-day streak',
                        style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              _statusPill(context, 'Good', AppColors.statusGreen),
            ],
          ),
          const SizedBox(height: 16),
          _trackedLabel(context, 'LAST 7 DAYS'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _adherenceChip(context, PhosphorIconsFill.forkKnife, 'Food', 95, cs.primaryContainer, cs.onPrimaryContainer)),
              const SizedBox(width: 8),
              Expanded(child: _adherenceChip(context, PhosphorIconsFill.heartbeat, 'Habits', 80, cs.secondaryContainer, cs.onSecondaryContainer)),
              const SizedBox(width: 8),
              Expanded(child: _adherenceChip(context, PhosphorIconsFill.barbell, 'Training', 100, cs.tertiaryContainer, cs.onTertiaryContainer)),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Coach: workout program
// ---------------------------------------------------------------------------

class _WorkoutPreview extends StatelessWidget {
  const _WorkoutPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return _previewCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(PhosphorIconsFill.barbell, size: 18, color: AppColors.secondaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Push Day',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ),
              _statusPill(context, '2/3 done', AppColors.statusGreen),
            ],
          ),
          const SizedBox(height: 16),
          _ex(context, cs, 'Bench Press', '4 × 8', true),
          _ex(context, cs, 'Incline DB Press', '3 × 10', true),
          _ex(context, cs, 'Cable Fly', '3 × 12', false),
        ],
      ),
    );
  }

  Widget _ex(BuildContext context, ColorScheme cs, String name, String scheme, bool done) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          if (done)
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                  color: AppColors.statusGreen, shape: BoxShape.circle),
              child: const Icon(PhosphorIconsBold.check, size: 11, color: Colors.white),
            )
          else
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6), width: 2),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Text(scheme,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Coach: roster pulse / growth
// ---------------------------------------------------------------------------

Widget _legendDot(BuildContext context, Color color, String label) {
  final theme = Theme.of(context);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label,
          style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
    ],
  );
}

class _PulsePreview extends StatelessWidget {
  const _PulsePreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    // Mirrors clients_screen `_RosterPulse`: gold-wash card, health label +
    // "needs you", a segmented status bar, and a legend.
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondaryColor.withValues(alpha: 0.08),
            AppColors.secondaryColor.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _trackedLabel(context, 'ROSTER HEALTH'),
              const Spacer(),
              Text('1 needs you',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.statusRed, fontWeight: FontWeight.w800)),
              const SizedBox(width: 3),
              const Icon(PhosphorIconsBold.arrowRight, size: 12, color: AppColors.statusRed),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(flex: 19, child: Container(color: AppColors.statusGreen)),
                  const SizedBox(width: 3),
                  Expanded(flex: 4, child: Container(color: AppColors.statusYellow)),
                  const SizedBox(width: 3),
                  Expanded(flex: 1, child: Container(color: AppColors.statusRed)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _legendDot(context, AppColors.statusGreen, '19 Good'),
              const SizedBox(width: 16),
              _legendDot(context, AppColors.statusYellow, '4 Watch'),
              const SizedBox(width: 16),
              _legendDot(context, AppColors.statusRed, '1 Alert'),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Client: nutrition dashboard
// ---------------------------------------------------------------------------

// Real macro column (mirrors client_home `_buildMacroColumn`): chip + icon/label
// + big value /target + mini progress bar.
Widget _macroColumn(BuildContext context, String label, IconData icon, int current,
    int target, Color chip, Color onChip) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final progress = (current / target).clamp(0.0, 1.0);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
    decoration: BoxDecoration(
      color: chip.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: onChip.withValues(alpha: 0.1)),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: onChip.withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: onChip.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      fontSize: 9)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$current',
                  style: theme.textTheme.titleLarge?.copyWith(
                      color: onChip,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      height: 1)),
              Text(' /${target}g',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4), fontSize: 10)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 5,
            child: Stack(
              children: [
                Container(width: double.infinity, color: chip.withValues(alpha: 0.4)),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [onChip.withValues(alpha: 0.55), onChip]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _NutritionPreview extends StatelessWidget {
  const _NutritionPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return _previewCard(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Icon(PhosphorIconsFill.fire, size: 22, color: AppColors.secondaryColor),
              const SizedBox(width: 8),
              Text('1,820',
                  style: theme.textTheme.displaySmall?.copyWith(
                      color: AppColors.secondaryColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                      height: 1)),
              Text(' / 2,100 kcal',
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w400)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 12,
              child: Stack(
                children: [
                  Container(
                      width: double.infinity,
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.55)),
                  FractionallySizedBox(
                    widthFactor: 0.86,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Color(0xA6C6A87C), AppColors.secondaryColor]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _macroColumn(context, 'PROTEIN', PhosphorIconsBold.barbell, 148, 150, cs.primaryContainer, cs.onPrimaryContainer)),
              const SizedBox(width: 10),
              Expanded(child: _macroColumn(context, 'CARBS', PhosphorIconsFill.lightning, 180, 210, cs.secondaryContainer, cs.onSecondaryContainer)),
              const SizedBox(width: 10),
              Expanded(child: _macroColumn(context, 'FAT', PhosphorIconsFill.drop, 52, 60, cs.tertiaryContainer, cs.onTertiaryContainer)),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Client: daily habits
// ---------------------------------------------------------------------------

class _HabitsPreview extends StatelessWidget {
  const _HabitsPreview();

  @override
  Widget build(BuildContext context) {
    return _previewCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _trackedLabel(context, 'YOUR HABITS')),
              _statusPill(context, '2/3', AppColors.secondaryColor),
            ],
          ),
          const SizedBox(height: 14),
          _habit(context, PhosphorIconsFill.drop, 'Water · 3L', true),
          _habit(context, PhosphorIconsFill.footprints, '10,000 steps', true),
          _habit(context, PhosphorIconsFill.prohibit, 'No sugar after 8pm', false),
        ],
      ),
    );
  }

  Widget _habit(BuildContext context, IconData icon, String name, bool done) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: done
                  ? AppColors.secondaryColor.withValues(alpha: 0.16)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: done ? AppColors.secondaryColor : cs.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: done ? cs.onSurfaceVariant : cs.onSurface,
                decoration: done ? TextDecoration.lineThrough : null,
                decorationColor: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: done ? AppColors.secondaryColor : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: done ? AppColors.secondaryColor : cs.outlineVariant.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
            child: done
                ? const Icon(PhosphorIconsBold.check, size: 13, color: AppColors.primaryColor)
                : null,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Client: coach note
// ---------------------------------------------------------------------------

class _NotePreview extends StatelessWidget {
  const _NotePreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return _previewCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _avatar(context, 'C', AppColors.secondaryColor),
              const SizedBox(width: 10),
              Expanded(child: _trackedLabel(context, 'NOTE FROM YOUR COACH')),
              _statusPill(context, '8-day streak', AppColors.secondaryColor),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Text(
              "Strong week, Sara. Your protein's bang on — let's add one more walk this weekend and you're golden.",
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45, color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Primary CTA
// ---------------------------------------------------------------------------

class _PrimaryButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, this.icon, required this.onTap});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.secondaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (widget.icon != null) ...[
                SizedBox(width: AppSpacing.p8),
                Icon(widget.icon, size: 18, color: AppColors.primaryColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
