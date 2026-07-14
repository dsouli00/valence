import 'package:flutter/material.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/models/workout_models.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/ui/ui.dart';
import 'package:valence/utils/units.dart';

/// Workouts tab — shows the coach-assigned workout for the selected day and
/// lets the client log it with as little friction as possible: tapping a set
/// row logs the TARGET reps in one tap (tap again to clear), with compact
/// reps/weight fields for fine-tuning. Day-done state is derived server-side
/// from the per-set data, so there's no separate "finish workout" bookkeeping
/// to get out of sync.
///
/// Weights are entered/displayed in the user's unit but stored canonical kg
/// (utils/units.dart). Past days are read-only; no workout doc for the day =
/// rest-day empty state.
///
/// DESIGN (§5.7): VHeader + the home-screen calendar cells → hero card with
/// `title2` + ONE gold fill bar (the ring was rejected on device for the home
/// hero — bars are the house language, v2.5) → collapsible exercise cards with
/// tap-to-complete set rows (gold check circles, quiet fields) → primary pill
/// to mark the day complete. Rest day = VEmpty.
class ClientWorkoutsScreen extends StatefulWidget {
  const ClientWorkoutsScreen({super.key});

  @override
  State<ClientWorkoutsScreen> createState() => _ClientWorkoutsScreenState();
}

