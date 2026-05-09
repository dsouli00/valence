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
                            onChanged: (value) {
                              _firestoreService.setAssignedWorkoutDone(
                                clientId: user.uid,
                                date: _selectedDate,
                                isDone: value,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(workout.exercises.length, (index) {
                      final exercise = workout.exercises[index];
                      final setLogs = exercise.loggedRepsBySet.isEmpty
                          ? List.generate(exercise.sets, (_) => 0)
                          : exercise.loggedRepsBySet;
                      final isExerciseCompleted =
                          setLogs.length >= exercise.sets &&
                              setLogs.take(exercise.sets).every((v) => v > 0);
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
                            '${exercise.sets} sets x target ${exercise.reps} reps',
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
                          children: List.generate(exercise.sets, (setIdx) {
                            final logged = setIdx < setLogs.length ? setLogs[setIdx] : 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Set ${setIdx + 1}',
                                      style: textTheme.bodyMedium,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 110,
                                    child: TextFormField(
                                      initialValue: logged > 0 ? '$logged' : '',
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        hintText: 'Reps',
                                        filled: true,
                                        fillColor: colorScheme.surface,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onFieldSubmitted: (value) {
                                        final repsDone = int.tryParse(value.trim()) ?? 0;
                                        _firestoreService.updateWorkoutSetRep(
                                          clientId: user.uid,
                                          date: _selectedDate,
                                          exerciseIndex: index,
                                          setIndex: setIdx,
                                          repsDone: repsDone,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      _firestoreService.updateWorkoutSetRep(
                                        clientId: user.uid,
                                        date: _selectedDate,
                                        exerciseIndex: index,
                                        setIndex: setIdx,
                                        repsDone: exercise.reps,
                                      );
                                    },
                                    icon: const Icon(Icons.check_circle_outline),
                                  ),
                                ],
                              ),
                            );
                          }),
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
