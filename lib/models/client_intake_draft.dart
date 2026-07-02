import 'enums.dart';
import 'target_macros.dart';

/// Every answer collected during the client onboarding journey, captured
/// *before* an account exists. It carries from the onboarding flow → signup →
/// Firestore, so personalization can happen ahead of the signup wall.
///
/// This is the single source of truth for the auto-calculated plan
/// (Mifflin-St Jeor BMR → activity TDEE → goal split) and for an honest
/// projected timeline derived from the user's own calorie deficit/surplus —
/// no invented numbers.
class ClientIntakeDraft {
  final FitnessGoal goal;
  final BiologicalSex sex;
  final int age;
  final double heightCm;
  final double currentWeight;
  final double targetWeight;
  final ActivityLevel activity;

  /// Optional market-research answer (prior nutrition-tracking habit). Used for
  /// product insight only; never gates the experience.
  final String? priorTracking;

  /// The unit system the user entered their body in. Values are stored
  /// canonically in metric regardless; this only sets their display preference
  /// (persisted as `weightUnit`: 'kg' when metric, 'lb' when imperial).
  final bool metric;

  const ClientIntakeDraft({
    required this.goal,
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.currentWeight,
    required this.targetWeight,
    required this.activity,
    this.priorTracking,
    this.metric = true,
  });

  /// The `weightUnit` value to persist for this user.
  String get weightUnit => metric ? 'kg' : 'lb';

  /// Mifflin-St Jeor basal metabolic rate.
  double get _bmr =>
      10 * currentWeight + 6.25 * heightCm - 5 * age + (sex == BiologicalSex.male ? 5 : -161);

  /// Total daily energy expenditure (BMR × activity multiplier).
  double get tdee => _bmr * activity.multiplier;

  /// Daily calorie target after the goal adjustment.
  int get calories {
    final c = switch (goal) {
      FitnessGoal.lose => tdee * 0.80,
      FitnessGoal.maintain => tdee,
      FitnessGoal.gain => tdee * 1.10,
    };
    return c.round();
  }

  TargetMacros get macros {
    final protein = (1.8 * currentWeight).round();
    final fat = ((calories * 0.25) / 9).round();
    final carbs = ((calories - protein * 4 - fat * 9) / 4).round().clamp(0, 100000);
    return TargetMacros(calories: calories, protein: protein, carbs: carbs, fat: fat);
  }

  /// ~7,700 kcal ≈ 1 kg of body mass — the standard energy-balance estimate.
  static const double _kcalPerKg = 7700;

  /// Honest week estimate to reach the goal weight, derived from the actual
  /// daily deficit/surplus. Null when maintaining, when the change is trivial,
  /// or when the daily delta is too small to project responsibly.
  int? get weeksToGoal {
    if (goal == FitnessGoal.maintain) return null;
    final deltaKg = (currentWeight - targetWeight).abs();
    if (deltaKg < 0.5) return null;
    final dailyDelta = (tdee - calories).abs();
    if (dailyDelta < 50) return null;
    final weeks = (deltaKg * _kcalPerKg) / (dailyDelta * 7);
    return weeks.ceil().clamp(1, 260);
  }

  /// The projected date the goal weight is reached, or null when there's no
  /// responsible estimate (see [weeksToGoal]).
  DateTime? get projectedDate {
    final weeks = weeksToGoal;
    if (weeks == null) return null;
    return DateTime.now().add(Duration(days: weeks * 7));
  }
}
