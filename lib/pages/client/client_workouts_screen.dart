import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:valence/models/workout_models.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/services/firestore_service.dart';
import 'package:valence/theme/app_theme.dart';

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
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: const Text('Workouts'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'RECENT DAYS',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final day = _calendarDays()[index];
                final normalizedDay = DateTime(day.year, day.month, day.day);
                final isSelected = _isSameDay(day, _selectedDate);
                final isToday = _isSameDay(day, DateTime.now());
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() {
                    _selectedDate = normalizedDay;
                    HapticFeedback.selectionClick();
                  }),
                  child: Container(
                    width: 46,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.secondaryColor.withAlpha(28)
                          : colorScheme.surfaceContainerHighest.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.secondaryColor.withAlpha(130)
                            : colorScheme.outlineVariant.withAlpha(65),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1],
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${day.day}',
                          style: textTheme.titleSmall?.copyWith(
                            color: isSelected ? AppColors.secondaryColor : colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isToday)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
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
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemCount: _calendarDays().length,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<AssignedWorkout?>(
              stream: _firestoreService.streamAssignedWorkoutForDate(
                user.uid,
                _selectedDate,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final workout = snapshot.data;
                final isTodaySelected = _isSameDay(_selectedDate, DateTime.now());
                if (workout == null) {
                  return Center(
                    child: Text(
                      'No workout assigned for this day.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant.withAlpha(90)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workout.title,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            workout.isCompleted ? 'Status: Completed' : 'Status: In progress',
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Mark workout as done'),
                            value: workout.isCompleted,
                            onChanged: isTodaySelected
                                ? (value) {
                                    _firestoreService.setAssignedWorkoutDone(
                                      clientId: user.uid,
                                      date: _selectedDate,
                                      isDone: value,
                                    );
                                  }
                                : null,
                          ),
                          if (!isTodaySelected)
                            Text(
                              'Past workouts are read-only.',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(workout.exercises.length, (index) {
                      final exercise = workout.exercises[index];
                      final setLogs = _normalizedSetLogs(exercise);
                      final doneSets = setLogs.where((v) => v > 0).length;
                      final isExerciseCompleted = doneSets >= exercise.sets;
                      final progress = exercise.sets > 0 ? doneSets / exercise.sets : 0.0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          title: Text(
                            exercise.name,
                            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '$doneSets/${exercise.sets} sets complete • target ${exercise.reps} reps',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isExerciseCompleted
                                  ? const Color(0xFF10B981).withAlpha(20)
                                  : colorScheme.secondary.withAlpha(20),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              isExerciseCompleted ? 'Done' : '${exercise.completedSets}/${exercise.sets}',
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isExerciseCompleted
                                    ? const Color(0xFF10B981)
                                    : colorScheme.secondary,
                              ),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(999),
                                      backgroundColor: colorScheme.surfaceContainerHighest,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: isTodaySelected
                                        ? () => _setExerciseDone(
                                              clientId: user.uid,
                                              exercise: exercise,
                                              exerciseIndex: index,
                                              done: !isExerciseCompleted,
                                            )
                                        : null,
                                    icon: Icon(
                                      isExerciseCompleted
                                          ? Icons.undo_rounded
                                          : Icons.check_circle_outline,
                                      size: 18,
                                    ),
                                    label: Text(isExerciseCompleted ? 'Reset' : 'Complete'),
                                  ),
                                ],
                              ),
                            ),
                            ...List.generate(exercise.sets, (setIdx) {
                              final logged = setIdx < setLogs.length ? setLogs[setIdx] : 0;
                              final targetWeight = setIdx < exercise.targetWeightKgBySet.length
                                  ? exercise.targetWeightKgBySet[setIdx]
                                  : null;
                              final loggedWeight = setIdx < exercise.loggedWeightKgBySet.length
                                  ? exercise.loggedWeightKgBySet[setIdx]
                                  : null;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest.withAlpha(60),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Set ${setIdx + 1}',
                                              style: textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: colorScheme.surface,
                                              borderRadius: BorderRadius.circular(999),
                                              border: Border.all(color: colorScheme.outlineVariant.withAlpha(100)),
                                            ),
                                            child: Text(
                                              '$logged reps',
                                              style: textTheme.labelMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          IconButton(
                                            tooltip: 'Decrease reps',
                                            onPressed: isTodaySelected
                                                ? () => _updateSetReps(
                                                      clientId: user.uid,
                                                      exerciseIndex: index,
                                                      setIndex: setIdx,
                                                      repsDone: (logged - 1).clamp(0, 1000),
                                                    )
                                                : null,
                                            icon: const Icon(Icons.remove_circle_outline),
                                          ),
                                          IconButton(
                                            tooltip: 'Increase reps',
                                            onPressed: isTodaySelected
                                                ? () => _updateSetReps(
                                                      clientId: user.uid,
                                                      exerciseIndex: index,
                                                      setIndex: setIdx,
                                                      repsDone: (logged + 1).clamp(0, 1000),
                                                    )
                                                : null,
                                            icon: const Icon(Icons.add_circle_outline),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              targetWeight == null
                                                  ? 'Coach target: — kg'
                                                  : 'Coach target: ${targetWeight.toStringAsFixed(1)} kg',
                                              style: textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 110,
                                            child: TextFormField(
                                              key: ValueKey(
                                                'weight_${workout.id}_${index}_$setIdx_${loggedWeight ?? 'none'}',
                                              ),
                                              initialValue: loggedWeight?.toStringAsFixed(1) ?? '',
                                              enabled: isTodaySelected,
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(decimal: true),
                                              decoration: const InputDecoration(
                                                labelText: 'Kg',
                                                isDense: true,
                                              ),
                                              onFieldSubmitted: (value) {
                                                if (!isTodaySelected) return;
                                                final trimmed = value.trim();
                                                final parsed =
                                                    trimmed.isEmpty ? null : double.tryParse(trimmed);
                                                if (trimmed.isNotEmpty && parsed == null) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Enter a valid weight value'),
                                                    ),
                                                  );
                                                  return;
                                                }
                                                _updateSetWeight(
                                                  clientId: user.uid,
                                                  exerciseIndex: index,
                                                  setIndex: setIdx,
                                                  weightKg: parsed,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
