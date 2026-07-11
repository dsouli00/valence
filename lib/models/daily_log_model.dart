import 'package:cloud_firestore/cloud_firestore.dart';

import 'meal_model.dart';

/// One client's tracking data for ONE day — `daily_logs/{clientId_YYYY-MM-DD}`.
///
/// The deterministic date-keyed id lets both sides fetch "today" with a
/// direct doc get (no query) and guarantees at most one log per day.
/// Everything a client tracks daily lives in this single doc: meals, water,
/// sleep, weight, notes, habit checks. It is created lazily on the first log
/// action of the day (`FirestoreService.getOrCreateTodayLog`).
class DailyLog {
  final String id;
  final String clientId; // duplicated inside the doc for queries + rules
  final String coachId; // lets the coach's rules/queries reach this log
  final DateTime date;

  final List<Meal> meals; // embedded array, not a subcollection — a day's meals are always read together

  // Denormalized running totals — recomputed by FirestoreService whenever a
  // meal is added/edited/removed, so dashboards never sum the array.
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  // Habit pillars. Null = "not logged today" (distinct from zero).
  final double? waterLiters;
  final int? sleepRating; // 1–5 stars
  final double? weightKg; // canonical kg
  final String? clientNote; // client → coach ("note to coach" on home)
  final String? coachNote; // coach → client (edit-in-place from client details)

  /// Per-day completion of coach-defined custom habits: habitId → done.
  final Map<String, bool>? habitChecks;

  DailyLog({
    required this.id,
    required this.clientId,
    required this.coachId,
    required this.date,
    required this.meals,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    this.waterLiters,
    this.sleepRating,
    this.weightKg,
    this.clientNote,
    this.coachNote,
    this.habitChecks,
  });

  factory DailyLog.fromJson(Map<String, dynamic> json, String id) {
    return DailyLog(
      id: id,
      clientId: json['clientId'] as String,
      coachId: json['coachId'] as String? ?? '',
      date: _parseDateTime(json['date']),
      meals: (json['meals'] as List<dynamic>? ?? [])
          .map((item) => Meal.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalCalories: (json['totalCalories'] as num?)?.toInt() ?? 0,
      totalProtein: (json['totalProtein'] as num?)?.toDouble() ?? 0.0,
      totalCarbs: (json['totalCarbs'] as num?)?.toDouble() ?? 0.0,
      totalFat: (json['totalFat'] as num?)?.toDouble() ?? 0.0,
      waterLiters: (json['waterLiters'] as num?)?.toDouble(),
      sleepRating: (json['sleepRating'] as num?)?.toInt(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      clientNote: json['clientNote'] as String?,
      coachNote: json['coachNote'] as String?,
      habitChecks: (json['habitChecks'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v == true)),
    );
  }

  /// Used on the create path. `habitChecks` is included ONLY when non-null:
  /// habit toggles are merge-written key-by-key elsewhere, and writing an
  /// explicit null map here would clobber them.
  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'coachId': coachId,
      'date': Timestamp.fromDate(date),
      'meals': meals.map((meal) => meal.toJson()).toList(),
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'waterLiters': waterLiters,
      'sleepRating': sleepRating,
      'weightKg': weightKg,
      'clientNote': clientNote,
      'coachNote': coachNote,
      if (habitChecks != null) 'habitChecks': habitChecks,
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    if (value is DateTime) return value;
    return DateTime.now();
  }
}