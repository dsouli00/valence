import 'package:cloud_firestore/cloud_firestore.dart';

import 'meal_model.dart';

class DailyLog {
  final String id;
  final String clientId;
  final String coachId;
  final DateTime date;

  final List<Meal> meals;

  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  final double? waterLiters;
  final int? sleepRating;
  final double? weightKg;
  final String? clientNote;
  final String? coachNote;

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
    );
  }

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
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    if (value is DateTime) return value;
    return DateTime.now();
  }
}