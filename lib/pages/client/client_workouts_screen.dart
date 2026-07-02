import 'package:flutter/material.dart';
import 'package:valence/l10n/l10n_ext.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:valence/models/workout_models.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/theme/app_theme.dart';
import 'package:valence/utils/units.dart';

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
    final user = context.watch<AuthProvider>().currentUser;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.p16, AppSpacing.p12, AppSpacing.p16, 0),
              child: Row(
                children: [
                  Text(
                    context.l10n.navWorkouts,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.p12),
            _DayStrip(
              days: _calendarDays(),
              selected: _selectedDate,
              onSelect: (d) {
                HapticFeedback.selectionClick();
                setState(() => _selectedDate = d);
              },
            ),
            SizedBox(height: AppSpacing.p8),
            Expanded(
              child: StreamBuilder<AssignedWorkout?>(
                stream: _workoutStreamFor(user.uid, _selectedDate),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final workout = snapshot.data;
                  final isToday = _isSameDay(_selectedDate, DateTime.now());
                  if (workout == null) {
                    return _EmptyState(theme: theme, isToday: isToday);
                  }
                  return _buildWorkout(theme, cs, user.uid, workout, isToday);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkout(
    ThemeData theme,
    ColorScheme cs,
    String clientId,
    AssignedWorkout workout,
    bool isToday,
  ) {
    final exercises = workout.exercises;
    final totalSets = exercises.fold<int>(0, (s, e) => s + e.sets);
    final doneSets = exercises.fold<int>(
      0,
      (s, e) => s + _normalizedSetLogs(e).where((r) => r > 0).length,
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.p16, AppSpacing.p8, AppSpacing.p16, AppSpacing.p32),
      children: [
        _WorkoutHero(
          theme: theme,
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
        SizedBox(height: AppSpacing.p16),
        ...List.generate(exercises.length, (index) {
          final exercise = exercises[index];
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.p12),
            child: _ExerciseCard(
              key: ValueKey('ex_${workout.id}_$index'),
              theme: theme,
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
// Day strip
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final now = DateTime.now();
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.p16),
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = _isSameDay(day, selected);
          final isToday = _isSameDay(day, now);
          return GestureDetector(
            onTap: () => onSelect(DateTime(day.year, day.month, day.day)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.secondaryColor.withValues(alpha: 0.14)
                    : cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.secondaryColor.withValues(alpha: 0.5)
                      : cs.outlineVariant.withValues(alpha: 0.3),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    MaterialLocalizations.of(context).narrowWeekdays[day.weekday % 7],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${day.day}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isSelected ? AppColors.secondaryColor : cs.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
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
// Workout hero
// ===========================================================================

class _WorkoutHero extends StatelessWidget {
  final ThemeData theme;
  final AssignedWorkout workout;
  final int totalSets;
  final int doneSets;
  final bool isToday;
  final ValueChanged<bool> onToggleDone;

  const _WorkoutHero({
    required this.theme,
    required this.workout,
    required this.totalSets,
    required this.doneSets,
    required this.isToday,
    required this.onToggleDone,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final done = workout.isCompleted;
    final accent = done ? AppColors.statusGreen : AppColors.secondaryColor;
    final progress = totalSets > 0 ? doneSets / totalSets : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(accent.withValues(alpha: 0.07), cs.surfaceContainerLow),
            cs.surfaceContainerLow,
          ],
          stops: const [0, 0.62],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: accent.withValues(alpha: 0.07),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 78,
                height: 78,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress.toDouble()),
                  duration: const Duration(milliseconds: 750),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 78,
                        height: 78,
                        child: CircularProgressIndicator(
                          value: value,
                          strokeWidth: 7,
                          strokeCap: StrokeCap.round,
                          backgroundColor: cs.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(value * 100).round()}',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              height: 1,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            context.l10n.pctDone.toUpperCase(),
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 8,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.p16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(PhosphorIconsFill.barbell, size: 12, color: accent),
                        const SizedBox(width: 5),
                        Text(
                          done ? context.l10n.workoutComplete.toUpperCase() : context.l10n.todaysWorkout.toUpperCase(),
                          style: textTheme.labelSmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workout.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.workoutExercisesSets(workout.exercises.length, doneSets, totalSets),
                      style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.p16),
          if (isToday)
            GestureDetector(
              onTap: () => onToggleDone(!done),
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: done ? cs.surfaceContainerHighest.withValues(alpha: 0.5) : AppColors.secondaryColor,
                  borderRadius: BorderRadius.circular(15),
                  border: done
                      ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.4))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      done ? PhosphorIconsBold.arrowCounterClockwise : PhosphorIconsFill.checkCircle,
                      size: 18,
                      color: done ? cs.onSurface : AppColors.primaryColor,
                    ),
                    SizedBox(width: AppSpacing.p8),
                    Text(
                      done ? context.l10n.markNotDone : context.l10n.markComplete,
                      style: textTheme.titleSmall?.copyWith(
                        color: done ? cs.onSurface : AppColors.primaryColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Row(
              children: [
                Icon(PhosphorIconsRegular.lockSimple, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Text(
                  context.l10n.pastWorkoutViewOnly,
                  style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
  final ThemeData theme;
  final WorkoutExercise exercise;
  final int index;
  final bool isToday;
  final List<int> setLogs;
  final Future<void> Function(int setIdx, int reps) onSetReps;
  final Future<void> Function(int setIdx, double? weight) onSetWeight;
  final Future<void> Function(bool done) onToggleComplete;

  const _ExerciseCard({
    super.key,
    required this.theme,
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
    final theme = widget.theme;
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final e = widget.exercise;
    final doneSets = widget.setLogs.where((r) => r > 0).length;
    final complete = doneSets >= e.sets && e.sets > 0;
    final accent = complete ? AppColors.statusGreen : AppColors.secondaryColor;
    final progress = e.sets > 0 ? doneSets / e.sets : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header (tap to expand/collapse).
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: accent.withValues(alpha: 0.25)),
                    ),
                    child: Icon(
                      complete ? PhosphorIconsFill.checkCircle : PhosphorIconsFill.barbell,
                      size: 18,
                      color: accent,
                    ),
                  ),
                  SizedBox(width: AppSpacing.p12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.exerciseSetsTarget(doneSets, e.sets, e.reps),
                          style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress.toDouble()),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, _) => Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 34,
                            height: 34,
                            child: CircularProgressIndicator(
                              value: value,
                              strokeWidth: 3.5,
                              backgroundColor: cs.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(accent),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          if (complete)
                            Icon(PhosphorIconsBold.check, size: 14, color: accent),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.p8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(PhosphorIconsBold.caretDown,
                        size: 16, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _buildSets(theme, cs, e, complete),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  Widget _buildSets(ThemeData theme, ColorScheme cs, WorkoutExercise e, bool complete) {
    final textTheme = theme.textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        children: [
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.2)),
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
              theme: theme,
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
          if (widget.isToday) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onToggleComplete(!complete);
              },
              child: Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: complete
                      ? cs.surfaceContainerHighest.withValues(alpha: 0.5)
                      : AppColors.secondaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: complete
                        ? cs.outlineVariant.withValues(alpha: 0.4)
                        : AppColors.secondaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      complete ? PhosphorIconsBold.arrowCounterClockwise : PhosphorIconsBold.checks,
                      size: 15,
                      color: complete ? cs.onSurface : AppColors.secondaryColor,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      complete ? context.l10n.resetExercise : context.l10n.completeAllSets,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: complete ? cs.onSurface : AppColors.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
// Set row — reps stepper + weight input
// ===========================================================================

class _SetRow extends StatelessWidget {
  final ThemeData theme;
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
    required this.theme,
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

  Widget _numField(
    BuildContext context, {
    required String label,
    required String keyStr,
    required String initial,
    required String hint,
    required bool decimal,
    required void Function(String) onSubmit,
  }) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Column(
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            fontSize: 8,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: 58,
          height: 38,
          child: TextFormField(
            key: ValueKey(keyStr),
            initialValue: initial,
            enabled: isToday,
            keyboardType: decimal
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.number,
            inputFormatters: decimal ? null : [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant.withValues(alpha: 0.35),
              ),
              filled: true,
              fillColor: cs.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: AppColors.secondaryColor, width: 1.5),
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
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
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
      duration: const Duration(milliseconds: 160),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: done
            ? AppColors.secondaryColor.withValues(alpha: 0.08)
            : cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done
              ? AppColors.secondaryColor.withValues(alpha: 0.3)
              : cs.outlineVariant.withValues(alpha: 0.2),
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
                  duration: const Duration(milliseconds: 160),
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: done ? AppColors.secondaryColor : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: done
                          ? AppColors.secondaryColor
                          : cs.onSurfaceVariant.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: done
                      ? const Icon(PhosphorIconsBold.check, size: 15, color: AppColors.primaryColor)
                      : null,
                ),
                SizedBox(width: AppSpacing.p12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.setNumberLabel(setNumber),
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      done ? context.l10n.logged : (isToday ? context.l10n.tapToLog : '—'),
                      style: textTheme.labelSmall?.copyWith(
                        color: done
                            ? AppColors.secondaryColor
                            : cs.onSurfaceVariant.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
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
            label: context.l10n.repsLabel.toUpperCase(),
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
                ? unitLabel.toUpperCase()
                : '${unitLabel.toUpperCase()} · ${fmtW(targetWeight!)}',
            keyStr: 'w_${workoutKey}_${exIndex}_${setNumber}_${loggedWeight ?? 'n'}',
            initial: weightStr,
            hint: targetWeight == null ? unitLabel : fmtW(targetWeight!),
            decimal: true,
            onSubmit: (v) {
              final trimmed = v.trim();
              final parsed = trimmed.isEmpty ? null : double.tryParse(trimmed);
              if (trimmed.isNotEmpty && parsed == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.enterValidWeight)),
                );
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
// Empty state
// ===========================================================================

class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  final bool isToday;

  const _EmptyState({required this.theme, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.secondaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(PhosphorIconsRegular.barbell,
                  size: 34, color: AppColors.secondaryColor.withValues(alpha: 0.8)),
            ),
            SizedBox(height: AppSpacing.p16),
            Text(
              context.l10n.restDay,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              isToday
                  ? context.l10n.restDayTodayBody
                  : context.l10n.restDayPastBody,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
