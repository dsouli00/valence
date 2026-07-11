import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// A single logged meal. Not its own collection — meals live embedded in
/// `DailyLog.meals`; adding/editing/deleting one goes through FirestoreService
/// so the log's denormalized totals stay in sync.

/// Firestore string codec for [MealConfidence] (stored as 'high'/'medium'/
/// 'low'/'manual'; unknown values fall back to manual).
extension MealConfidenceX on MealConfidence {
  String get value => switch (this) {
    MealConfidence.high => 'high',
    MealConfidence.medium => 'medium',
    MealConfidence.low => 'low',
    MealConfidence.manual => 'manual',
  };

  static MealConfidence fromValue(String? value) {
    switch (value) {
      case 'high':
        return MealConfidence.high;
      case 'medium':
        return MealConfidence.medium;
      case 'low':
        return MealConfidence.low;
      case 'manual':
      default:
        return MealConfidence.manual;
    }
  }
}

class Meal {
  final String id; // client-generated (timestamp-based) — identifies the meal inside the array for edit/delete
  final String name;
  final int calories;
  final double protein; // grams
  final double carbs; // grams
  final double fat; // grams
  final String? imageUrl; // photo the AI scanned, if any
  final MealConfidence aiConfidence; // 'manual' when the user typed the numbers
  final DateTime loggedAt;

  Meal({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.imageUrl,
    this.aiConfidence = MealConfidence.manual,
    required this.loggedAt,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] as String,
      name: json['name'] as String,
      calories: (json['calories'] as num).toInt(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      aiConfidence: MealConfidenceX.fromValue(json['aiConfidence'] as String?),
      loggedAt: _parseDateTime(json['loggedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'imageUrl': imageUrl,
      'aiConfidence': aiConfidence.value,
      'loggedAt': Timestamp.fromDate(loggedAt),
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    if (value is DateTime) return value;
    return DateTime.now();
  }
}