import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:valence/models/user_model.dart';
import 'package:valence/models/workout_models.dart';
import 'package:valence/providers/auth_provider.dart';
import 'package:valence/services/firestore_service.dart';

class CoachWorkoutLibraryScreen extends StatefulWidget {
  const CoachWorkoutLibraryScreen({super.key});

  @override
  State<CoachWorkoutLibraryScreen> createState() => _CoachWorkoutLibraryScreenState();
}

class _CoachWorkoutLibraryScreenState extends State<CoachWorkoutLibraryScreen> {
  final _firestoreService = FirestoreService();

  Future<void> _showCreateTemplateDialog(String coachId) async {
    final nameController = TextEditingController();
    final exercises = <WorkoutExercise>[const WorkoutExercise(name: '', sets: 3, reps: 10)];
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Workout Template'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Template Name'),
                ),
                const SizedBox(height: 12),
                ...List.generate(exercises.length, (index) {
                  final exercise = exercises[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: exercise.name,
                            decoration: InputDecoration(labelText: 'Exercise ${index + 1}'),
                            onChanged: (value) {
                              exercises[index] = exercise.copyWith(name: value);
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: () => setDialogState(() {
                            final sets = (exercises[index].sets - 1).clamp(1, 50);
                            exercises[index] = exercises[index].copyWith(sets: sets);
                          }),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('${exercise.sets}'),
                        IconButton(
                          onPressed: () => setDialogState(() {
                            final sets = (exercises[index].sets + 1).clamp(1, 50);
                            exercises[index] = exercises[index].copyWith(sets: sets);
                          }),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        IconButton(
                          onPressed: () => setDialogState(() {
                            final reps = (exercises[index].reps - 1).clamp(1, 100);
                            exercises[index] = exercises[index].copyWith(reps: reps);
                          }),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('${exercise.reps}'),
                        IconButton(
                          onPressed: () => setDialogState(() {
                            final reps = (exercises[index].reps + 1).clamp(1, 100);
                            exercises[index] = exercises[index].copyWith(reps: reps);
                          }),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  );
                }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setDialogState(() {
                      exercises.add(const WorkoutExercise(name: '', sets: 3, reps: 10));
                    }),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Exercise'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    final name = nameController.text.trim();
    final validExercises = exercises.where((e) => e.name.trim().isNotEmpty).toList();
    if (name.isEmpty || validExercises.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a template name and at least one exercise')),
      );
      return;
    }
    await _firestoreService.createWorkoutTemplate(
      coachId: coachId,
      name: name,
      exercises: validExercises,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template created')),
    );
  }

  Future<void> _showAssignDialog(
    WorkoutTemplate template,
    List<AppUser> clients,
    String coachId,
  ) async {
    if (clients.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No clients available')),
      );
      return;
    }

    String selectedClientId = clients.first.uid;
    DateTime selectedDate = DateTime.now();
    final editableExercises = template.exercises.map((e) => e.copyWith()).toList();

    final shouldAssign = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Assign Workout'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedClientId,
                  decoration: const InputDecoration(labelText: 'Client'),
                  items: clients
                      .map((c) => DropdownMenuItem(value: c.uid, child: Text(c.name)))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => selectedClientId = value);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Date: ${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDate: selectedDate,
                        );
                        if (picked == null) return;
                        setDialogState(() {
                          selectedDate = DateTime(picked.year, picked.month, picked.day);
                        });
                      },
                      child: const Text('Pick'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Minor adjustments'),
                const SizedBox(height: 6),
                ...List.generate(editableExercises.length, (index) {
                  final exercise = editableExercises[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(exercise.name)),
                        IconButton(
                          onPressed: () => setDialogState(() {
                            editableExercises[index] = exercise.copyWith(
                              sets: (exercise.sets - 1).clamp(1, 50),
                            );
                          }),
                          icon: const Icon(Icons.remove, size: 18),
                        ),
                        Text('${exercise.sets}x${exercise.reps}'),
                        IconButton(
                          onPressed: () => setDialogState(() {
                            editableExercises[index] = exercise.copyWith(
                              sets: (exercise.sets + 1).clamp(1, 50),
                            );
                          }),
                          icon: const Icon(Icons.add, size: 18),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );

    if (shouldAssign != true) return;
    await _firestoreService.assignWorkoutToClient(
      coachId: coachId,
      clientId: selectedClientId,
      date: selectedDate,
      title: template.name,
      exercises: editableExercises,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workout assigned')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coach = context.watch<AuthProvider>().currentUser;
    if (coach == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<AppUser>>(
      stream: _firestoreService.streamClientsByCoach(coach.uid),
      builder: (context, clientsSnapshot) {
        final clients = clientsSnapshot.data ?? const <AppUser>[];
        return StreamBuilder<List<WorkoutTemplate>>(
          stream: _firestoreService.streamWorkoutTemplates(coach.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final templates = snapshot.data ?? const <WorkoutTemplate>[];
            return Scaffold(
              appBar: AppBar(
                title: const Text('Workout Library'),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _showCreateTemplateDialog(coach.uid),
                icon: const Icon(Icons.add),
                label: const Text('New Template'),
              ),
              body: templates.isEmpty
                  ? const Center(child: Text('No workout templates yet.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  template.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                ...template.exercises.map(
                                  (e) => Text('• ${e.name} — ${e.sets}x${e.reps}'),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showAssignDialog(
                                      template,
                                      clients,
                                      coach.uid,
                                    ),
                                    icon: const Icon(Icons.send_outlined),
                                    label: const Text('Assign to Client'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: templates.length,
                    ),
            );
          },
        );
      },
    );
  }
}
