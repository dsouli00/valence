import 'package:cloud_firestore/cloud_firestore.dart';

/// Workout domain models.
///
/// Flow: a coach builds [WorkoutTemplate]s in the library → assigning one to
/// a client COPIES its exercises into an [AssignedWorkout] doc for a specific
/// day (so later template edits never mutate already-assigned days) → the
/// client logs per-set reps/weight against that copy.

/// One exercise inside a template or an assigned workout.
///
/// Per-set data uses PARALLEL LISTS indexed 0..sets-1: `loggedRepsBySet[i]`,
/// `targetWeightKgBySet[i]`, `loggedWeightKgBySet[i]` all describe set i.
/// Weights are canonical kg (see utils/units.dart for display conversion).
class WorkoutExercise {
  final String name;
  final int sets; // planned number of sets
  final int reps; // planned reps per set (the target the client taps to log)
  final int completedSets;
  final List<int> loggedRepsBySet; // 0 = set not done yet
  final List<double?> targetWeightKgBySet; // null = coach set no target weight
  final List<double?> loggedWeightKgBySet; // null = client didn't log a weight
  final String? notes;

  const WorkoutExercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.completedSets = 0,
    this.loggedRepsBySet = const [],
    this.targetWeightKgBySet = const [],
    this.loggedWeightKgBySet = const [],
    this.notes,
  });

  WorkoutExercise copyWith({
    String? name,
    int? sets,
    int? reps,
    int? completedSets,
    List<int>? loggedRepsBySet,
    List<double?>? targetWeightKgBySet,
    List<double?>? loggedWeightKgBySet,
    String? notes,
  }) {
    return WorkoutExercise(
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      completedSets: completedSets ?? this.completedSets,
      loggedRepsBySet: loggedRepsBySet ?? this.loggedRepsBySet,
      targetWeightKgBySet: targetWeightKgBySet ?? this.targetWeightKgBySet,
      loggedWeightKgBySet: loggedWeightKgBySet ?? this.loggedWeightKgBySet,
      notes: notes ?? this.notes,
    );
  }

  /// Defensive parse: the per-set lists in old/edited docs can be shorter or
  /// longer than `sets` (e.g. the coach changed the set count after logging
  /// started), so each list is padded/truncated to exactly `sets` entries —
  /// UI code can then index by set number without bounds checks.
  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    final sets = (json['sets'] as num?)?.toInt() ?? 0;
    final logged = (json['loggedRepsBySet'] as List<dynamic>? ?? const [])
        .map((e) => (e as num?)?.toInt() ?? 0)
        .toList();
    final paddedLogged = logged.length >= sets
        ? logged.take(sets).toList()
        : [...logged, ...List.generate(sets - logged.length, (_) => 0)];
    final rawTargetWeights = (json['targetWeightKgBySet'] as List<dynamic>? ?? const []);
    final targetWeights = rawTargetWeights
        .map((e) => e == null ? null : (e as num).toDouble())
        .toList();
    final paddedTargetWeights = targetWeights.length >= sets
        ? targetWeights.take(sets).toList()
        : [...targetWeights, ...List.generate(sets - targetWeights.length, (_) => null)];
    final rawLoggedWeights = (json['loggedWeightKgBySet'] as List<dynamic>? ?? const []);
    final loggedWeights = rawLoggedWeights
        .map((e) => e == null ? null : (e as num).toDouble())
        .toList();
    final paddedLoggedWeights = loggedWeights.length >= sets
        ? loggedWeights.take(sets).toList()
        : [...loggedWeights, ...List.generate(sets - loggedWeights.length, (_) => null)];
    // Older docs predate `completedSets`; infer it from logged reps so
    // progress rings still render correctly for them.
    final inferredCompleted = paddedLogged.where((repsDone) => repsDone > 0).length;

    return WorkoutExercise(
      name: (json['name'] as String? ?? '').trim(),
      sets: sets,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      completedSets: (json['completedSets'] as num?)?.toInt() ?? inferredCompleted,
      loggedRepsBySet: paddedLogged,
      targetWeightKgBySet: paddedTargetWeights,
      loggedWeightKgBySet: paddedLoggedWeights,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'completedSets': completedSets,
      'loggedRepsBySet': loggedRepsBySet,
      'targetWeightKgBySet': targetWeightKgBySet,
      'loggedWeightKgBySet': loggedWeightKgBySet,
      'notes': notes,
    };
  }
}

/// A reusable workout in the coach's library — `workout_templates/{id}`.
/// Read-only model: creates/updates are built field-by-field in
/// FirestoreService, so there is deliberately no toJson here.
class WorkoutTemplate {
  final String id;
  final String coachId; // owner; used by rules + the library query
  final String name;
  final List<WorkoutExercise> exercises;
  final DateTime createdAt;

  const WorkoutTemplate({
    required this.id,
    required this.coachId,
    required this.name,
    required this.exercises,
    required this.createdAt,
  });

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json, String id) {
    return WorkoutTemplate(
      id: id,
      coachId: json['coachId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map((e) => WorkoutExercise.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      createdAt: _parseDateTime(json['createdAt']),
    );
  }
}

/// A workout scheduled for one client on one day —
/// `assigned_workouts/{clientId_YYYY-MM-DD}`. The deterministic doc id means
/// one workout per client per day: re-assigning the same day overwrites
/// (resetting progress) instead of duplicating.
class AssignedWorkout {
  final String id;
  final String clientId;
  final String coachId;
  final DateTime date;
  final String title; // template name at assign time (frozen copy)
  final List<WorkoutExercise> exercises;
  final bool isCompleted; // the client's explicit "mark day done" flag
  final DateTime? completedAt;

  const AssignedWorkout({
    required this.id,
    required this.clientId,
    required this.coachId,
    required this.date,
    required this.title,
    required this.exercises,
    required this.isCompleted,
    this.completedAt,
  });

  factory AssignedWorkout.fromJson(Map<String, dynamic> json, String id) {
    return AssignedWorkout(
      id: id,
      clientId: json['clientId'] as String? ?? '',
      coachId: json['coachId'] as String? ?? '',
      date: _parseDateTime(json['date']),
      title: json['title'] as String? ?? 'Workout',
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map((e) => WorkoutExercise.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      isCompleted: json['isCompleted'] == true,
      completedAt: json['completedAt'] == null
          ? null
          : _parseDateTime(json['completedAt']),
    );
  }
}

// Dates arrive as Timestamp from Firestore but as DateTime/String from local
// construction and tests — accept all three rather than crash on bad data.
DateTime _parseDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