class _ClientWorkoutsScreenState extends State<ClientWorkoutsScreen> {
  final _firestoreService = FirestoreService();
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Cache the assigned-workout stream so rebuilds (e.g. the keyboard opening to
  // log reps/weight) don't restart it and flash the loading state.
  String? _woUid;
  DateTime? _woDate;
  Stream<AssignedWorkout?>? _woStream;
  Stream<AssignedWorkout?> _workoutStreamFor(String uid, DateTime date) {
    if (_woStream == null || _woUid != uid || !_isSameDay(_woDate!, date)) {
      _woUid = uid;
      _woDate = date;
      _woStream = _firestoreService.streamAssignedWorkoutForDate(uid, date);
    }
    return _woStream!;
  }

  List<DateTime> _calendarDays() {
    final now = DateTime.now();
    return List.generate(
      7,
      (index) => DateTime(now.year, now.month, now.day - (6 - index)),
    );
  }

  List<int> _normalizedSetLogs(WorkoutExercise exercise) {
    if (exercise.loggedRepsBySet.length >= exercise.sets) {
      return exercise.loggedRepsBySet.take(exercise.sets).toList();
    }
    return [
      ...exercise.loggedRepsBySet,
      ...List.generate(exercise.sets - exercise.loggedRepsBySet.length, (_) => 0),
    ];
  }

  Future<void> _updateSetReps({
    required String clientId,
    required int exerciseIndex,
    required int setIndex,
    required int repsDone,
  }) {
    return _firestoreService.updateWorkoutSetRep(
      clientId: clientId,
      date: _selectedDate,
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      repsDone: repsDone,
    );
  }

  /// "Mark whole exercise done/undone" = writing target reps (or 0) to every
  /// set. Sequential awaits, not parallel — each write is a transaction on
  /// the same doc, so firing them concurrently would just make them retry
  /// against each other.
  Future<void> _setExerciseDone({
    required String clientId,
    required WorkoutExercise exercise,
    required int exerciseIndex,
    required bool done,
  }) async {
    for (var i = 0; i < exercise.sets; i++) {
      await _updateSetReps(
        clientId: clientId,
        exerciseIndex: exerciseIndex,
        setIndex: i,
        repsDone: done ? exercise.reps : 0,
      );
    }
  }

  Future<void> _updateSetWeight({
    required String clientId,
    required int exerciseIndex,
    required int setIndex,
    required double? weightKg,
  }) {
    return _firestoreService.updateWorkoutSetWeight(
      clientId: clientId,
      date: _selectedDate,
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      weightKg: weightKg,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: t.canvas,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: t.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: VSpace.screenMargin),
              child: VHeader(title: context.l10n.navWorkouts),
            ),
            const SizedBox(height: 16),
            _DayStrip(
              days: _calendarDays(),
              selected: _selectedDate,
              onSelect: (d) {
                HapticFeedback.selectionClick();
                setState(() => _selectedDate = d);
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<AssignedWorkout?>(
                stream: _workoutStreamFor(user.uid, _selectedDate),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _WorkoutSkeleton();
                  }
                  final workout = snapshot.data;
                  final isToday = _isSameDay(_selectedDate, DateTime.now());
                  if (workout == null) {
                    return VEmpty(
                      icon: PhosphorIconsRegular.barbell,
                      title: context.l10n.restDay,
                      message: isToday
                          ? context.l10n.restDayTodayBody
                          : context.l10n.restDayPastBody,
                    );
                  }
                  return _buildWorkout(user.uid, workout, isToday);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkout(String clientId, AssignedWorkout workout, bool isToday) {
    final exercises = workout.exercises;
    final totalSets = exercises.fold<int>(0, (s, e) => s + e.sets);
    final doneSets = exercises.fold<int>(
      0,
      (s, e) => s + _normalizedSetLogs(e).where((r) => r > 0).length,
    );

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsetsDirectional.fromSTEB(
        VSpace.screenMargin,
        8,
        VSpace.screenMargin,
        VSpace.scrollBottom + 72,
      ),
      children: [
        _WorkoutHero(
          workout: workout,
          totalSets: totalSets,
          doneSets: doneSets,
          isToday: isToday,
          onToggleDone: (v) {
            HapticFeedback.mediumImpact();
            _firestoreService.setAssignedWorkoutDone(
              clientId: clientId,
              date: _selectedDate,
              isDone: v,
            );
          },
        ),
        const SizedBox(height: 16),
        ...List.generate(exercises.length, (index) {
          final exercise = exercises[index];
          return Padding(
            padding: const EdgeInsetsDirectional.only(bottom: VSpace.cardGap),
            child: _ExerciseCard(
              key: ValueKey('ex_${workout.id}_$index'),
              exercise: exercise,
              index: index,
              isToday: isToday,
              setLogs: _normalizedSetLogs(exercise),
              onSetReps: (setIdx, reps) => _updateSetReps(
                clientId: clientId,
                exerciseIndex: index,
                setIndex: setIdx,
                repsDone: reps,
              ),
              onSetWeight: (setIdx, weight) => _updateSetWeight(
                clientId: clientId,
                exerciseIndex: index,
                setIndex: setIdx,
                weightKg: weight,
              ),
              onToggleComplete: (done) => _setExerciseDone(
                clientId: clientId,
                exercise: exercise,
                exerciseIndex: index,
                done: done,
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ===========================================================================
// Day strip — the home-screen calendar cells (§5.7 "same calendar cells"):
// transparent on canvas, selected = ink fill, today = gold dot.
// ===========================================================================

class _DayStrip extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  const _DayStrip({required this.days, required this.selected, required this.onSelect});

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final now = DateTime.now();
    final narrow = MaterialLocalizations.of(context).narrowWeekdays;

    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.symmetric(
            horizontal: VSpace.screenMargin),
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = _isSameDay(day, selected);
          final isToday = _isSameDay(day, now);
          return VPressable(
            onTap: () => onSelect(DateTime(day.year, day.month, day.day)),
            child: AnimatedContainer(
              duration: VDuration.standard,
              curve: VMotion.curve,
              width: 48,
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
                      color: isSelected
                          ? t.onInk.withValues(alpha: 0.7)
                          : t.inkTertiary,
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
                      decoration:
                          BoxDecoration(color: t.gold, shape: BoxShape.circle),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ===========================================================================
// Workout hero — title + quiet stats + ONE gold fill bar + primary CTA.
// ===========================================================================

class _WorkoutHero extends StatelessWidget {
  final AssignedWorkout workout;
  final int totalSets;
  final int doneSets;
  final bool isToday;
  final ValueChanged<bool> onToggleDone;

  const _WorkoutHero({
    required this.workout,
    required this.totalSets,
    required this.doneSets,
    required this.isToday,
    required this.onToggleDone,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final done = workout.isCompleted;
    final progress =
        totalSets > 0 ? (doneSets / totalSets).clamp(0.0, 1.0).toDouble() : 0.0;

    return Container(
      padding: const EdgeInsets.all(VSpace.cardPaddingHero),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        boxShadow: t.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  workout.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: VType.title2.copyWith(color: t.ink),
                ),
              ),
              if (done) ...[
                const SizedBox(width: 8),
                VStatusPill(
                  variant: VStatusVariant.good,
                  label: context.l10n.done,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n
                .workoutExercisesSets(workout.exercises.length, doneSets, totalSets),
            style: VType.subhead.copyWith(
              color: t.inkSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(VRadius.pill),
            child: Container(
              height: 10,
              color: t.surfaceSubtle,
              child: AnimatedFractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: progress,
                duration: reduceMotion ? Duration.zero : VDuration.fill,
                curve: VMotion.curve,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: done ? t.good : t.gold,
                    borderRadius: BorderRadius.circular(VRadius.pill),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isToday)
            done
                ? VPillButton.secondary(
                    label: context.l10n.markNotDone,
                    icon: PhosphorIconsBold.arrowCounterClockwise,
                    onPressed: () => onToggleDone(false),
                  )
                : VPillButton.primary(
                    label: context.l10n.markComplete,
                    icon: PhosphorIconsFill.checkCircle,
                    onPressed: () => onToggleDone(true),
                  )
          else
            Row(
              children: [
                Icon(PhosphorIconsRegular.lockSimple,
                    size: 14, color: t.inkTertiary),
                const SizedBox(width: 6),
                Text(
                  context.l10n.pastWorkoutViewOnly,
                  style: VType.caption.copyWith(color: t.inkSecondary),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Exercise card (collapsible, with per-set logging)
// ===========================================================================

class _ExerciseCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final int index;
  final bool isToday;
  final List<int> setLogs;
  final Future<void> Function(int setIdx, int reps) onSetReps;
  final Future<void> Function(int setIdx, double? weight) onSetWeight;
  final Future<void> Function(bool done) onToggleComplete;

  const _ExerciseCard({
    super.key,
    required this.exercise,
    required this.index,
    required this.isToday,
    required this.setLogs,
    required this.onSetReps,
    required this.onSetWeight,
    required this.onToggleComplete,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    // Start expanded if the exercise still has work left for today.
    final done = widget.setLogs.where((r) => r > 0).length;
    _expanded = widget.isToday && done < widget.exercise.sets;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final e = widget.exercise;
    final doneSets = widget.setLogs.where((r) => r > 0).length;
    final complete = doneSets >= e.sets && e.sets > 0;

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        boxShadow: t.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header (tap to expand/collapse).
          VPressable(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = !_expanded);
            },
            overlay: true,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: t.tintFill(complete ? t.good : t.gold),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      complete
                          ? PhosphorIconsFill.checkCircle
                          : PhosphorIconsFill.barbell,
                      size: 18,
                      color: complete ? t.good : t.legibleTint(t.gold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VType.headline.copyWith(color: t.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.exerciseSetsTarget(doneSets, e.sets, e.reps),
                          style: VType.caption.copyWith(
                            color: t.inkSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$doneSets/${e.sets}',
                    style: VType.stat(15).copyWith(
                      color: complete ? t.good : t.inkSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: VDuration.standard,
                    curve: VMotion.curve,
                    child: Icon(PhosphorIconsBold.caretDown,
                        size: 14, color: t.inkTertiary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _buildSets(e, complete),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: VDuration.standard,
            sizeCurve: VMotion.curve,
          ),
        ],
      ),
    );
  }

  Widget _buildSets(WorkoutExercise e, bool complete) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          Divider(height: 1, thickness: 1, color: t.hairline),
          const SizedBox(height: 12),
          ...List.generate(e.sets, (setIdx) {
            final reps = setIdx < widget.setLogs.length ? widget.setLogs[setIdx] : 0;
            final targetWeight = setIdx < e.targetWeightKgBySet.length
                ? e.targetWeightKgBySet[setIdx]
                : null;
            final loggedWeight = setIdx < e.loggedWeightKgBySet.length
                ? e.loggedWeightKgBySet[setIdx]
                : null;
            return _SetRow(
              setNumber: setIdx + 1,
              reps: reps,
              targetReps: e.reps,
              targetWeight: targetWeight,
              loggedWeight: loggedWeight,
              isToday: widget.isToday,
              workoutKey: '${widget.key}',
              exIndex: widget.index,
              onReps: (v) => widget.onSetReps(setIdx, v),
              onWeight: (w) => widget.onSetWeight(setIdx, w),
            );
          }),
          if (widget.isToday)
            Center(
              child: VTextAction(
                icon: complete
                    ? PhosphorIconsBold.arrowCounterClockwise
                    : PhosphorIconsBold.checks,
                label: complete
                    ? context.l10n.resetExercise
                    : context.l10n.completeAllSets,
                color: complete ? t.inkSecondary : null,
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onToggleComplete(!complete);
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Set row — tap-to-complete gold check circle + quiet reps/weight fields.
// ===========================================================================

class _SetRow extends StatelessWidget {
  final int setNumber;
  final int reps;
  final int targetReps;
  final double? targetWeight;
  final double? loggedWeight;
  final bool isToday;
  final String workoutKey;
  final int exIndex;
  final ValueChanged<int> onReps;
  final ValueChanged<double?> onWeight;

  const _SetRow({
    required this.setNumber,
    required this.reps,
    required this.targetReps,
    required this.targetWeight,
    required this.loggedWeight,
    required this.isToday,
    required this.workoutKey,
    required this.exIndex,
    required this.onReps,
    required this.onWeight,
  });

  /// Compact quiet field: `surfaceSubtle` fill, no border, gold focus ring.
  Widget _numField(
    BuildContext context, {
    required String label,
    required String keyStr,
    required String initial,
    required String hint,
    required bool decimal,
    required void Function(String) onSubmit,
  }) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: VType.caption.copyWith(
            fontSize: 10,
            color: t.inkTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          height: 40,
          child: TextFormField(
            key: ValueKey(keyStr),
            initialValue: initial,
            enabled: isToday,
            keyboardType: decimal
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.number,
            inputFormatters:
                decimal ? null : [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            cursorColor: t.gold,
            style: VType.stat(15).copyWith(color: t.ink),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: VType.stat(15).copyWith(
                color: t.inkTertiary.withValues(alpha: 0.6),
              ),
              filled: true,
              fillColor: t.surfaceSubtle,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: t.gold, width: 1.5),
              ),
            ),
            onFieldSubmitted: (v) {
              if (!isToday) return;
              onSubmit(v);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final done = reps > 0;
    // The client logs in their own unit; values are stored canonically in kg.
    final unit = context.read<AuthProvider>().currentUser?.weightUnit;
    final metric = isMetricWeight(unit);
    final unitLabel = metric ? context.l10n.unitKg : context.l10n.unitLb;
    String fmtW(double kg) {
      final v = displayWeight(kg, unit);
      if (!metric) return v.round().toString();
      return v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    }

    final weightStr = loggedWeight == null ? '' : fmtW(loggedWeight!);

    return AnimatedContainer(
      duration: VDuration.micro,
      curve: VMotion.curve,
      margin: const EdgeInsetsDirectional.only(bottom: 8),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        // Done = the gold selected treatment (ring + wash); pending = quiet.
        color: done
            ? Color.alphaBlend(t.selectedWash, t.surface)
            : t.surfaceSubtle.withValues(alpha: t.isLight ? 0.55 : 0.7),
        borderRadius: BorderRadius.circular(VRadius.input),
        border: Border.all(
          color: done ? t.gold : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // One-tap complete: logs the target reps (tap again to clear).
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isToday
                ? () {
                    HapticFeedback.lightImpact();
                    onReps(done ? 0 : targetReps);
                  }
                : null,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: VDuration.standard,
                  curve: VMotion.curve,
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: done ? t.gold : Colors.transparent,
                    shape: BoxShape.circle,
                    border: done
                        ? null
                        : Border.all(
                            color: t.inkTertiary.withValues(alpha: 0.45),
                            width: 2,
                          ),
                  ),
                  child: done
                      ? const Icon(PhosphorIconsBold.check,
                          size: 14, color: Color(0xFF1A1814))
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.setNumberLabel(setNumber),
                      style: VType.body.copyWith(
                        color: t.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      done
                          ? context.l10n.logged
                          : (isToday ? context.l10n.tapToLog : '—'),
                      style: VType.caption.copyWith(
                        color: done ? t.goldDeep : t.inkTertiary,
                        fontWeight: done ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          _numField(
            context,
            label: context.l10n.repsLabel,
            keyStr: 'r_${workoutKey}_${exIndex}_${setNumber}_$reps',
            initial: done ? '$reps' : '',
            hint: '$targetReps',
            decimal: false,
            onSubmit: (v) {
              final p = int.tryParse(v.trim());
              onReps((p ?? 0).clamp(0, 1000));
            },
          ),
          const SizedBox(width: 8),
          _numField(
            context,
            label: targetWeight == null
                ? unitLabel
                : '$unitLabel · ${fmtW(targetWeight!)}',
            keyStr: 'w_${workoutKey}_${exIndex}_${setNumber}_${loggedWeight ?? 'n'}',
            initial: weightStr,
            hint: targetWeight == null ? unitLabel : fmtW(targetWeight!),
            decimal: true,
            onSubmit: (v) {
              final trimmed = v.trim();
              final parsed = trimmed.isEmpty ? null : double.tryParse(trimmed);
              if (trimmed.isNotEmpty && parsed == null) {
                showVToast(context, context.l10n.enterValidWeight);
                return;
              }
              // Convert the entered display value back to canonical kg.
              onWeight(parsed == null ? null : weightToKg(parsed, unit));
            },
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Skeleton — hero card + two exercise cards.
// ===========================================================================

class _WorkoutSkeleton extends StatelessWidget {
  const _WorkoutSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.fromSTEB(
          VSpace.screenMargin, 8, VSpace.screenMargin, 0),
      children: const [
        VSkeleton(height: 170, radius: VRadius.card),
        SizedBox(height: 16),
        VSkeleton(height: 76, radius: VRadius.card),
        SizedBox(height: VSpace.cardGap),
        VSkeleton(height: 76, radius: VRadius.card),
      ],
    );
  }
}
