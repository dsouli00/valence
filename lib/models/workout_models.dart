import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutExercise {
  final String name;
  final int sets;
  final int reps;
  final int completedSets;
  final String? notes;

  const WorkoutExercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.completedSets = 0,
    this.notes,
  });

  WorkoutExercise copyWith({
    String? name,
    int? sets,
    int? reps,
    int? completedSets,
    String? notes,
  }) {
    return WorkoutExercise(
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      completedSets: completedSets ?? this.completedSets,
      notes: notes ?? this.notes,
    );
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      name: (json['name'] as String? ?? '').trim(),
      sets: (json['sets'] as num?)?.toInt() ?? 0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      completedSets: (json['completedSets'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'completedSets': completedSets,
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
