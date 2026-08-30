import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/daily_log_model.dart';
import '../../models/enums.dart';
import '../../models/habit_model.dart';
import '../../models/meal_model.dart';
import '../../models/target_macros.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../ui/ui.dart';
import '../../utils/day_rollover.dart';
import '../../utils/macro_status.dart';
import '../../utils/units.dart';
import '../../l10n/l10n_ext.dart';
import 'log_meal_screen.dart';
import 'share_win_screen.dart';

/// The client "Today" dashboard — Archetype A (design.md §4-A / §5.6). Flat warm
/// canvas, editorial greeting, one count-up hero, naked data, borderless cards.
///
/// LAYOUT IS LOCKED (Yassine's rule): greeting → week strip → coach note →
/// nutrition (hero + macros + Log Meal) → meals → water/weight/sleep → custom
/// habits → daily-win share. This file only re-clothes that IA in V-components;
/// the logic, streams and service calls are unchanged.
///
/// Data flow: everything renders from ONE StreamBuilder on the selected day's
/// DailyLog. Writes go through FirestoreService (which refreshes the adherence
/// status) and the stream re-emits — so most actions don't setState for data,
/// only for local UI state (water/sleep keep a local copy for instant feedback
/// on today). Past days are read-only: `isViewingToday` gates every mutation.
class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen>
    with WidgetsBindingObserver, DayRolloverMixin {

  // Local copies of today's steppers for instant tap feedback; the stream
  // remains the source of truth for any other day.
  int _waterLiters = 0;
  int _sleepRating = 0;

  // Calendar reaches ~three weeks back, read-only. Built newest-first and shown
  // in a reversed strip, so today is always pinned at the trailing edge and
  // visible on open — no scroll offset to manage, and scrolling back to older
  // days never yanks the user forward on a stream re-emit.
  static const int _calendarDays = 21;

  final _clientNoteController = TextEditingController();
  final _firestoreService = FirestoreService();
  DateTime _selectedDate = startOfDay(DateTime.now());

  @override
  void initState() {
    super.initState();
    startDayRollover();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLog());
  }

  @override
  void dispose() {
    stopDayRollover();
    _clientNoteController.dispose();
    super.dispose();
  }

  @override
  bool get isViewingToday => _isSameDay(_selectedDate, today);

  /// Midnight passed. A client sitting on today follows the clock onto the new
  /// day — with the local stepper copies cleared, or they'd show yesterday's
  /// water against an empty document. A client reading an older day stays put.
  @override
  void onDayRolled({required bool wasViewingToday}) {
    if (!wasViewingToday) return;
    setState(() {
      _selectedDate = today;
      _waterLiters = 0;
      _sleepRating = 0;
    });
    _initLog();
  }

  /// Ensures today's log doc exists (created lazily on first open) and seeds
  /// the local water/sleep values from it.
  Future<void> _initLog() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    if ((user.coachId ?? '').trim().isEmpty) return;
    try {
      final log = await _firestoreService.getOrCreateTodayLog(
        user.uid,
        user.coachId ?? '',
      );
      if (mounted) {
        setState(() {
          _waterLiters = (log.waterLiters ?? 0).round();
          _sleepRating = log.sleepRating ?? 0;
        });
      }
    } catch (_) {}
  }

  DateTime _normalizedDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Cache the daily-log stream so rebuilds (keyboard, theme, etc.) reuse it
  // instead of restarting and flashing the dashboard.
  String? _logUid;
  DateTime? _logDate;
  Stream<DailyLog?>? _logStream;
  Stream<DailyLog?> _logStreamFor(String uid, DateTime date) {
    if (_logStream == null || _logUid != uid || !_isSameDay(_logDate!, date)) {
      _logUid = uid;
      _logDate = date;
      _logStream = _firestoreService.streamLogForDateNullable(uid, date);
    }
    return _logStream!;
  }

  String get _uid => context.read<AuthProvider>().currentUser!.uid;
  String get _coachId =>
      context.read<AuthProvider>().currentUser?.coachId ?? '';

  // ==========================================================================
  //  BUILD
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final user = context.watch<AuthProvider>().currentUser!;
    final targets = user.targetMacros ?? const TargetMacros();
    final firstName = user.name.split(' ').first;

    return Scaffold(
      backgroundColor: t.canvas,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<DailyLog?>(
          stream: _logStreamFor(user.uid, _selectedDate),
          builder: (context, snapshot) {
            final log = snapshot.data;
            final isViewingToday = _isSameDay(_selectedDate, today);
            final waterLiters = isViewingToday
                ? _waterLiters
                : (log?.waterLiters ?? 0).round();
            final sleepRating =
                isViewingToday ? _sleepRating : (log?.sleepRating ?? 0);

            return ListView(
              padding: const EdgeInsetsDirectional.only(
                start: VSpace.screenMargin,
                end: VSpace.screenMargin,
                top: 8,
                bottom: VSpace.scrollBottom + 72,
              ),
              children: [
                _greetingHeader(firstName, user.currentStreak ?? 0),
                const SizedBox(height: 20),
                _calendarStrip(),
                if (!isViewingToday) ...[
                  const SizedBox(height: 16),
                  _pastDayIndicator(),
                ],
                const SizedBox(height: VSpace.sectionGap),

                if ((log?.coachNote ?? '').isNotEmpty) ...[
                  VCallout(
                    author: context.l10n.badgeCoach,
                    body: log!.coachNote!,
                  ),
                  const SizedBox(height: VSpace.sectionGap),
                ],

                _nutritionSection(
                  currentCals: log?.totalCalories ?? 0,
                  currentProtein: log?.totalProtein.toInt() ?? 0,
                  currentCarbs: log?.totalCarbs.toInt() ?? 0,
                  currentFat: log?.totalFat.toInt() ?? 0,
                  targets: targets,
                  isViewingToday: isViewingToday,
                ),

                if ((log?.meals ?? const []).isNotEmpty) ...[
                  const SizedBox(height: VSpace.sectionGap),
                  _mealsSection(log!.meals, canEdit: isViewingToday),
                ],

                const SizedBox(height: VSpace.sectionGap),
                _sectionHead(context.l10n.dailyHabits),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _waterCard(waterLiters, isViewingToday)),
                      const SizedBox(width: VSpace.cardGap),
                      Expanded(child: _weightCard(log?.weightKg, isViewingToday)),
                    ],
                  ),
                ),
                const SizedBox(height: VSpace.cardGap),
                _sleepCard(sleepRating, isViewingToday),

                _customHabits(
                  log?.habitChecks ?? const <String, bool>{},
                  isViewingToday,
                ),

                const SizedBox(height: VSpace.sectionGap),
                Center(
                  child: VTextAction(
                    icon: PhosphorIconsBold.shareNetwork,
                    label: context.l10n.shareWinCta,
                    onTap: () => _openShareWin(user),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==========================================================================
  //  GREETING HEADER — editorial serif greeting + quiet streak + note chip
  // ==========================================================================
  Widget _greetingHeader(String firstName, int streak) {
    final t = context.tokens;

    // One nav-style row: brand mark + greeting on the left, streak + note chip
    // on the right. "Hi," is ink, the client's name is the brand gold.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: SvgPicture.asset(
            'assets/logo/valence_logo.svg',
            colorFilter: ColorFilter.mode(t.gold, BlendMode.srcIn),
            fit: BoxFit.contain,
            semanticsLabel: 'Valence',
          ),
        ),
        const SizedBox(width: 10),
        // Greeting hugs the left; the Expanded's slack leaves the centre empty
        // and pushes the streak + note chip to the far right.
        Expanded(
          child: VTextScaleCap(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${context.l10n.hi} ',
                    style: VType.serifTitle.copyWith(color: t.ink),
                  ),
                  TextSpan(
                    text: firstName,
                    style: VType.serifTitle.copyWith(color: t.goldDeep),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (streak > 0) ...[
          _StreakChip(streak: streak),
          const SizedBox(width: 10),
        ],
        VIconCircle(
          icon: PhosphorIconsFill.notePencil,
          semanticLabel: context.l10n.noteButton,
          onTap: () {
            HapticFeedback.selectionClick();
            final user = context.read<AuthProvider>().currentUser!;
            _showClientNoteSheet(
              clientId: user.uid,
              coachId: user.coachId ?? '',
              date: _selectedDate,
            );
          },
        ),
      ],
    );
  }

  // ==========================================================================
  //  CALENDAR STRIP — 7 quiet cells, selected = ink fill, today = gold dot
  // ==========================================================================
  /// A horizontally-scrollable strip of the last [_calendarDays] days. Days are
  /// generated newest-first (index 0 = today) and the list is [reverse]d, so
  /// today sits at the trailing edge and is on screen the moment the app opens.
  /// Tapping any earlier day switches the whole dashboard to it, read-only.
  Widget _calendarStrip() {
    final days = List.generate(
      _calendarDays,
      (i) => today.subtract(Duration(days: i)),
    );

    return SizedBox(
      height: 66,
      child: ListView.builder(
        reverse: true,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: days.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsetsDirectional.only(start: 8),
          child: _calendarCell(days[i], today),
        ),
      ),
    );
  }

  Widget _calendarCell(DateTime day, DateTime now) {
    final t = context.tokens;
    final normalizedDay = _normalizedDate(day);
    final isToday = _isSameDay(day, now);
    final isSelected = _isSameDay(_selectedDate, normalizedDay);
    final narrow = MaterialLocalizations.of(context).narrowWeekdays;

    return VPressable(
      onTap: () {
        setState(() => _selectedDate = normalizedDay);
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: VDuration.standard,
        curve: VMotion.curve,
        width: 48,
        height: 62,
        decoration: BoxDecoration(
          // Unselected cells sit transparent on the warm canvas — no whitish
          // card. Only the selected day fills (ink); today keeps its gold dot.
          color: isSelected ? t.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(VRadius.input),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              narrow[day.weekday % 7],
              style: VType.caption.copyWith(
                color: isSelected
                    ? t.onInk.withValues(alpha: 0.7)
                    : t.inkTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            VTextScaleCap(
              child: Text(
                '${day.day}',
                style: VType.stat(17)
                    .copyWith(color: isSelected ? t.onInk : t.ink),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isToday ? t.gold : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pastDayIndicator() {
    final t = context.tokens;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: t.surfaceSubtle,
          borderRadius: BorderRadius.circular(VRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsRegular.clockCounterClockwise,
                size: 14, color: t.inkSecondary),
            const SizedBox(width: 6),
            Text(
              context.l10n.viewingPastDay,
              style: VType.caption.copyWith(color: t.inkSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  //  NUTRITION — hero calorie count-up + 3 naked macro stats + Log Meal
  // ==========================================================================
  Widget _nutritionSection({
    required int currentCals,
    required int currentProtein,
    required int currentCarbs,
    required int currentFat,
    required TargetMacros targets,
    required bool isViewingToday,
  }) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CalorieHero(
          current: currentCals,
          target: targets.calories,
          label: context.l10n.caloriesLabel,
          unit: context.l10n.kcal,
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MacroStat(
                icon: PhosphorIconsFill.fish,
                tint: t.teal,
                label: context.l10n.macroProtein,
                current: currentProtein,
                target: targets.protein,
                kind: MacroTargetKind.floor,
              ),
            ),
            Expanded(
              child: _MacroStat(
                icon: PhosphorIconsFill.bread,
                tint: t.gold,
                label: context.l10n.macroCarbs,
                current: currentCarbs,
                target: targets.carbs,
                kind: MacroTargetKind.softCeiling,
              ),
            ),
            Expanded(
              child: _MacroStat(
                icon: PhosphorIconsFill.cheese,
                tint: t.clay,
                label: context.l10n.macroFat,
                current: currentFat,
                target: targets.fat,
                kind: MacroTargetKind.softCeiling,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        VPillButton.primary(
          label: context.l10n.logMeal,
          icon: PhosphorIconsBold.plus,
          onPressed: isViewingToday
              ? () async {
                  final user = context.read<AuthProvider>().currentUser!;
                  // Compact creation sheet (v2.13): pick the method here, then
                  // the full-screen flow opens already in that mode.
                  final action = await showVSheet<LogMealAction>(
                    context: context,
                    builder: (_) => const LogMealChooserSheet(),
                  );
                  if (action == null || !mounted) return;
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => LogMealScreen(
                        clientId: user.uid,
                        coachId: user.coachId ?? '',
                        initialAction: action,
                      ),
                    ),
                  );
                }
              : null,
        ),
      ],
    );
  }

  // ==========================================================================
  //  MEALS — VRow-style rows inside a VGroupCard
  // ==========================================================================
  Widget _mealsSection(List<Meal> meals, {required bool canEdit}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHead(context.l10n.todaysMeals, count: meals.length),
        const SizedBox(height: 16),
        VGroupCard(
          dividerInset: 68,
          children: [
            for (final meal in meals) _mealRow(meal, canEdit: canEdit),
          ],
        ),
      ],
    );
  }

  Widget _mealRow(Meal meal, {required bool canEdit}) {
    final t = context.tokens;
    final confTint = _confidenceTint(t, meal.aiConfidence);

    return VPressable(
      onTap: canEdit ? () => _showMealActionsSheet(meal) : null,
      overlay: true,
      overlayRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _mealLeading(meal, confTint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    meal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VType.headline.copyWith(color: t.ink),
                  ),
                  const SizedBox(height: 7),
                  // Macro dots share the section's tints (protein teal, carbs
                  // gold, fat clay) — colour ties the row to the dashboard.
                  Row(
                    children: [
                      _macroDot(t.teal, meal.protein),
                      const SizedBox(width: 14),
                      _macroDot(t.gold, meal.carbs),
                      const SizedBox(width: 14),
                      _macroDot(t.clay, meal.fat),
                    ],
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
                  Text('${meal.calories}',
                      style: VType.stat(22).copyWith(color: t.ink)),
                  Text(' ${context.l10n.kcal}',
                      style: VType.caption.copyWith(color: t.inkTertiary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroDot(Color tint, double grams) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '${grams.toStringAsFixed(0)}g',
          style: VType.caption.copyWith(
            color: t.ink,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  /// Meal thumbnail: the AI photo when present, else a fork glyph. A small
  /// confidence dot sits on the corner — provenance without an extra text line.
  Widget _mealLeading(Meal meal, Color confTint) {
    final t = context.tokens;
    final Widget base = (meal.imageUrl ?? '').isNotEmpty
        ? VAvatar(
            name: meal.name,
            shape: VAvatarShape.squircle,
            size: 40,
            imageUrl: meal.imageUrl,
          )
        : Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: t.tintFill(t.clay),
              borderRadius: BorderRadius.circular(VRadius.squircle),
            ),
            child: Icon(PhosphorIconsFill.forkKnife, size: 19, color: t.clay),
          );

    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          base,
          PositionedDirectional(
            end: -2,
            top: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: confTint,
                shape: BoxShape.circle,
                border: Border.all(color: t.surface, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  //  WATER / WEIGHT / SLEEP — three borderless surface cards
  // ==========================================================================
  Widget _waterCard(int waterLiters, bool isEnabled) {
    final t = context.tokens;
    return _habitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardHeader(PhosphorIconsFill.drop, t.steel, context.l10n.waterLabel),
          const SizedBox(height: 14),
          _bigNumber('$waterLiters', ' L'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _roundStepButton(
                icon: PhosphorIconsBold.minus,
                enabled: isEnabled && waterLiters > 0,
                onTap: () {
                  setState(() => _waterLiters = waterLiters - 1);
                  HapticFeedback.lightImpact();
                  _firestoreService.updateWater(_uid, _coachId, _waterLiters.toDouble());
                },
              ),
              _roundStepButton(
                icon: PhosphorIconsBold.plus,
                enabled: isEnabled,
                primary: true,
                onTap: () {
                  setState(() => _waterLiters = waterLiters + 1);
                  HapticFeedback.lightImpact();
                  _firestoreService.updateWater(_uid, _coachId, _waterLiters.toDouble());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weightCard(double? weight, bool isEnabled) {
    final t = context.tokens;
    final user = context.read<AuthProvider>().currentUser;
    final unit = user?.weightUnit;
    final metric = isMetricWeight(unit);
    final shown = weight != null ? displayWeight(weight, unit) : null;
    final unitLabel = metric ? context.l10n.unitKg : context.l10n.unitLb;

    return _habitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardHeader(PhosphorIconsFill.scales, t.gold, context.l10n.weightLabel),
          const SizedBox(height: 14),
          _bigNumber(
            shown != null ? shown.toStringAsFixed(metric ? 1 : 0) : '—',
            shown != null ? ' $unitLabel' : '',
          ),
          const SizedBox(height: 16),
          _softButton(
            label: context.l10n.logNow,
            enabled: isEnabled,
            onTap: () => _showLogWeightSheet(),
          ),
        ],
      ),
    );
  }

  Widget _sleepCard(int sleepRating, bool isEnabled) {
    final t = context.tokens;
    return _habitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardHeader(PhosphorIconsFill.moon, t.lilac, context.l10n.sleepQuality),
          const SizedBox(height: 12),
          Text(context.l10n.howRested,
              textAlign: TextAlign.center,
              style: VType.subhead.copyWith(color: t.inkSecondary)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final active = index < sleepRating;
              return VPressable(
                onTap: isEnabled
                    ? () {
                        setState(() => _sleepRating = index + 1);
                        HapticFeedback.selectionClick();
                        _firestoreService.updateSleep(_uid, _coachId, index + 1);
                      }
                    : null,
                enableFeedback: isEnabled,
                child: Semantics(
                  label: '${index + 1}',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: Icon(
                      active ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                      size: 32,
                      color: active ? t.gold : t.inkTertiary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  //  CUSTOM HABITS — coach-defined, additive to the core pillars
  // ==========================================================================
  IconData _habitIcon(String key) {
    switch (key) {
      case 'footprints':
        return PhosphorIconsFill.footprints;
      case 'drop':
        return PhosphorIconsFill.drop;
      case 'barbell':
        return PhosphorIconsFill.barbell;
      case 'pill':
        return PhosphorIconsFill.pill;
      case 'forkKnife':
        return PhosphorIconsFill.forkKnife;
      case 'moon':
        return PhosphorIconsFill.moon;
      case 'heartbeat':
        return PhosphorIconsFill.heartbeat;
      case 'sun':
        return PhosphorIconsFill.sun;
      case 'leaf':
        return PhosphorIconsFill.leaf;
      case 'prohibit':
        return PhosphorIconsFill.prohibit;
      default:
        return PhosphorIconsFill.checkCircle;
    }
  }

  void _toggleHabit(String habitId, bool currentlyDone) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    HapticFeedback.lightImpact();
    _firestoreService.toggleHabitCompletion(
        user.uid, user.coachId ?? '', habitId, !currentlyDone);
  }

  /// Optional "Your habits" checklist — coach-defined habits on top of the core
  /// water/sleep/weight pillars. Deliberately ADDITIVE: renders nothing when the
  /// coach defined none, and checking these does NOT feed the adherence engine
  /// (v1 decision — status stays a function of the core pillars only).
  Widget _customHabits(Map<String, bool> checks, bool isEnabled) {
    final t = context.tokens;
    final habits = context.read<AuthProvider>().currentUser?.customHabits ??
        const <HabitDefinition>[];
    if (habits.isEmpty) return const SizedBox.shrink();
    final done = habits.where((h) => checks[h.id] == true).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: VSpace.sectionGap),
        _sectionHead(
          context.l10n.yourHabits,
          trailing: Text('$done/${habits.length}',
              style: VType.subhead.copyWith(
                color: t.inkTertiary,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
        ),
        const SizedBox(height: 16),
        VGroupCard(
          children: [
            for (final habit in habits)
              _habitRow(habit, checks[habit.id] == true, isEnabled),
          ],
        ),
      ],
    );
  }

  Widget _habitRow(HabitDefinition habit, bool done, bool isEnabled) {
    final t = context.tokens;
    return VRow(
      onTap: isEnabled ? () => _toggleHabit(habit.id, done) : null,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: done ? t.tintFill(t.gold) : t.surfaceSubtle,
          shape: BoxShape.circle,
        ),
        child: Icon(_habitIcon(habit.icon),
            size: 18, color: done ? t.goldDeep : t.inkSecondary),
      ),
      title: habit.name,
      trailing: _CheckCircle(done: done),
    );
  }

  // ==========================================================================
  //  SHARED SCREEN PRIMITIVES
  // ==========================================================================
  Widget _sectionHead(String title, {int? count, Widget? trailing}) {
    final t = context.tokens;
    return Row(
      children: [
        Text(title, style: VType.title2.copyWith(color: t.ink)),
        if (count != null) ...[
          const SizedBox(width: 8),
          Text('$count', style: VType.stat(17).copyWith(color: t.inkSecondary)),
        ],
        const Spacer(),
        ?trailing,
      ],
    );
  }

  Widget _habitCard({required Widget child}) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        boxShadow: t.cardShadow,
      ),
      padding: const EdgeInsets.all(VSpace.cardPadding),
      child: child,
    );
  }

  Widget _cardHeader(IconData icon, Color tint, String label) {
    final t = context.tokens;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: t.isLight ? 0.18 : 0.22),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 17, color: t.legibleTint(tint)),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: VType.subhead
                .copyWith(color: t.inkSecondary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _bigNumber(String value, String unit) {
    final t = context.tokens;
    return VTextScaleCap(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(value, style: VType.stat(28).copyWith(color: t.ink)),
          if (unit.isNotEmpty)
            Text(unit, style: VType.caption.copyWith(color: t.inkTertiary)),
        ],
      ),
    );
  }

  Widget _roundStepButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    final t = context.tokens;
    return VPressable(
      onTap: enabled ? onTap : null,
      enableFeedback: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primary ? t.ink : t.surfaceSubtle,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: primary ? t.onInk : t.ink),
        ),
      ),
    );
  }

  Widget _softButton({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final t = context.tokens;
    return VPressable(
      onTap: enabled ? onTap : null,
      enableFeedback: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.surfaceSubtle,
            borderRadius: BorderRadius.circular(VRadius.input),
          ),
          child: Text(
            label,
            style: VType.subhead
                .copyWith(color: t.ink, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Color _confidenceTint(ValenceTokens t, MealConfidence c) => switch (c) {
        MealConfidence.high => t.sage,
        MealConfidence.medium => t.gold,
        MealConfidence.low => t.clay,
        MealConfidence.manual => t.inkTertiary,
      };

  // ==========================================================================
  //  SHARE PROGRESS
  // ==========================================================================

  /// Opens the shareable progress card.
  ///
  /// Replaces the old copy-to-clipboard "daily win": nobody shares text, and
  /// nobody brags about one day's calorie percentage. The card shows real
  /// progress read from their own logs, and credits their coach — which is the
  /// growth loop (a client's post advertises their coach, so coaches want
  /// their roster sharing).
  Future<void> _openShareWin(AppUser client) async {
    // The coach's name for the credit line. Best-effort: a failure here drops
    // the credit rather than blocking the client's own progress card.
    var coachName = '';
    final coachId = client.coachId;
    if (coachId != null && coachId.trim().isNotEmpty) {
      try {
        final coach = await _firestoreService.streamUserById(coachId).first;
        coachName = coach?.name ?? '';
      } catch (_) {}
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ShareWinScreen(client: client, coachName: coachName),
      ),
    );
  }

  // ==========================================================================
  //  SHEETS (all VSheets — AlertDialog is retired app-wide, §6.6)
  // ==========================================================================
  Future<void> _showClientNoteSheet({
    required String clientId,
    required String coachId,
    required DateTime date,
  }) async {
    if (!_isSameDay(date, today)) {
      showVToast(context, context.l10n.noteOnlyToday);
      return;
    }
    // Prefill with today's existing note (one-time) before opening the sheet.
    final existing = (await _firestoreService
            .streamLogForDateNullable(clientId, date)
            .first)
        ?.clientNote
        ?.trim();
    if (existing != null && existing.isNotEmpty) {
      _clientNoteController.text = existing;
    }
    if (!mounted) return;

    await showVSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final hasText = _clientNoteController.text.trim().isNotEmpty;
          return _NoteSheetHost(
            controller: _clientNoteController,
            hasText: hasText,
            onChanged: () => setSheet(() {}),
            onSend: () async {
              HapticFeedback.mediumImpact();
              final navigator = Navigator.of(ctx);
              setSheet(() {});
              final ok = await _saveClientNote(
                clientId: clientId,
                coachId: coachId,
                date: date,
                note: _clientNoteController.text.trim(),
              );
              if (!mounted) return;
              if (ok) {
                _clientNoteController.clear();
                navigator.pop();
              } else {
                setSheet(() {});
              }
            },
          );
        },
      ),
    );
  }

  Future<bool> _saveClientNote({
    required String clientId,
    required String coachId,
    required DateTime date,
    required String note,
  }) async {
    if (note.isEmpty) return false;
    try {
      if (_isSameDay(date, today)) {
        await _firestoreService.getOrCreateTodayLog(clientId, coachId);
      }
      final saved =
          await _firestoreService.saveClientNoteForDate(clientId, date, note);
      if (!mounted) return saved;
      showVToast(context,
          saved ? context.l10n.noteSentToCoach : context.l10n.noLogForDay);
      return saved;
    } catch (_) {
      if (mounted) showVToast(context, context.l10n.noteSaveFailed);
      return false;
    }
  }

  Future<void> _showLogWeightSheet() async {
    final user = context.read<AuthProvider>().currentUser!;
    final unitLabel =
        user.usesMetricWeight ? context.l10n.unitKg : context.l10n.unitLb;
    final value = await showVSheet<double>(
      context: context,
      builder: (_) => _LogWeightSheet(
        title: context.l10n.logWeightTitle,
        hint: context.l10n.enterWeightHint,
        saveLabel: context.l10n.save,
        unitLabel: unitLabel,
      ),
    );
    if (value == null || !mounted) return;
    await _firestoreService.updateWeight(
        user.uid, user.coachId ?? '', weightToKg(value, user.weightUnit));
  }

  Future<void> _showMealActionsSheet(Meal meal) async {
    final action = await showVSheet<String>(
      context: context,
      builder: (ctx) => VSheet(
        title: meal.name,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetActionRow(
              icon: PhosphorIconsRegular.pencilSimple,
              label: context.l10n.editMeal,
              onTap: () => Navigator.of(ctx).pop('edit'),
            ),
            _sheetActionRow(
              icon: PhosphorIconsRegular.trash,
              label: context.l10n.deleteMeal,
              destructive: true,
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') {
      await _showEditMealSheet(meal);
    } else if (action == 'delete') {
      await _confirmDeleteMeal(meal);
    }
  }

  Widget _sheetActionRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final t = context.tokens;
    final color = destructive ? t.alert : t.ink;
    final tintBg = destructive ? t.alert : t.gold;
    return VPressable(
      onTap: onTap,
      overlay: true,
      overlayRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: t.tintFill(tintBg), shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: t.legibleTint(tintBg)),
            ),
            const SizedBox(width: 12),
            Text(label, style: VType.headline.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditMealSheet(Meal meal) async {
    final edited = await showVSheet<Meal>(
      context: context,
      builder: (_) => _EditMealSheet(meal: meal),
    );
    if (edited == null || !mounted) return;
    await _firestoreService.updateMealInTodayLog(_uid, edited);
    if (!mounted) return;
    showVToast(context, context.l10n.mealUpdated);
  }

  Future<void> _confirmDeleteMeal(Meal meal) async {
    final t = context.tokens;
    final ok = await showVSheet<bool>(
      context: context,
      builder: (ctx) => VSheet(
        title: context.l10n.deleteMealTitle,
        pinnedAction: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VPillButton.destructive(
              label: context.l10n.delete,
              solid: true,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: 8),
            VPillButton.secondary(
              label: context.l10n.cancel,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            context.l10n.deleteMealMsg(meal.name),
            style: VType.body.copyWith(color: t.inkSecondary),
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    await _firestoreService.deleteMealFromTodayLog(_uid, meal.id);
    if (!mounted) return;
    showVToast(context, context.l10n.mealDeleted);
  }
}

// ============================================================================
//  Private leaf widgets
// ============================================================================

/// Quiet gold flame + streak count, no pill (design.md §5.6).
class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: '$streak day streak',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsFill.fire, size: 18, color: t.goldDeep),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: VType.stat(18).copyWith(color: t.goldDeep),
          ),
        ],
      ),
    );
  }
}

/// A single naked macro metric with a mini fill bar (design.md §5.6). Mirrors
/// [VStatColumn] but carries current/target + a proportion bar.
class _MacroStat extends StatelessWidget {
  const _MacroStat({
    required this.icon,
    required this.tint,
    required this.label,
    required this.current,
    required this.target,
    required this.kind,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final int current;
  final int target;
  final MacroTargetKind kind;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    // Direction matters: protein over target is a win, carbs and fat get a
    // tolerance band, calories does not. See utils/macro_status.dart.
    final tone = macroTone(kind: kind, current: current, target: target);
    final over = target > 0 && current > target;
    final toneColor = switch (tone) {
      MacroTone.alert => t.alert,
      MacroTone.good => t.good,
      MacroTone.neutral => t.inkTertiary,
    };
    final fraction =
        target > 0 ? (current / target).clamp(0.0, 1.0).toDouble() : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: t.isLight ? 0.18 : 0.22),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 17, color: t.legibleTint(tint)),
        ),
        const SizedBox(height: 8),
        VTextScaleCap(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$current',
                  style: VType.stat(22).copyWith(
                      color: tone == MacroTone.alert ? t.alert : t.ink)),
              Text(
                over ? ' +${current - target}g' : ' / ${target}g',
                style: VType.caption.copyWith(
                  color: toneColor,
                  fontWeight: tone == MacroTone.neutral
                      ? FontWeight.w500
                      : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: VType.caption.copyWith(color: t.inkSecondary)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: SizedBox(
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(VRadius.pill),
              child: Container(
                height: 8,
                color: t.surfaceSubtle,
                child: AnimatedFractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: fraction,
                  duration: reduceMotion ? Duration.zero : VDuration.fill,
                  curve: VMotion.curve,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tone == MacroTone.alert ? t.alert : tint,
                      borderRadius: BorderRadius.circular(VRadius.pill),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The calorie hero: a fire glyph beside a count-up number, then a horizontal
/// fill bar that grows from the start (mirroring the macro bars). Over target,
/// the number + bar turn `alert` and a "+over" badge appears (design.md §1.1).
class _CalorieHero extends StatelessWidget {
  const _CalorieHero({
    required this.current,
    required this.target,
    required this.label,
    required this.unit,
  });

  final int current;
  final int target;
  final String label;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final over = target > 0 && current > target;
    final fraction =
        target > 0 ? (current / target).clamp(0.0, 1.0).toDouble() : 0.0;
    final accent = over ? t.alert : t.gold;

    return Column(
      children: [
        Semantics(
          label: '$label: $current / $target $unit',
          child: VTextScaleCap(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(PhosphorIconsFill.fire,
                    size: 26, color: over ? t.alert : t.goldDeep),
                const SizedBox(width: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: current.toDouble()),
                      duration:
                          reduceMotion ? Duration.zero : VDuration.countUp,
                      curve: VMotion.curve,
                      builder: (context, v, _) => Text(
                        v.round().toString(),
                        style: VType.display
                            .copyWith(color: over ? t.alert : t.ink),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('/ $target $unit',
                        style: VType.subhead.copyWith(color: t.inkSecondary)),
                  ],
                ),
                if (over) ...[
                  const SizedBox(width: 8),
                  _OverBadge(text: '+${current - target}'),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Full-width track (surfaceSubtle) with the gold fill on top — the empty
        // portion reads as "remaining", the same treatment as the macro bars.
        ClipRRect(
          borderRadius: BorderRadius.circular(VRadius.pill),
          child: Container(
            height: 12,
            color: t.surfaceSubtle,
            child: AnimatedFractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: fraction,
              duration: reduceMotion ? Duration.zero : VDuration.fill,
              curve: VMotion.curve,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(VRadius.pill),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Small `alert`-tinted "+N over" pill, shown when a metric exceeds its target.
class _OverBadge extends StatelessWidget {
  const _OverBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: t.alert.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VRadius.pill),
      ),
      child: Text(
        text,
        style: VType.caption.copyWith(
          color: t.alert,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Trailing habit-completion circle: gold fill + check when done, hairline ring
/// when not (design.md §5.6).
class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.done});
  final bool done;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AnimatedContainer(
      duration: VDuration.standard,
      curve: VMotion.curve,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: done ? t.gold : Colors.transparent,
        shape: BoxShape.circle,
        border: done ? null : Border.all(color: t.hairline, width: 2),
      ),
      child: done
          ? Icon(PhosphorIconsBold.check, size: 15, color: t.onInk)
          : null,
    );
  }
}

/// The note-to-coach sheet body. Kept as a small widget so the parent's
/// StatefulBuilder can drive its enabled/loading state while the controller
/// stays owned by the screen State.
class _NoteSheetHost extends StatelessWidget {
  const _NoteSheetHost({
    required this.controller,
    required this.hasText,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool hasText;
  final VoidCallback onChanged;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return VSheet(
      title: context.l10n.todaysCheckIn,
      pinnedAction: VPillButton.primary(
        label: context.l10n.sendToCoach,
        icon: PhosphorIconsFill.paperPlaneTilt,
        onPressed: hasText ? onSend : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.noteToCoachBody,
            style: VType.body.copyWith(color: t.inkSecondary),
          ),
          const SizedBox(height: 16),
          VField(
            controller: controller,
            hint: context.l10n.noteToCoachHint,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Weight-entry sheet. Owns its own controller + focus node (design.md §2/§6.13:
/// sheets with text fields own their controllers). Pops the entered value in the
/// user's display unit; the caller converts to canonical kg.
class _LogWeightSheet extends StatefulWidget {
  const _LogWeightSheet({
    required this.title,
    required this.hint,
    required this.saveLabel,
    required this.unitLabel,
  });

  final String title;
  final String hint;
  final String saveLabel;
  final String unitLabel;

  @override
  State<_LogWeightSheet> createState() => _LogWeightSheetState();
}

class _LogWeightSheetState extends State<_LogWeightSheet> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  double? get _parsed {
    final v = double.tryParse(_controller.text.trim().replaceAll(',', '.'));
    return (v != null && v > 0) ? v : null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final valid = _parsed != null;
    return VSheet(
      title: widget.title,
      pinnedAction: VPillButton.primary(
        label: widget.saveLabel,
        onPressed: valid
            ? () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop(_parsed);
              }
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: VField(
          controller: _controller,
          focusNode: _focus,
          hint: widget.hint,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          suffix: Text(widget.unitLabel,
              style: VType.subhead.copyWith(color: t.inkSecondary)),
        ),
      ),
    );
  }
}

/// Edit-meal sheet. Owns its five controllers. Validates on save and pops the
/// edited [Meal]; the caller performs the write.
class _EditMealSheet extends StatefulWidget {
  const _EditMealSheet({required this.meal});
  final Meal meal;

  @override
  State<_EditMealSheet> createState() => _EditMealSheetState();
}

class _EditMealSheetState extends State<_EditMealSheet> {
  late final _name = TextEditingController(text: widget.meal.name);
  late final _calories =
      TextEditingController(text: widget.meal.calories.toString());
  late final _protein =
      TextEditingController(text: widget.meal.protein.toStringAsFixed(0));
  late final _carbs =
      TextEditingController(text: widget.meal.carbs.toStringAsFixed(0));
  late final _fat =
      TextEditingController(text: widget.meal.fat.toStringAsFixed(0));

  @override
  void dispose() {
    _name.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  void _save() {
    final calories = int.tryParse(_calories.text.trim());
    final protein = double.tryParse(_protein.text.trim().replaceAll(',', '.'));
    final carbs = double.tryParse(_carbs.text.trim().replaceAll(',', '.'));
    final fat = double.tryParse(_fat.text.trim().replaceAll(',', '.'));
    if (calories == null || protein == null || carbs == null || fat == null) {
      showVToast(context, context.l10n.invalidMacros);
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(Meal(
      id: widget.meal.id,
      name: _name.text.trim(),
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      imageUrl: widget.meal.imageUrl,
      aiConfidence: widget.meal.aiConfidence,
      loggedAt: widget.meal.loggedAt,
    ));
  }

  @override
  Widget build(BuildContext context) {
    const decimal = TextInputType.numberWithOptions(decimal: true);
    return VSheet(
      title: context.l10n.editMeal,
      pinnedAction: VPillButton.primary(
        label: context.l10n.save,
        onPressed: _save,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VField(
            controller: _name,
            label: context.l10n.mealName,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          VField(
            controller: _calories,
            label: context.l10n.caloriesLabel,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: VField(
                  controller: _protein,
                  label: context.l10n.proteinG,
                  keyboardType: decimal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: VField(
                  controller: _carbs,
                  label: context.l10n.carbsG,
                  keyboardType: decimal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: VField(
                  controller: _fat,
                  label: context.l10n.fatG,
                  keyboardType: decimal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
