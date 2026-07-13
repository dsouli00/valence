import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:valence/models/daily_log_model.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:valence/models/enums.dart';
import 'package:valence/models/habit_model.dart';
import 'package:valence/models/meal_model.dart';
import 'package:valence/models/target_macros.dart';
import 'package:valence/models/user_model.dart';
import 'package:valence/models/workout_models.dart';
import 'package:valence/pages/shared/progress_charts_section.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/ui/ui.dart';
import 'package:valence/utils/units.dart';

/// The coach's single-client command centre — hero (avatar + status + streak)
/// over three tabs:
///  • TODAY: date strip → mini stat cards → the client's nutrition dashboard
///    (mirrors what the client sees) → meals with per-meal macros → detailed
///    workout progress (per-set reps/weight vs target) → client note →
///    coach-note editor.
///  • ANALYTICS: the shared ProgressChartsSection (same charts as the
///    client's Progress tab).
///  • PLAN: macro targets (edit sheet), custom-habits manager, and the
///    day's assigned workout (update / swap / remove).
///
/// DESIGN: reskinned to design system v2.2 (design.md §5.12, archetype A).
/// Hero = VAvatar 56 + `title1` name + VStatusPill (+ quiet streak); tabs =
/// VSegmented; every dialog is a VSheet (AlertDialog retired); the Today-tab
/// nutrition intentionally MIRRORS the client home §5.6 components read-only
/// (same fire hero + tinted macro columns) so a coach-client conversation is
/// about the same picture — don't restyle one side without the other.
///
/// [client] is only the initial snapshot for instant paint — the screen
/// re-streams the user doc (`_clientStreamCached`) so macro/habit edits
/// refresh live. Weights display in the CLIENT's unit preference (not the
/// coach's): the coach reads values the client will recognize.
class ClientDetailsScreen extends StatefulWidget {
  final AppUser client;
  final int initialTabIndex;

  const ClientDetailsScreen({
    super.key,
    required this.client,
    this.initialTabIndex = 0,
  });

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  /// Cached display unit of the client currently being viewed ('kg'|'lb'),
  /// refreshed each build from the streamed client so deep workout/weight
  /// helpers can convert without threading it through every signature.
  String? _unit;
  String get _weightUnitLabel => isMetricWeight(_unit) ? context.l10n.unitKg : context.l10n.unitLb;
  String _weightStr(double kg) => '${_formatNumber(displayWeight(kg, _unit))} $_weightUnitLabel';
  final _firestoreService = FirestoreService();
  bool _isSavingMacros = false;
  late int _tab = widget.initialTabIndex.clamp(0, 2).toInt();
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  ChartRange _selectedRange = ChartRange.weekly;

  // Cached Firestore streams — created lazily and re-created only when their key
  // inputs (the viewed date / chart range) change. This stops unrelated rebuilds
  // — notably the keyboard opening, which re-runs build repeatedly during its
  // animation — from restarting the streams and rebuilding the whole screen
  // (the source of the typing lag).
  Stream<AppUser?>? _clientStream;
  Stream<AppUser?> get _clientStreamCached =>
      _clientStream ??= _firestoreService.streamUserById(widget.client.uid);

  DateTime? _logStreamDate;
  Stream<DailyLog?>? _logStream;
  Stream<DailyLog?> _logStreamFor(DateTime date) {
    if (_logStream == null || !_isSameDay(_logStreamDate!, date)) {
      _logStreamDate = date;
      _logStream = _firestoreService.streamLogForDateNullable(widget.client.uid, date);
    }
    return _logStream!;
  }

  DateTime? _workoutStreamDate;
  Stream<AssignedWorkout?>? _workoutStream;
  Stream<AssignedWorkout?> _assignedWorkoutStreamFor(DateTime date) {
    if (_workoutStream == null || !_isSameDay(_workoutStreamDate!, date)) {
      _workoutStreamDate = date;
      _workoutStream = _firestoreService.streamAssignedWorkoutForDate(widget.client.uid, date);
    }
    return _workoutStream!;
  }

  int? _recentLogsDays;
  Stream<List<DailyLog>>? _recentLogsStream;
  Stream<List<DailyLog>> _recentLogsStreamFor(int days) {
    if (_recentLogsStream == null || _recentLogsDays != days) {
      _recentLogsDays = days;
      _recentLogsStream = _firestoreService.streamRecentLogs(widget.client.uid, days: days);
    }
    return _recentLogsStream!;
  }

  // Status labels mirror clients_screen's bucket meta so the two surfaces
  // read identically. Colors come from the status tokens (§1.1).
  String _statusLabel(ClientStatus status) {
    switch (status) {
      case ClientStatus.unconfigured:
        return context.l10n.statusSetup;
      case ClientStatus.onTrack:
        return context.l10n.statusGood;
      case ClientStatus.slipping:
        return context.l10n.statusWatch;
      case ClientStatus.atRisk:
        return context.l10n.statusAlert;
    }
  }

  VStatusVariant _statusVariant(ClientStatus status) {
    switch (status) {
      case ClientStatus.onTrack:
        return VStatusVariant.good;
      case ClientStatus.slipping:
        return VStatusVariant.watch;
      case ClientStatus.atRisk:
        return VStatusVariant.alert;
      case ClientStatus.unconfigured:
        // Setup renders as a VTextAction, never a pill (design.md §2) — this
        // value is unused for unconfigured clients but keeps the switch total.
        return VStatusVariant.brandNew;
    }
  }

  String _sleepLabel(int? rating) {
    switch (rating) {
      case 1:
      case 2:
        return context.l10n.sleepPoor;
      case 3:
        return context.l10n.sleepFair;
      case 4:
        return context.l10n.statusGood;
      case 5:
        return context.l10n.sleepGreat;
      default:
        return '--';
    }
  }

  String _formatNumber(num value) {
    final asDouble = value.toDouble();
    if (asDouble == asDouble.roundToDouble()) {
      return asDouble.toInt().toString();
    }
    return asDouble.toStringAsFixed(1);
  }

