/// A client's daily nutrition targets, stored as a map on the user doc
/// (`users/{uid}.targetMacros`). Set either by the intake auto-calculation
/// (ClientIntakeDraft) or manually by the coach ("Update Macros" in client
/// details), e.g.:
///   await firestoreService.updateUserFields(clientId, {'targetMacros': targets.toJson()});
///
/// The defaults below are generic-adult fallbacks for legacy/partial docs —
/// a real client should always have intake- or coach-set values (a missing
/// `targetMacros` routes them to the intake flow instead).
class TargetMacros {
  final int calories;
  final int protein; // grams
  final int carbs; // grams
  final int fat; // grams
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
