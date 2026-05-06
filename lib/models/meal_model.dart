import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

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
  final String id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? imageUrl;
  final MealConfidence aiConfidence;
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