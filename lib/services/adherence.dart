/// THE adherence model — the pure scoring math behind a client's
/// [ClientStatus] and the roster's `statusSummary`.
///
/// This lives apart from [FirestoreService] for one reason: it is the app's
/// core judgement about a human being, and a regression here does not crash —
/// it quietly tells a coach the wrong thing about a client. Separated from the
/// Firestore reads/writes, it becomes a pure function of (today, signup date,
/// logs, workouts) and can be tested exhaustively. `FirestoreService` still
/// owns all the I/O: it fetches the docs, calls [computeAdherence], and
/// denormalizes the result onto the user doc.
///
/// The rules (tuned across several iterations — do NOT tweak thresholds
/// casually, the tests below encode them deliberately):
///   • Rolling 7-day window of COMPLETED days. Today is in-progress and is
///     never penalised — it can only improve the picture, so it is excluded.
///   • The window is bounded by the client's signup date: no expectations are
///     placed on days before they existed.
///   • Status = the WORST of two independent signals:
///       - Recency: consecutive fully-silent days walking back from yesterday.
///       - Consistency: average share of expected pillars met per day.
///   • Per-pillar expectations: Nutrition + Habits are daily; Training counts
///     only on days a workout was actually assigned.
library;

/// The denormalized verdict written onto the user doc.
class AdherenceResult {
  /// Firestore status string: 'on_track' | 'slipping' | 'at_risk'.
  final String status;

  /// Human-readable roster summary, e.g.
  /// "Last 7d: nutrition 5/7 • habits 4/7 • workouts 2/3".
  final String summary;

  const AdherenceResult({required this.status, required this.summary});
}

/// Normalizes a date into the stable day key used for date-keyed doc ids
/// ("{clientId}_{YYYY-MM-DD}"). Single source of truth — `FirestoreService`
/// delegates to this so ids and scoring can never disagree on what a day is.
String dateKeyFor(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';
}

/// Today + the 7 completed days behind it.
const int kAdherenceWindowDays = 8;

/// A day counts for nutrition if anything was eaten and recorded.
bool nutritionMet(Map<String, dynamic>? log) {
  if (log == null) return false;
  final meals = (log['meals'] as List<dynamic>? ?? const []);
  final cals = (log['totalCalories'] as num?)?.toInt() ?? 0;
  return meals.isNotEmpty || cals > 0;
}

/// Habits need at least 2 of the 3 core pillars (water / sleep / weight).
/// Deliberately forgiving: hitting every pillar daily is not the bar.
bool habitsMet(Map<String, dynamic>? log) {
  if (log == null) return false;
  final water = (log['waterLiters'] as num?)?.toDouble() ?? 0;
  final sleep = (log['sleepRating'] as num?)?.toInt() ?? 0;
  final weight = (log['weightKg'] as num?)?.toDouble() ?? 0;
  return [water > 0, sleep > 0, weight > 0].where((v) => v).length >= 2;
}

/// Any sign of life at all on a day — the recency signal's only question.
/// A single glass of water breaks a silence streak.
bool anyActivity(Map<String, dynamic>? log, Map<String, dynamic>? workout) {
  if (nutritionMet(log)) return true;
  if (log != null) {
    final water = (log['waterLiters'] as num?)?.toDouble() ?? 0;
    final sleep = (log['sleepRating'] as num?)?.toInt() ?? 0;
    final weight = (log['weightKg'] as num?)?.toDouble() ?? 0;
    if (water > 0 || sleep > 0 || weight > 0) return true;
  }
  return workout != null && workout['isCompleted'] == true;
}

/// Scores [logsByDay] / [workoutsByDay] (both keyed by [dateKeyFor]) into a
/// status + summary. [createdAt] should be the client's signup day (normalized
/// to midnight); null means no signup bound is applied.
AdherenceResult computeAdherence({
  required DateTime normalizedToday,
  DateTime? createdAt,
  required Map<String, Map<String, dynamic>> logsByDay,
  required Map<String, Map<String, dynamic>> workoutsByDay,
  int windowDays = kAdherenceWindowDays,
}) {
  var nutNum = 0, nutDen = 0;
  var habNum = 0, habDen = 0;
  var woNum = 0, woDen = 0;
  var scoreSum = 0.0, scoreDays = 0;

  // i starts at 1: today is in-progress and never counted against them.
  for (var i = 1; i < windowDays; i++) {
    final day = normalizedToday.subtract(Duration(days: i));
    if (createdAt != null && day.isBefore(createdAt)) continue; // pre-signup
    final key = dateKeyFor(day);
    final log = logsByDay[key];
    final workout = workoutsByDay[key];

    final nut = nutritionMet(log);
    final hab = habitsMet(log);
    final assigned = workout != null;
    final woDone = assigned && workout['isCompleted'] == true;

    nutDen++;
    if (nut) nutNum++;
    habDen++;
    if (hab) habNum++;
    if (assigned) {
      woDen++;
      if (woDone) woNum++;
    }

    final applicable = 2 + (assigned ? 1 : 0);
    final met = (nut ? 1 : 0) + (hab ? 1 : 0) + (woDone ? 1 : 0);
    scoreSum += met / applicable;
    scoreDays++;
  }

  // Recency gap — consecutive fully-silent days walking back from yesterday.
  // NOTE: this breaks (not continues) at the signup boundary — a brand-new
  // client has no silence to answer for.
  var gap = 0;
  for (var i = 1; i < windowDays; i++) {
    final day = normalizedToday.subtract(Duration(days: i));
    if (createdAt != null && day.isBefore(createdAt)) break; // no expectation yet
    final key = dateKeyFor(day);
    if (anyActivity(logsByDay[key], workoutsByDay[key])) break;
    gap++;
  }

  final adherence = scoreDays == 0 ? 1.0 : (scoreSum / scoreDays);

  // 0 = on track, 1 = slipping (watch), 2 = at risk. Status = worst signal.
  final recencyRank = gap >= 3
      ? 2
      : gap == 2
          ? 1
          : 0;
  final adherenceRank = scoreDays == 0
      ? 0
      : adherence < 0.5
          ? 2
          : adherence < 0.75
              ? 1
              : 0;
  final rank = recencyRank > adherenceRank ? recencyRank : adherenceRank;
  final status = rank == 2
      ? 'at_risk'
      : rank == 1
          ? 'slipping'
          : 'on_track';

  final summary =
      'Last 7d: nutrition $nutNum/$nutDen • habits $habNum/$habDen • workouts $woNum/$woDen';
  return AdherenceResult(status: status, summary: summary);
}