  String _firstName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return context.l10n.roleClient;
    return trimmed.split(' ').first;
  }

  DateTime _normalizedDate(DateTime date) => DateTime(date.year, date.month, date.day);

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _toast(String message) {
    if (!mounted) return;
    showVToast(context, message);
  }

  /// Saves (or overwrites) the coach note for [date]. Returns whether it saved
  /// — the note overwrites the same day's note rather than appending a new one.
  Future<bool> _saveCoachNoteText(String clientId, DateTime date, String text) async {
    final note = text.trim();
    if (note.isEmpty) return false;
    try {
      final saved = await _firestoreService.saveCoachNoteForDate(clientId, date, note);
      if (!mounted) return saved;
      _toast(saved ? context.l10n.noteSaved : context.l10n.noLogForDay);
      return saved;
    } catch (_) {
      if (!mounted) return false;
      _toast(context.l10n.noteSaveFailed);
      return false;
    }
  }

  /// Opens the macro-targets editor and saves. This is also the coach's
  /// OVERRIDE for a client stuck in "Setup": saving marks them configured
  /// (status on_track) even if they never finished intake themselves.
  Future<void> _configureMacros(AppUser client) async {
    if (_isSavingMacros) return;

    final current = client.targetMacros ?? const TargetMacros();
    // The sheet owns its own TextEditingControllers and disposes them in its
    // State.dispose() (runs at the correct teardown moment). Disposing them
    // here right after pop tripped `InheritedElement.debugDeactivated` when a
    // field still had focus during the sheet's exit.
    final draft = await showVSheet<_MacroDraft>(
      context: context,
      builder: (_) => _MacroEditorSheet(
        initial: current,
        clientFirstName: _firstName(client.name),
      ),
    );

    if (draft == null) return;

    final calories = int.tryParse(draft.calories);
    final protein = int.tryParse(draft.protein);
    final carbs = int.tryParse(draft.carbs);
    final fat = int.tryParse(draft.fat);

    if (calories == null || protein == null || carbs == null || fat == null) {
      if (!mounted) return;
      _toast(context.l10n.enterValidMacros);
      return;
    }

    if (calories <= 0 || protein <= 0 || carbs <= 0 || fat <= 0) {
      if (!mounted) return;
      _toast(context.l10n.macrosMustBePositive);
      return;
    }

    setState(() => _isSavingMacros = true);
    try {
      final targets = TargetMacros(
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      );
      await _firestoreService.updateClientMacros(client.uid, targets);
      if (!mounted) return;
      _toast(context.l10n.macroTargetsUpdated);
    } catch (_) {
      if (!mounted) return;
      _toast(context.l10n.failedSaveMacros);
    } finally {
      if (mounted) setState(() => _isSavingMacros = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return StreamBuilder<AppUser?>(
      stream: _clientStreamCached,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: t.canvas,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        VSpace.screenMargin, 8, VSpace.screenMargin, 0),
                    child: VIconCircle(
                      icon: PhosphorIconsBold.caretLeft,
                      semanticLabel: context.l10n.back,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Expanded(
                    child: VEmpty(
                      icon: PhosphorIconsRegular.cloudSlash,
                      title: context.l10n.clientDetailsTitle,
                      message: context.l10n.loadClientError,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final client = snapshot.data ?? widget.client;
        _unit = client.weightUnit;
        final status = client.status ?? ClientStatus.onTrack;

        return Scaffold(
          backgroundColor: t.canvas,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      VSpace.screenMargin, 8, VSpace.screenMargin, 0),
                  child: _buildHero(client, status),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: VSpace.screenMargin),
                  child: VSegmented<int>(
                    selected: _tab,
                    onChanged: (v) => setState(() => _tab = v),
                    segments: [
                      VSegment(0, context.l10n.todayLabel),
                      VSegment(1, context.l10n.tabAnalytics),
                      VSegment(2, context.l10n.tabPlan),
                    ],
                  ),
                ),
                Expanded(
                  // IndexedStack keeps all three tabs alive (mirrors the old
                  // TabBarView) so cached streams stay subscribed and switching
                  // tabs never flashes a loading state.
                  child: IndexedStack(
                    index: _tab,
                    children: [
                      StreamBuilder<DailyLog?>(
                        stream: _logStreamFor(_selectedDate),
                        builder: (context, logSnapshot) {
                          if (logSnapshot.hasError) {
                            return Center(
                              child: Text(
                                context.l10n.loadDayError,
                                style: VType.body.copyWith(color: t.inkSecondary),
                              ),
                            );
                          }
                          return _buildTodayTab(client, logSnapshot.data, _selectedDate);
                        },
                      ),
                      _buildAnalyticsTab(client),
                      _buildPlanTab(client),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  //  HERO — back chip · VAvatar 56 · name title1 · status + quiet streak
  // ==========================================================================
  Widget _buildHero(AppUser client, ClientStatus status) {
    final t = context.tokens;
    final streak = client.currentStreak ?? 0;
    final isSetup = status == ClientStatus.unconfigured;

    // The one status signal on the screen: a pill (breathing when at-risk), or
    // the "Setup →" action for unconfigured clients (design.md §2) — tapping
    // it jumps straight to the Plan tab where macros get configured.
    final Widget statusWidget = isSetup
        ? VTextAction(
            label: context.l10n.statusSetup,
            arrow: true,
            onTap: () => setState(() => _tab = 2),
          )
        : VStatusPill(
            variant: _statusVariant(status),
            label: _statusLabel(status),
            breathing: status == ClientStatus.atRisk,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VIconCircle(
          icon: PhosphorIconsBold.caretLeft,
          semanticLabel: context.l10n.back,
          onTap: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            VAvatar(name: client.name, size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VType.title1.copyWith(color: t.ink),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      statusWidget,
                      if (streak > 0) ...[
                        const SizedBox(width: 12),
                        Icon(PhosphorIconsFill.fire, size: 15, color: t.goldDeep),
                        const SizedBox(width: 3),
                        Text(
                          '$streak',
                          style: VType.stat(15).copyWith(color: t.goldDeep),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================================
  //  TODAY TAB — date strip · mini stats · nutrition mirror · meals · workout
  //  · check-in · coach note. Intentionally mirrors the client's own dashboard
  //  (§5.6) so a coach-client conversation is about the same picture.
  // ==========================================================================
  Widget _buildTodayTab(AppUser client, DailyLog? log, DateTime selectedDate) {
    final targets = client.targetMacros ?? const TargetMacros();
    final weight = log?.weightKg ?? client.currentWeight;
    final water = log?.waterLiters;
    final sleep = log?.sleepRating;
    final isToday = _isSameDay(selectedDate, DateTime.now());
    final t = context.tokens;

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        VSpace.screenMargin,
        16,
        VSpace.screenMargin,
        VSpace.scrollBottom + 72,
      ),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildCoachDateStrip(),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MiniStat(
                icon: PhosphorIconsFill.scales,
                tint: t.gold,
                label: context.l10n.weightLabel,
                value: weight == null ? '--' : _weightStr(weight),
              ),
            ),
            const SizedBox(width: VSpace.cardGap),
            Expanded(
              child: _MiniStat(
                icon: PhosphorIconsFill.drop,
                tint: t.steel,
                label: context.l10n.waterLabel,
                value: water == null ? '--' : '${_formatNumber(water)}L',
              ),
            ),
            const SizedBox(width: VSpace.cardGap),
            Expanded(
              child: _MiniStat(
                icon: PhosphorIconsFill.moon,
                tint: t.lilac,
                label: context.l10n.sleepLabel,
                value: _sleepLabel(sleep),
              ),
            ),
          ],
        ),
        const SizedBox(height: VSpace.sectionGap),
        _sectionHead(
          context.l10n.nutritionSummary,
          actionLabel: context.l10n.editTargets,
          onAction: () => _configureMacros(client),
        ),
        const SizedBox(height: 20),
        _CalorieHero(
          current: log?.totalCalories ?? 0,
          target: targets.calories,
          label: context.l10n.caloriesLabel,
          unit: context.l10n.kcal,
        ),
        const SizedBox(height: VSpace.sectionGap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MacroStat(
                icon: PhosphorIconsFill.fish,
                tint: t.teal,
                label: context.l10n.macroProtein,
                current: (log?.totalProtein ?? 0).toInt(),
                target: targets.protein,
              ),
            ),
            Expanded(
              child: _MacroStat(
                icon: PhosphorIconsFill.bread,
                tint: t.gold,
                label: context.l10n.macroCarbs,
                current: (log?.totalCarbs ?? 0).toInt(),
                target: targets.carbs,
              ),
            ),
            Expanded(
              child: _MacroStat(
                icon: PhosphorIconsFill.cheese,
                tint: t.clay,
                label: context.l10n.macroFat,
                current: (log?.totalFat ?? 0).toInt(),
                target: targets.fat,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildMealsList(log),
        const SizedBox(height: VSpace.sectionGap),
        _sectionHead(
          isToday ? context.l10n.todaysWorkout : context.l10n.workoutLabel,
          actionLabel: context.l10n.swapWorkout,
          onAction: () => _showSwapWorkoutDialog(client, selectedDate),
        ),
        const SizedBox(height: 16),
        _buildWorkoutCard(client.uid, selectedDate),
        const SizedBox(height: VSpace.sectionGap),
        VCallout(
          author: context.l10n.clientCheckIn,
          body: (log?.clientNote?.trim().isNotEmpty ?? false)
              ? log!.clientNote!.trim()
              : context.l10n.noCheckInNote,
        ),
        const SizedBox(height: VSpace.sectionGap),
        _sectionHead(context.l10n.coachNoteLabel),
        const SizedBox(height: 16),
        _CoachNoteEditor(
          key: ValueKey('coachnote_${selectedDate.toIso8601String()}'),
          initialNote: log?.coachNote,
          firstName: _firstName(client.name),
          isToday: isToday,
          onSave: (text) => _saveCoachNoteText(client.uid, selectedDate, text),
        ),
      ],
    );
  }

  /// Big bold section head + optional quiet trailing action (design.md §1.2 —
  /// the old gold container chips are retired).
  Widget _sectionHead(String title, {String? actionLabel, VoidCallback? onAction}) {
    final t = context.tokens;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: VType.title2.copyWith(color: t.ink),
          ),
        ),
        if (actionLabel != null) VTextAction(label: actionLabel, onTap: onAction),
      ],
    );
  }

  // ==========================================================================
  //  MEALS — mirrors the client home meal rows (photo squircle · name · macro
  //  dots · naked kcal), read-only.
  // ==========================================================================
  Widget _buildMealsList(DailyLog? log) {
    final t = context.tokens;
    final meals = log?.meals ?? const [];
    if (meals.isEmpty) {
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
              Icon(PhosphorIconsRegular.forkKnife, size: 14, color: t.inkSecondary),
              const SizedBox(width: 6),
              Text(
                context.l10n.noMealsLogged,
                style: VType.caption.copyWith(color: t.inkSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return VGroupCard(
      dividerInset: 68,
      children: [for (final meal in meals) _mealRow(meal)],
    );
  }

  Widget _mealRow(Meal meal) {
    final t = context.tokens;
    final hasImage = (meal.imageUrl ?? '').isNotEmpty;

    final Widget leading = hasImage
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

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading,
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
                // Macro dots share the dashboard tints (protein teal, carbs
                // gold, fat clay) — same language as the client home rows.
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
                Text('${meal.calories}', style: VType.stat(22).copyWith(color: t.ink)),
                Text(' ${context.l10n.kcal}',
                    style: VType.caption.copyWith(color: t.inkTertiary)),
              ],
            ),
          ),
        ],
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

  // ==========================================================================
  //  WORKOUT — one surface card, per-exercise blocks separated by hairlines,
  //  per-set quiet rows (design.md §5.12).
  // ==========================================================================
  Widget _buildWorkoutCard(String clientId, DateTime selectedDate) {
    final t = context.tokens;
    return StreamBuilder<AssignedWorkout?>(
      stream: _assignedWorkoutStreamFor(selectedDate),
      builder: (context, snapshot) {
        final workout = snapshot.data;
        if (workout == null) {
          return _quietCard(
            child: Text(
              context.l10n.noWorkoutAssignedLib,
              style: VType.body.copyWith(color: t.inkSecondary),
            ),
          );
        }

        final exercises = workout.exercises;
        final totalSets = exercises.fold<int>(0, (s, e) => s + e.sets);
        final doneSets = exercises.fold<int>(0, (s, e) => s + _loggedDoneSets(e));
        final setProgress = totalSets > 0 ? doneSets / totalSets : 0.0;
        final reduceMotion = MediaQuery.of(context).disableAnimations;

        return _quietCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      workout.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VType.headline.copyWith(color: t.ink),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (workout.isCompleted)
                    VStatusPill(
                      variant: VStatusVariant.good,
                      label: context.l10n.done,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(VRadius.pill),
                      child: Container(
                        height: 8,
                        color: t.surfaceSubtle,
                        child: AnimatedFractionallySizedBox(
                          alignment: AlignmentDirectional.centerStart,
                          widthFactor: setProgress.clamp(0.0, 1.0).toDouble(),
                          duration: reduceMotion ? Duration.zero : VDuration.fill,
                          curve: VMotion.curve,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: workout.isCompleted ? t.good : t.gold,
                              borderRadius: BorderRadius.circular(VRadius.pill),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$doneSets/$totalSets ${context.l10n.statSets.toLowerCase()}',
                    style: VType.caption.copyWith(
                      color: t.inkSecondary,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              for (final e in exercises) ...[
                const SizedBox(height: 14),
                Divider(height: 1, thickness: 1, color: t.hairline),
                const SizedBox(height: 14),
                _buildExerciseProgress(e),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Number of sets the client has actually logged reps for.
  int _loggedDoneSets(WorkoutExercise e) {
    final logs = e.loggedRepsBySet;
    var count = 0;
    for (var i = 0; i < e.sets; i++) {
      if (i < logs.length && logs[i] > 0) count++;
    }
    return count;
  }

  /// Read-only per-exercise breakdown mirroring what the client logs:
  /// each set's reps and weight (logged, falling back to the coach target).
  Widget _buildExerciseProgress(WorkoutExercise e) {
    final t = context.tokens;
    final done = _loggedDoneSets(e);
    final complete = done >= e.sets && e.sets > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                e.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VType.body.copyWith(color: t.ink, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            if (complete)
              Icon(PhosphorIconsFill.checkCircle, size: 16, color: t.good)
            else
              Text(
                '$done/${e.sets}',
                style: VType.caption.copyWith(
                  color: t.inkSecondary,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(e.sets, (i) {
          final reps = i < e.loggedRepsBySet.length ? e.loggedRepsBySet[i] : 0;
          final logged = i < e.loggedWeightKgBySet.length ? e.loggedWeightKgBySet[i] : null;
          final target = i < e.targetWeightKgBySet.length ? e.targetWeightKgBySet[i] : null;
          final weight = logged ?? target;
          final dn = reps > 0;
          return Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  dn ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.circle,
                  size: 15,
                  color: dn ? t.good : t.inkTertiary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.setNumberLabel(i + 1),
                  style: VType.caption.copyWith(color: t.inkSecondary),
                ),
                const Spacer(),
                Text(
                  dn
                      ? '$reps ${context.l10n.statReps.toLowerCase()}'
                      : context.l10n.pendingTarget(e.reps),
                  style: VType.subhead.copyWith(
                    color: dn ? t.ink : t.inkTertiary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (weight != null) ...[
                  Text('  ·  ', style: VType.subhead.copyWith(color: t.inkTertiary)),
                  Text(
                    _weightStr(weight),
                    style: VType.subhead.copyWith(
                      color: logged != null ? t.goldDeep : t.inkSecondary,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  // ==========================================================================
  //  DATE STRIP — client-home calendar cells (transparent on canvas, selected
  //  = ink fill, today = gold dot), newest pinned at the trailing edge.
  // ==========================================================================
  Widget _buildCoachDateStrip() {
    final now = DateTime.now();
    // Newest-first + reversed list = today sits at the trailing edge and is on
    // screen at open (the old strip started scrolled to the oldest day).
    final days = List.generate(
      14,
      (i) => DateTime(now.year, now.month, now.day - i),
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
          child: _calendarCell(days[i], now),
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
          color: isSelected ? t.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(VRadius.input),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              narrow[day.weekday % 7],
              style: VType.caption.copyWith(
                color: isSelected ? t.onInk.withValues(alpha: 0.7) : t.inkTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${day.day}',
              style: VType.stat(16).copyWith(
                color: isSelected ? t.onInk : t.ink,
              ),
            ),
            if (isToday) ...[
              const SizedBox(height: 3),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(color: t.gold, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  //  ANALYTICS TAB — the shared charts section (inherits the §5.8 pilot).
  // ==========================================================================
  Widget _buildAnalyticsTab(AppUser client) {
    final t = context.tokens;
    final targets = client.targetMacros ?? const TargetMacros();
    return StreamBuilder<List<DailyLog>>(
      stream: _recentLogsStreamFor(_selectedRange.days),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: t.gold));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              context.l10n.loadAnalyticsError,
              style: VType.body.copyWith(color: t.inkSecondary),
            ),
          );
        }

        return ProgressChartsSection(
          logs: snapshot.data ?? const <DailyLog>[],
          targets: targets,
          weightUnit: client.weightUnit,
          selectedRange: _selectedRange,
          onRangeChanged: (value) => setState(() => _selectedRange = value),
        );
      },
    );
  }

  // ==========================================================================
  //  SWAP / EDIT / DELETE WORKOUT (all VSheets)
  // ==========================================================================

  /// Replaces the selected day's workout with a different template via a
  /// VSheet picker (_SwapWorkoutSheet). Assigning overwrites the day's doc,
  /// which resets any progress the client had logged — acceptable: a swap
  /// means "do this instead".
  Future<void> _showSwapWorkoutDialog(AppUser client, DateTime date) async {
    final coachId = client.coachId?.trim();
    if (coachId == null || coachId.isEmpty) {
      _toast(context.l10n.noCoachLinked);
      return;
    }

    final templates = await _firestoreService.getWorkoutTemplates(coachId);
    if (!mounted) return;
    if (templates.isEmpty) {
      _toast(context.l10n.noLibraryWorkouts);
      return;
    }

    final selected = await showVSheet<WorkoutTemplate>(
      context: context,
      builder: (_) => _SwapWorkoutSheet(
        templates: templates,
        clientName: _firstName(client.name),
        date: date,
      ),
    );
    if (selected == null) return;

    try {
      await _firestoreService.assignWorkoutToClient(
        coachId: coachId,
        clientId: client.uid,
        date: date,
        title: selected.name,
        exercises: selected.exercises,
      );
      if (!mounted) return;
      _toast(context.l10n.workoutAssignedName(selected.name));
    } catch (_) {
      if (!mounted) return;
      _toast(context.l10n.assignWorkoutErr);
    }
  }

  Future<void> _showEditWorkoutDialog(AssignedWorkout workout) async {
    final titleController = TextEditingController(text: workout.title);
    final exerciseNameControllers = workout.exercises
        .map((e) => TextEditingController(text: e.name))
        .toList();
    final sets = workout.exercises.map((e) => e.sets).toList();
    final reps = workout.exercises.map((e) => e.reps).toList();
    final targetWeights = workout.exercises
        .map((e) => e.targetWeightKgBySet.isEmpty ? null : e.targetWeightKgBySet.first)
        .toList();

    final shouldSave = await showVSheet<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final t = ctx.tokens;

          Widget stepBtn(IconData icon, VoidCallback onTap) => VPressable(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: t.surfaceSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: t.ink),
                ),
              );

          Widget stepper({
            required String label,
            required String value,
            required VoidCallback onMinus,
            required VoidCallback onPlus,
            String? suffix,
          }) {
            return Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: VType.subhead.copyWith(color: t.inkSecondary),
                  ),
                ),
                stepBtn(PhosphorIconsBold.minus, onMinus),
                SizedBox(
                  width: 72,
                  child: VTextScaleCap(
                    child: Text(
                      suffix == null ? value : '$value$suffix',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: VType.stat(16).copyWith(color: t.ink),
                    ),
                  ),
                ),
                stepBtn(PhosphorIconsBold.plus, onPlus),
              ],
            );
          }

          return VSheet(
            title: ctx.l10n.updateWorkout,
            pinnedAction: VPillButton.primary(
              label: ctx.l10n.saveWorkout,
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(ctx, true);
              },
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                VField(
                  controller: titleController,
                  label: ctx.l10n.workoutTitleLabel,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 8),
                ...List.generate(exerciseNameControllers.length, (index) {
                  final canRemove = exerciseNameControllers.length > 1;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Divider(height: 1, thickness: 1, color: t.hairline),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: VField(
                              controller: exerciseNameControllers[index],
                              label: ctx.l10n.exerciseNumber(index + 1),
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                          const SizedBox(width: 10),
                          VPressable(
                            onTap: !canRemove
                                ? null
                                : () => setSheetState(() {
                                      exerciseNameControllers.removeAt(index).dispose();
                                      sets.removeAt(index);
                                      reps.removeAt(index);
                                      targetWeights.removeAt(index);
                                    }),
                            enableFeedback: canRemove,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: t.alert.withValues(alpha: canRemove ? 0.12 : 0.05),
                                borderRadius: BorderRadius.circular(VRadius.input),
                              ),
                              child: Icon(
                                PhosphorIconsBold.trash,
                                size: 18,
                                color: t.alert.withValues(alpha: canRemove ? 1 : 0.35),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      stepper(
                        label: ctx.l10n.statSets,
                        value: '${sets[index]}',
                        onMinus: () => setSheetState(
                            () => sets[index] = (sets[index] - 1).clamp(1, 50)),
                        onPlus: () => setSheetState(
                            () => sets[index] = (sets[index] + 1).clamp(1, 50)),
                      ),
                      const SizedBox(height: 8),
                      stepper(
                        label: ctx.l10n.statReps,
                        value: '${reps[index]}',
                        onMinus: () => setSheetState(
                            () => reps[index] = (reps[index] - 1).clamp(1, 100)),
                        onPlus: () => setSheetState(
                            () => reps[index] = (reps[index] + 1).clamp(1, 100)),
                      ),
                      const SizedBox(height: 8),
                      stepper(
                        label: ctx.l10n.targetWeightLabel,
                        suffix: targetWeights[index] == null ? '' : ' $_weightUnitLabel',
                        // Edited in the client's unit; stored as kg.
                        value: targetWeights[index] == null
                            ? '—'
                            : _formatNumber(displayWeight(targetWeights[index]!, _unit)),
                        onMinus: () => setSheetState(() {
                          final inc = isMetricWeight(_unit) ? 2.5 : 5.0;
                          final disp = displayWeight(targetWeights[index] ?? 0, _unit) - inc;
                          targetWeights[index] = disp <= 0
                              ? null
                              : weightToKg(disp.clamp(0, 2000).toDouble(), _unit);
                        }),
                        onPlus: () => setSheetState(() {
                          final inc = isMetricWeight(_unit) ? 2.5 : 5.0;
                          final disp = (displayWeight(targetWeights[index] ?? 0, _unit) + inc)
                              .clamp(0, 2000)
                              .toDouble();
                          targetWeights[index] = weightToKg(disp, _unit);
                        }),
                      ),
                      const SizedBox(height: 4),
                    ],
                  );
                }),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: VTextAction(
                    icon: PhosphorIconsBold.plus,
                    label: ctx.l10n.addExercise,
                    onTap: () => setSheetState(() {
                      exerciseNameControllers.add(TextEditingController());
                      sets.add(3);
                      reps.add(10);
                      targetWeights.add(null);
                    }),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final nameValues = exerciseNameControllers.map((c) => c.text.trim()).toList();
    for (final c in exerciseNameControllers) {
      c.dispose();
    }
    final title = titleController.text.trim();
    titleController.dispose();

    if (shouldSave != true) return;
    final exercises = <WorkoutExercise>[];
    for (var i = 0; i < nameValues.length; i++) {
      if (nameValues[i].isEmpty) continue;
      final existing = i < workout.exercises.length ? workout.exercises[i] : null;
      final oldLogs = existing?.loggedRepsBySet ?? const <int>[];
      final oldWeightLogs = existing?.loggedWeightKgBySet ?? const <double?>[];
      final newSets = sets[i];
      final newLogs = oldLogs.length >= newSets
          ? oldLogs.take(newSets).toList()
          : [...oldLogs, ...List.generate(newSets - oldLogs.length, (_) => 0)];
      final newWeightLogs = oldWeightLogs.length >= newSets
          ? oldWeightLogs.take(newSets).toList()
          : [...oldWeightLogs, ...List.generate(newSets - oldWeightLogs.length, (_) => null)];
      exercises.add(
        WorkoutExercise(
          name: nameValues[i],
          sets: newSets,
          reps: reps[i],
          completedSets: newLogs.where((v) => v > 0).length,
          loggedRepsBySet: newLogs,
          targetWeightKgBySet: List.generate(newSets, (_) => targetWeights[i]),
          loggedWeightKgBySet: newWeightLogs,
        ),
      );
    }
    if (title.isEmpty || exercises.isEmpty) {
      if (!mounted) return;
      _toast(context.l10n.workoutTitleRequired);
      return;
    }

    try {
      await _firestoreService.updateAssignedWorkout(
        clientId: workout.clientId,
        date: workout.date,
        title: title,
        exercises: exercises,
      );
      if (!mounted) return;
      _toast(context.l10n.workoutUpdated);
    } catch (_) {
      if (!mounted) return;
      _toast(context.l10n.updateWorkoutError);
    }
  }

  Future<void> _confirmDeleteWorkout(AssignedWorkout workout) async {
    final shouldDelete = await showVSheet<bool>(
      context: context,
      builder: (ctx) {
        final t = ctx.tokens;
        return VSheet(
          title: ctx.l10n.removeWorkoutTitle,
          scrollable: false,
          pinnedAction: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VPillButton.destructive(
                label: ctx.l10n.remove,
                solid: true,
                onPressed: () => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 8),
              VPillButton.secondary(
                label: ctx.l10n.cancel,
                onPressed: () => Navigator.pop(ctx, false),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                ctx.l10n.removeWorkoutMsg,
                style: VType.body.copyWith(color: t.inkSecondary),
              ),
            ),
          ),
        );
      },
    );
    if (shouldDelete != true) return;
    try {
      await _firestoreService.deleteAssignedWorkout(
        clientId: workout.clientId,
        date: workout.date,
      );
      if (!mounted) return;
      _toast(context.l10n.workoutRemoved);
    } catch (_) {
      if (!mounted) return;
      _toast(context.l10n.removeWorkoutError);
    }
  }

  // ==========================================
  // CUSTOM HABITS (coach-managed, additive)
  // ==========================================
  Widget _buildHabitsCard(AppUser client) {
    final t = context.tokens;
    final habits = client.customHabits ?? const <HabitDefinition>[];
    return VGroupCard(
      dividerInset: 54,
      header: VListHeader(
        title: context.l10n.dailyHabits,
        count: habits.isEmpty ? null : habits.length,
        trailing: VMiniPill(
          icon: habits.isEmpty ? PhosphorIconsBold.plus : PhosphorIconsBold.pencilSimple,
          label: habits.isEmpty ? context.l10n.addHabits : context.l10n.manageHabits,
          onTap: () => _manageHabits(client),
        ),
      ),
      children: habits.isEmpty
          ? [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 14),
                child: Text(
                  context.l10n.noCustomHabitsBody,
                  style: VType.subhead.copyWith(color: t.inkSecondary),
                ),
              ),
            ]
          : [
              for (final h in habits)
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 8, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: t.tintFill(t.gold),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _habitIconData(h.icon),
                          size: 15,
                          color: t.legibleTint(t.gold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          h.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VType.body.copyWith(
                            color: t.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
    );
  }

  Future<void> _manageHabits(AppUser client) async {
    final result = await showVSheet<List<HabitDefinition>>(
      context: context,
      builder: (_) => _HabitsManagerSheet(initial: client.customHabits ?? const []),
    );
    if (result == null || !mounted) return;
    try {
      await _firestoreService.setClientHabits(client.uid, result);
      if (!mounted) return;
      _toast(context.l10n.habitsUpdated);
    } catch (_) {
      if (!mounted) return;
      _toast(context.l10n.saveHabitsError);
    }
  }

  // ==========================================================================
  //  PLAN TAB — macro targets (VStatColumns + edit) · habits · day's workout
  // ==========================================================================
  Widget _buildPlanTab(AppUser client) {
    final t = context.tokens;
    final targets = client.targetMacros ?? const TargetMacros();
    final isUnconfigured =
        (client.status ?? ClientStatus.unconfigured) == ClientStatus.unconfigured;

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        VSpace.screenMargin,
        16,
        VSpace.screenMargin,
        VSpace.scrollBottom + 72,
      ),
      physics: const BouncingScrollPhysics(),
      children: [
        _quietCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.macroTargets,
                      style: VType.headline.copyWith(color: t.ink),
                    ),
                  ),
                  if (!isUnconfigured)
                    _isSavingMacros
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: t.gold),
                          )
                        : VMiniPill(
                            icon: PhosphorIconsBold.pencilSimple,
                            label: context.l10n.editMacros,
                            onTap: () => _configureMacros(client),
                          ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: VStatColumn(
                      icon: PhosphorIconsFill.fire,
                      tint: t.gold,
                      value: '${targets.calories}',
                      label: context.l10n.kcal,
                      statSize: 18,
                    ),
                  ),
                  Expanded(
                    child: VStatColumn(
                      icon: PhosphorIconsFill.fish,
                      tint: t.teal,
                      value: '${targets.protein}g',
                      label: context.l10n.macroProtein,
                      statSize: 18,
                    ),
                  ),
                  Expanded(
                    child: VStatColumn(
                      icon: PhosphorIconsFill.bread,
                      tint: t.gold,
                      value: '${targets.carbs}g',
                      label: context.l10n.macroCarbs,
                      statSize: 18,
                    ),
                  ),
                  Expanded(
                    child: VStatColumn(
                      icon: PhosphorIconsFill.cheese,
                      tint: t.clay,
                      value: '${targets.fat}g',
                      label: context.l10n.macroFat,
                      statSize: 18,
                    ),
                  ),
                ],
              ),
              if (isUnconfigured) ...[
                const SizedBox(height: 18),
                VPillButton.primary(
                  label: context.l10n.configureMacros,
                  loading: _isSavingMacros,
                  onPressed: () => _configureMacros(client),
                ),
                const SizedBox(height: 10),
                Text(
                  context.l10n.savingMacrosConfigures,
                  style: VType.caption.copyWith(color: t.inkSecondary),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: VSpace.cardGap),
        _buildHabitsCard(client),
        const SizedBox(height: VSpace.sectionGap),
        _sectionHead(
          context.l10n.workoutLogTitle('${_selectedDate.month}/${_selectedDate.day}'),
          actionLabel: context.l10n.swapWorkout,
          onAction: () => _showSwapWorkoutDialog(client, _selectedDate),
        ),
        const SizedBox(height: 16),
        StreamBuilder<AssignedWorkout?>(
          stream: _assignedWorkoutStreamFor(_selectedDate),
          builder: (context, snapshot) {
            final workout = snapshot.data;
            if (workout == null) {
              return _quietCard(
                child: Text(
                  context.l10n.noWorkoutSelectedDay,
                  style: VType.body.copyWith(color: t.inkSecondary),
                ),
              );
            }
            return _quietCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VType.headline.copyWith(color: t.ink),
                  ),
                  const SizedBox(height: 6),
                  for (final e in workout.exercises)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: VType.body.copyWith(
                                color: t.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${e.sets} × ${e.reps}'
                            '${e.targetWeightKgBySet.isNotEmpty && e.targetWeightKgBySet.first != null ? '  ·  ${_weightStr(e.targetWeightKgBySet.first!)}' : ''}',
                            style: VType.subhead.copyWith(
                              color: t.inkSecondary,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      VMiniPill(
                        icon: PhosphorIconsBold.pencilSimple,
                        label: context.l10n.updateBtn,
                        onTap: () => _showEditWorkoutDialog(workout),
                      ),
                      const Spacer(),
                      VTextAction(
                        label: context.l10n.remove,
                        color: t.alert,
                        onTap: () => _confirmDeleteWorkout(workout),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// The one card treatment (§1.5): `surface`, r24, single soft shadow,
  /// no border.
  Widget _quietCard({required Widget child}) {
    final t = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VSpace.cardPadding),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        boxShadow: t.cardShadow,
      ),
      child: child,
    );
  }
}

// ===========================================================================
// Mini stat card — tinted icon circle · naked value · quiet label. Read-only
// sibling of the client home habit cards.
// ===========================================================================

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(VRadius.cardSmall),
        boxShadow: t.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: t.isLight ? 0.18 : 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: t.legibleTint(tint)),
          ),
          const SizedBox(height: 12),
          VTextScaleCap(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VType.stat(17).copyWith(color: t.ink),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: VType.caption.copyWith(color: t.inkSecondary),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Nutrition mirror — same components as the client home §5.6 (fire hero +
// tinted macro columns). KEEP IN SYNC with client_home_screen.dart: the two
// sides must always show the same picture.
// ===========================================================================

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
                      duration: reduceMotion ? Duration.zero : VDuration.countUp,
                      curve: VMotion.curve,
                      builder: (context, v, _) => Text(
                        v.round().toString(),
                        style: VType.display.copyWith(color: over ? t.alert : t.ink),
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

class _MacroStat extends StatelessWidget {
  const _MacroStat({
    required this.icon,
    required this.tint,
    required this.label,
    required this.current,
    required this.target,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final int current;
  final int target;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final over = current > target;
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
                  style: VType.stat(22).copyWith(color: over ? t.alert : t.ink)),
              Text(
                over ? ' +${current - target}g' : ' / ${target}g',
                style: VType.caption.copyWith(
                  color: over ? t.alert : t.inkTertiary,
                  fontWeight: over ? FontWeight.w700 : FontWeight.w500,
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
                      color: over ? t.alert : tint,
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

// ===========================================================================
// Coach note editor — shows & edits the existing note for the day (overwrites,
// never appends). Keyed by date so switching days reloads the right note.
// ===========================================================================

class _CoachNoteEditor extends StatefulWidget {
  final String? initialNote;
  final String firstName;
  final bool isToday;
  final Future<bool> Function(String text) onSave;

  const _CoachNoteEditor({
    super.key,
    required this.initialNote,
    required this.firstName,
    required this.isToday,
    required this.onSave,
  });

  @override
  State<_CoachNoteEditor> createState() => _CoachNoteEditorState();
}

class _CoachNoteEditorState extends State<_CoachNoteEditor> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialNote ?? '');
  late String _saved = (widget.initialNote ?? '').trim();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasText => _controller.text.trim().isNotEmpty;
  bool get _dirty => _controller.text.trim() != _saved;

  Future<void> _save() async {
    if (_saving || !_dirty || !_hasText) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    final ok = await widget.onSave(_controller.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _saved = _controller.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hasSaved = _saved.isNotEmpty;
    final canSave = _dirty && _hasText && !_saving;

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        boxShadow: t.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hasSaved ? context.l10n.yourNote : context.l10n.leaveANote,
                  style: VType.subhead.copyWith(
                    color: t.inkSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hasSaved && !_dirty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsFill.checkCircle, size: 13, color: t.good),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.savedLabel,
                      style: VType.caption.copyWith(
                        color: t.good,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          VField(
            controller: _controller,
            hint: context.l10n.writeFeedbackFor(widget.firstName),
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!widget.isToday)
                Expanded(
                  child: Text(
                    context.l10n.editingPastDay,
                    style: VType.caption.copyWith(color: t.inkTertiary),
                  ),
                )
              else
                const Spacer(),
              VPillButton.primary(
                label: hasSaved ? context.l10n.updateNote : context.l10n.saveNote,
                loading: _saving,
                expand: false,
                onPressed: canSave ? _save : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Swap workout — VSheet with VOptionCard template picks (design.md §5.12).
// Returns the chosen template via Navigator.pop, or null on cancel.
// ===========================================================================

class _SwapWorkoutSheet extends StatefulWidget {
  final List<WorkoutTemplate> templates;
  final String clientName;
  final DateTime date;

  const _SwapWorkoutSheet({
    required this.templates,
    required this.clientName,
    required this.date,
  });

  @override
  State<_SwapWorkoutSheet> createState() => _SwapWorkoutSheetState();
}

class _SwapWorkoutSheetState extends State<_SwapWorkoutSheet> {
  late WorkoutTemplate _selected = widget.templates.first;

  String get _dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(widget.date.year, widget.date.month, widget.date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return context.l10n.relToday;
    if (diff == 1) return context.l10n.relTomorrow;
    if (diff == -1) return context.l10n.relYesterday;
    return '${widget.date.day}/${widget.date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return VSheet(
      title: context.l10n.forClientDate(widget.clientName, _dateLabel),
      scrollable: false,
      pinnedAction: VPillButton.primary(
        label: context.l10n.assignWorkoutBtn,
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop(_selected);
        },
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.chooseAWorkout,
            style: VType.subhead.copyWith(color: t.inkSecondary),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 264),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.templates.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final template = widget.templates[index];
                  return VOptionCard(
                    icon: PhosphorIconsFill.barbell,
                    label: template.name,
                    subtitle: context.l10n.exerciseCount(template.exercises.length),
                    selected: template.id == _selected.id,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selected = template);
                    },
                  );
                },
              ),
            ),
          ),
          if (_selected.exercises.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              context.l10n.includesLabel,
              style: VType.subhead.copyWith(
                color: t.inkSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    for (final e in _selected.exercises)
                      Text(
                        '${e.name} · ${e.sets}×${e.reps}',
                        style: VType.caption.copyWith(
                          color: t.inkSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ===========================================================================
// Custom-habit icon set (shared keys with the client home resolver)
// ===========================================================================

const List<String> _habitIconKeys = [
  'footprints', 'drop', 'barbell', 'pill', 'forkKnife',
  'moon', 'heartbeat', 'sun', 'leaf', 'prohibit',
];

IconData _habitIconData(String key) {
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

// ===========================================================================
// Habits manager — add / edit / remove a client's custom habits (VSheet)
// ===========================================================================

class _HabitsManagerSheet extends StatefulWidget {
  final List<HabitDefinition> initial;
  const _HabitsManagerSheet({required this.initial});

  @override
  State<_HabitsManagerSheet> createState() => _HabitsManagerSheetState();
}

class _HabitsManagerSheetState extends State<_HabitsManagerSheet> {
  late final List<HabitDefinition> _habits = List.of(widget.initial);
  final _nameController = TextEditingController();
  String _icon = _habitIconKeys.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _add() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _habits.add(HabitDefinition(
        id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
        name: name,
        icon: _icon,
      ));
      _nameController.clear();
    });
  }

  void _remove(String id) {
    HapticFeedback.selectionClick();
    setState(() => _habits.removeWhere((h) => h.id == id));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return VSheet(
      title: context.l10n.dailyHabits,
      pinnedAction: VPillButton.primary(
        label: context.l10n.saveHabits,
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop(_habits);
        },
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.habitsManagerBody,
            style: VType.subhead.copyWith(color: t.inkSecondary),
          ),
          if (_habits.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final h in _habits)
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: t.tintFill(t.gold),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _habitIconData(h.icon),
                        size: 16,
                        color: t.legibleTint(t.gold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        h.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VType.body.copyWith(
                          color: t.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    VPressable(
                      onTap: () => _remove(h.id),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(PhosphorIconsBold.trash, size: 18, color: t.alert),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 16),
          Text(
            context.l10n.addAHabit,
            style: VType.subhead.copyWith(
              color: t.inkSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _habitIconKeys.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final key = _habitIconKeys[i];
                final sel = key == _icon;
                return VPressable(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _icon = key);
                  },
                  child: AnimatedContainer(
                    duration: VDuration.micro,
                    curve: VMotion.curve,
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: sel
                          ? Color.alphaBlend(t.selectedWash, t.surface)
                          : t.surfaceSubtle,
                      borderRadius: BorderRadius.circular(VRadius.squircle),
                      border: Border.all(
                        color: sel ? t.gold : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _habitIconData(key),
                      size: 19,
                      color: sel ? t.legibleTint(t.gold) : t.inkSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: VField(
                  controller: _nameController,
                  hint: context.l10n.habitNameHint,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 10),
              VPressable(
                onTap: _add,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: t.ink,
                    borderRadius: BorderRadius.circular(VRadius.input),
                  ),
                  child: Icon(PhosphorIconsBold.plus, size: 20, color: t.onInk),
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

/// The four macro values as trimmed strings, returned by [_MacroEditorSheet].
/// The caller parses + validates so the sheet stays purely about input.
class _MacroDraft {
  final String calories;
  final String protein;
  final String carbs;
  final String fat;
  const _MacroDraft(this.calories, this.protein, this.carbs, this.fat);
}

/// Macro-targets editor (VSheet — design.md §5.12: AlertDialog retired). Owns
/// its TextEditingControllers and disposes them in [dispose] — which the
/// framework runs after the sheet subtree is fully detached, avoiding the
/// teardown-order crash that disposing right after the pop used to cause
/// (a focused field being torn out from under its inherited scope).
class _MacroEditorSheet extends StatefulWidget {
  final TargetMacros initial;
  final String clientFirstName;

  const _MacroEditorSheet({
    required this.initial,
    required this.clientFirstName,
  });

  @override
  State<_MacroEditorSheet> createState() => _MacroEditorSheetState();
}

class _MacroEditorSheetState extends State<_MacroEditorSheet> {
  late final TextEditingController _calories =
      TextEditingController(text: widget.initial.calories.toString());
  late final TextEditingController _protein =
      TextEditingController(text: widget.initial.protein.toString());
  late final TextEditingController _carbs =
      TextEditingController(text: widget.initial.carbs.toString());
  late final TextEditingController _fat =
      TextEditingController(text: widget.initial.fat.toString());

  @override
  void dispose() {
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  void _save() {
    HapticFeedback.mediumImpact();
    // Drop focus before popping so no field is torn down mid-focus.
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(
      context,
      _MacroDraft(
        _calories.text.trim(),
        _protein.text.trim(),
        _carbs.text.trim(),
        _fat.text.trim(),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, String unit,
      IconData icon, Color tint) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: VField(
        controller: c,
        label: label,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        prefix: Icon(icon, size: 18, color: t.legibleTint(tint)),
        suffix: Text(unit, style: VType.caption.copyWith(color: t.inkTertiary)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return VSheet(
      title: context.l10n.dailyGoalsName(widget.clientFirstName),
      pinnedAction: VPillButton.primary(
        label: context.l10n.saveTargets,
        onPressed: _save,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          _field(_calories, context.l10n.caloriesLabel, 'kcal',
              PhosphorIconsFill.fire, t.gold),
          _field(_protein, context.l10n.macroProtein, 'g',
              PhosphorIconsFill.fish, t.teal),
          _field(_carbs, context.l10n.macroCarbs, 'g',
              PhosphorIconsFill.bread, t.gold),
          _field(_fat, context.l10n.macroFat, 'g',
              PhosphorIconsFill.cheese, t.clay),
        ],
      ),
    );
  }
}
