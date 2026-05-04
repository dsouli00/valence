/// await firestoreService.updateUserFields(clientId, {'targetMacros': targets.toJson()});

class TargetMacros {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  const TargetMacros({
    this.calories = 2000,
    this.protein = 150,
    this.carbs = 200,
    this.fat = 65,
  });

  // SERIALIZATION (Firestore ↔ TargetMacros)
  factory TargetMacros.fromJson(Map<String, dynamic> json) {
    return TargetMacros(
      calories: json['calories'] ?? 2000,
      protein: json['protein'] ?? 150,
      carbs: json['carbs'] ?? 200,
      fat: json['fat'] ?? 65,
    );
  }

  /// Convert TargetMacros to Firestore document
  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };
}
