import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:valence/models/workout_models.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/services/firestore_service.dart';

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
      21,
      (i) => DateTime(now.year, now.month, now.day).add(Duration(days: i - 10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Workouts')),
      body: Column(
        children: [
          SizedBox(
            height: 68,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final day = _calendarDays()[index];
                final isSelected = _isSameDay(day, _selectedDate);
                final isToday = _isSameDay(day, DateTime.now());
                return InkWell(
                  onTap: () => setState(() {
                    _selectedDate = DateTime(day.year, day.month, day.day);
                  }),
                  child: Container(
                    width: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isSelected
                          ? Theme.of(context).colorScheme.secondary.withOpacity(0.14)
                          : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1],
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          '${day.day}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (isToday)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
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
                  return const Center(
                    child: Text('No workout assigned for this day.'),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workout.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              workout.isCompleted ? 'Status: Completed' : 'Status: In progress',
                              style: Theme.of(context).textTheme.bodyMedium,
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
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(workout.exercises.length, (index) {
                      final exercise = workout.exercises[index];
                      return Card(
                        child: ListTile(
                          title: Text(exercise.name),
                          subtitle: Text(
                            '${exercise.sets} sets x ${exercise.reps} reps',
                          ),
                          trailing: SizedBox(
                            width: 140,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    _firestoreService.updateWorkoutExerciseProgress(
                                      clientId: user.uid,
                                      date: _selectedDate,
                                      exerciseIndex: index,
                                      completedSets: exercise.completedSets - 1,
                                    );
                                  },
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text('${exercise.completedSets}/${exercise.sets}'),
                                IconButton(
                                  onPressed: () {
                                    _firestoreService.updateWorkoutExerciseProgress(
                                      clientId: user.uid,
                                      date: _selectedDate,
                                      exerciseIndex: index,
                                      completedSets: exercise.completedSets + 1,
                                    );
                                  },
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ),
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
