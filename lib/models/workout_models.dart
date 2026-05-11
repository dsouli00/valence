import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutExercise {
  final String name;
  final int sets;
  final int reps;
  final int completedSets;
  final List<int> loggedRepsBySet;
  final List<double?> targetWeightKgBySet;
  final List<double?> loggedWeightKgBySet;
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

class WorkoutTemplate {
  final String id;
  final String coachId;
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

class AssignedWorkout {
  final String id;
  final String clientId;
  final String coachId;
  final DateTime date;
  final String title;
  final List<WorkoutExercise> exercises;
  final bool isCompleted;
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

DateTime _parseDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
