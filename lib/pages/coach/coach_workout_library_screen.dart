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

  Future<void> _showEditTemplateDialog(
    WorkoutTemplate template,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nameController = TextEditingController(text: template.name);
    final exerciseNameControllers = template.exercises
        .map((e) => TextEditingController(text: e.name))
        .toList();
    final sets = template.exercises.map((e) => e.sets).toList();
    final reps = template.exercises.map((e) => e.reps).toList();

    Widget buildExerciseRow(StateSetter setDialogState, int index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(70),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant.withAlpha(100)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: exerciseNameControllers[index],
                      decoration: InputDecoration(
                        labelText: 'Exercise ${index + 1}',
                        filled: true,
                        fillColor: colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove exercise',
                    onPressed: exerciseNameControllers.length <= 1
                        ? null
                        : () => setDialogState(() {
                            exerciseNameControllers.removeAt(index).dispose();
                            sets.removeAt(index);
                            reps.removeAt(index);
                          }),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Sets', style: theme.textTheme.labelMedium),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setDialogState(() {
                      sets[index] = (sets[index] - 1).clamp(1, 50);
                    }),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('${sets[index]}', style: theme.textTheme.titleSmall),
                  IconButton(
                    onPressed: () => setDialogState(() {
                      sets[index] = (sets[index] + 1).clamp(1, 50);
                    }),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('Reps', style: theme.textTheme.labelMedium),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setDialogState(() {
                      reps[index] = (reps[index] - 1).clamp(1, 100);
                    }),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('${reps[index]}', style: theme.textTheme.titleSmall),
                  IconButton(
                    onPressed: () => setDialogState(() {
                      reps[index] = (reps[index] + 1).clamp(1, 100);
                    }),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: colorScheme.surface,
          title: const Text('Edit Workout Template'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Template Name',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withAlpha(60),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    exerciseNameControllers.length,
                    (index) => buildExerciseRow(setDialogState, index),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setDialogState(() {
                        exerciseNameControllers.add(TextEditingController());
                        sets.add(3);
                        reps.add(10);
                      }),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Exercise'),
                    ),
                  ),
                ],
              ),
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

    final templateName = nameController.text.trim();
    final exerciseNames = exerciseNameControllers.map((c) => c.text.trim()).toList();
    for (final c in exerciseNameControllers) {
      c.dispose();
    }
    nameController.dispose();

    if (shouldSave != true) return;
    final validExercises = <WorkoutExercise>[];
    for (var i = 0; i < exerciseNames.length; i++) {
      if (exerciseNames[i].isEmpty) continue;
      validExercises.add(
        WorkoutExercise(
          name: exerciseNames[i],
          sets: sets[i],
          reps: reps[i],
        ),
      );
    }
    if (templateName.isEmpty || validExercises.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a template name and at least one exercise')),
      );
      return;
    }
    await _firestoreService.updateWorkoutTemplate(
      templateId: template.id,
      name: templateName,
      exercises: validExercises,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template updated')),
    );
  }

  Future<void> _confirmDeleteTemplate(WorkoutTemplate template) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete template?'),
        content: Text('Delete "${template.name}" from workout library?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    await _firestoreService.deleteWorkoutTemplate(template.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template deleted')),
    );
  }

  Future<void> _showCreateTemplateDialog(String coachId) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nameController = TextEditingController();
    final exerciseNameControllers = <TextEditingController>[
      TextEditingController(),
    ];
    final sets = <int>[3];
    final reps = <int>[10];

    Widget buildExerciseRow(StateSetter setDialogState, int index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(70),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant.withAlpha(100)),
          ),
          child: Column(
            children: [
              TextField(
                controller: exerciseNameControllers[index],
                decoration: InputDecoration(
                  labelText: 'Exercise ${index + 1}',
                  filled: true,
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Sets', style: theme.textTheme.labelMedium),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setDialogState(() {
                      sets[index] = (sets[index] - 1).clamp(1, 50);
                    }),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('${sets[index]}', style: theme.textTheme.titleSmall),
                  IconButton(
                    onPressed: () => setDialogState(() {
                      sets[index] = (sets[index] + 1).clamp(1, 50);
                    }),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('Reps', style: theme.textTheme.labelMedium),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setDialogState(() {
                      reps[index] = (reps[index] - 1).clamp(1, 100);
                    }),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('${reps[index]}', style: theme.textTheme.titleSmall),
                  IconButton(
                    onPressed: () => setDialogState(() {
                      reps[index] = (reps[index] + 1).clamp(1, 100);
                    }),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: colorScheme.surface,
          title: const Text('Create Workout Template'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Template Name',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withAlpha(60),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(
                  exerciseNameControllers.length,
                  (index) => buildExerciseRow(setDialogState, index),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setDialogState(() {
                      exerciseNameControllers.add(TextEditingController());
                      sets.add(3);
                      reps.add(10);
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

    final templateName = nameController.text.trim();
    final exerciseNames = exerciseNameControllers.map((c) => c.text.trim()).toList();
    for (final c in exerciseNameControllers) {
      c.dispose();
    }
    nameController.dispose();

    if (saved != true) return;
    final name = templateName;
    final validExercises = <WorkoutExercise>[];
    for (var i = 0; i < exerciseNames.length; i++) {
      final exerciseName = exerciseNames[i];
      if (exerciseName.isEmpty) continue;
      validExercises.add(
        WorkoutExercise(
          name: exerciseName,
          sets: sets[i],
          reps: reps[i],
        ),
      );
    }
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
    final colorScheme = Theme.of(context).colorScheme;
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
          backgroundColor: colorScheme.surface,
          title: const Text('Assign Workout'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedClientId,
                  decoration: const InputDecoration(labelText: 'Client'),
                  items: clients
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.uid,
                          child: Text(
                            c.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      )
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(70),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                                   maxLines: 1,
                                   overflow: TextOverflow.ellipsis,
                                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                         fontWeight: FontWeight.bold,
                                       ),
                                 ),
                                const SizedBox(height: 6),
                                 ...template.exercises.map(
                                   (e) => Text(
                                     '• ${e.name} — ${e.sets}x${e.reps}',
                                     maxLines: 1,
                                     overflow: TextOverflow.ellipsis,
                                   ),
                                 ),
                                 const SizedBox(height: 8),
                                 Wrap(
                                   spacing: 8,
                                   runSpacing: 8,
                                   alignment: WrapAlignment.end,
                                   children: [
                                     OutlinedButton.icon(
                                       onPressed: () => _showAssignDialog(
                                         template,
                                         clients,
                                         coach.uid,
                                       ),
                                       icon: const Icon(Icons.send_outlined),
                                       label: const Text('Assign'),
                                     ),
                                     OutlinedButton.icon(
                                       onPressed: () => _showEditTemplateDialog(template),
                                       icon: const Icon(Icons.edit_outlined),
                                       label: const Text('Edit'),
                                     ),
                                     OutlinedButton.icon(
                                       onPressed: () => _confirmDeleteTemplate(template),
                                       icon: const Icon(Icons.delete_outline),
                                       label: const Text('Delete'),
                                     ),
                                   ],
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
