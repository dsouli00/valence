import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:valence/models/user_model.dart';

import '../models/daily_log_model.dart';
import '../models/invite_token_model.dart';
import '../models/meal_model.dart';
import '../models/enums.dart';

/// Central service for all Firestore reads/writes.
///
/// Convention: daily log documents are keyed as "{clientId}_{YYYY-MM-DD}"
/// so each client has exactly one log per calendar day.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generates the deterministic Firestore document ID for a client's daily log.
  String dailyLogId(String clientId, DateTime date) {
    final dateString = _dateKey(date);
    return '${clientId}_$dateString';
  }

  /// Normalizes a date into a stable day key so date comparisons remain consistent.
  String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';
  }

  /// Returns today's log for [clientId], creating a blank one if it doesn't exist yet.
  Future<DailyLog> getOrCreateTodayLog(String clientId, String coachId) async {
    final today = DateTime.now();
    final docId = dailyLogId(clientId, today);

    final docRef = _firestore.collection('daily_logs').doc(docId);
    final doc = await docRef.get();

    if (doc.exists) {
      return DailyLog.fromJson(doc.data()!, doc.id);
    }

    final newLog = DailyLog(
      id: docId,
      clientId: clientId,
      coachId: coachId,
      date: today,
      waterLiters: 0,
      sleepRating: 0,
      weightKg: 0,
      meals: [],
      totalCalories: 0,
      totalProtein: 0,
      totalCarbs: 0,
      totalFat: 0,
    );

    await docRef.set(newLog.toJson());
    return newLog;
  }

  /// Appends [meal] to today's log and increments the running macro totals atomically.
  /// Also updates the client's streak after logging.
  Future<void> addMealToLog(String clientId, Meal meal) async {
    final today = DateTime.now();
    final docId = dailyLogId(clientId, today);

    final logRef = _firestore.collection('daily_logs').doc(docId);

    await logRef.update({
      'meals': FieldValue.arrayUnion([meal.toJson()]),
      'totalCalories': FieldValue.increment(meal.calories),
      'totalProtein': FieldValue.increment(meal.protein),
      'totalCarbs': FieldValue.increment(meal.carbs),
      'totalFat': FieldValue.increment(meal.fat),
    });

    await _updateStreak(clientId);
  }

  /// Replaces one meal inside today's log and recomputes macro totals from source meals.
  Future<void> updateMealInTodayLog(String clientId, Meal updatedMeal) async {
    final docId = dailyLogId(clientId, DateTime.now());
    final logRef = _firestore.collection('daily_logs').doc(docId);

    await _firestore.runTransaction((tx) async {
      final logSnap = await tx.get(logRef);
      if (!logSnap.exists) return;

      final existingMealsRaw = (logSnap.data()?['meals'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final existingMeals =
          existingMealsRaw.map((m) => Meal.fromJson(Map<String, dynamic>.from(m))).toList();

      final idx = existingMeals.indexWhere((m) => m.id == updatedMeal.id);
      if (idx == -1) return;
      existingMeals[idx] = updatedMeal;

      final totals = _computeMealTotals(existingMeals);
      tx.update(logRef, {
        'meals': existingMeals.map((m) => m.toJson()).toList(),
        'totalCalories': totals.calories,
        'totalProtein': totals.protein,
        'totalCarbs': totals.carbs,
        'totalFat': totals.fat,
      });
    });
  }

  /// Deletes one meal from today's log and recomputes macro totals from remaining meals.
  Future<void> deleteMealFromTodayLog(String clientId, String mealId) async {
    final docId = dailyLogId(clientId, DateTime.now());
    final logRef = _firestore.collection('daily_logs').doc(docId);

    await _firestore.runTransaction((tx) async {
      final logSnap = await tx.get(logRef);
      if (!logSnap.exists) return;

      final existingMealsRaw = (logSnap.data()?['meals'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final existingMeals =
          existingMealsRaw.map((m) => Meal.fromJson(Map<String, dynamic>.from(m))).toList();

      existingMeals.removeWhere((m) => m.id == mealId);
      final totals = _computeMealTotals(existingMeals);

      tx.update(logRef, {
        'meals': existingMeals.map((m) => m.toJson()).toList(),
        'totalCalories': totals.calories,
        'totalProtein': totals.protein,
        'totalCarbs': totals.carbs,
        'totalFat': totals.fat,
      });
    });
  }

  /// Fully removes a client from app data so they no longer appear in any coach roster.
  Future<void> deleteClientCompletely(String clientId) async {
    final userRef = _firestore.collection('users').doc(clientId);
    final logs = await _firestore
        .collection('daily_logs')
        .where('clientId', isEqualTo: clientId)
        .get();

    final batch = _firestore.batch();
    for (final doc in logs.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(userRef);
    await batch.commit();
  }

  /// Updates the water intake (in litres) for today's log.
  Future<void> updateWater(String clientId, double liters) async {
    final docId = dailyLogId(clientId, DateTime.now());
    final logRef = _firestore.collection('daily_logs').doc(docId);

    await logRef.update({'waterLiters': liters});
  }

  /// Saves the client's sleep quality rating (1–5) for today.
  Future<void> updateSleep(String clientId, int rating) async {
    final docId = dailyLogId(clientId, DateTime.now());
    final logRef = _firestore.collection('daily_logs').doc(docId);

    await logRef.update({'sleepRating': rating});
  }

  /// Writes the client's weight to today's log AND updates their user profile
  /// in a single batch so both stay consistent.
  Future<void> updateWeight(String clientId, double kg) async {
    final docId = dailyLogId(clientId, DateTime.now());
    final logRef = _firestore.collection('daily_logs').doc(docId);

    final userRef = _firestore.collection('users').doc(clientId);

    final batch = _firestore.batch();
    batch.update(logRef, {'weightKg': kg});
    batch.update(userRef, {'currentWeight': kg});

    await batch.commit();
  }

  /// Real-time stream of today's [DailyLog] for the home screen.
  Stream<DailyLog> streamTodayLog(String clientId) {
    final docId = dailyLogId(clientId, DateTime.now());

    return _firestore
        .collection('daily_logs')
        .doc(docId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        throw Exception("Daily log not found");
      }
      return DailyLog.fromJson(doc.data()!, doc.id);
    });
  }

  /// Increments the client's streak by 1 if they logged yesterday,
  /// resets to 1 if they missed a day, or is a no-op if they already logged today.
  Future<void> _updateStreak(String clientId) async {
    final today = DateTime.now();
    final todayString = _dateKey(today);

    final userRef = _firestore.collection('users').doc(clientId);
    final userDoc = await userRef.get();

    if (!userDoc.exists) return;

    final data = userDoc.data()!;
    final lastLogDate = data['lastLogDate'];
    int currentStreak = data['currentStreak'] ?? 0;

    final yesterday = DateTime(today.year, today.month, today.day).subtract(
      const Duration(days: 1),
    );
    final yesterdayString = _dateKey(yesterday);

    if (lastLogDate == todayString) {
      return;
    }

    if (lastLogDate == yesterdayString) {
      currentStreak += 1;
    } else {
      currentStreak = 1;
    }

    await userRef.update({
      'lastLogDate': todayString,
      'currentStreak': currentStreak,
    });
  }

  /// Real-time stream of all clients assigned to [coachId].
  Stream<List<AppUser>> streamClientsByCoach(String coachId) {
    return _firestore
        .collection('users')
        .where('coachId', isEqualTo: coachId)
        .where('role', isEqualTo: 'client')
        .snapshots()
        .map((event) => event.docs
        .map((doc) => AppUser.fromJson(doc.data(), doc.id))
        .toList());
  }

  /// Creates a signed-quality random invite token and stores it under the coach document.
  Future<String> createCoachInviteToken(
    String coachId, {
    Duration ttl = const Duration(days: 7),
    int maxUses = 1,
  }) async {
    final token = _generateSecureToken();
    final now = DateTime.now();
    final invite = InviteToken(
      token: token,
      createdAt: now,
      expiresAt: now.add(ttl),
      maxUses: maxUses,
      currentUses: 0,
      isActive: true,
    );

    await _firestore.collection('users').doc(coachId).set({
      'inviteTokens': {token: invite.toJson()},
    }, SetOptions(merge: true));

    return token;
  }

  /// Returns a shareable invite URL that can be pasted into chat/email.
  String buildInviteLink(String token) {
    return 'https://valence.app/invite?token=$token';
  }

  /// Extracts the token from a raw token or a URL that contains `token=`.
  String parseInviteToken(String input) {
    final trimmed = input.trim();
    final uri = Uri.tryParse(trimmed);
    final tokenFromQuery = uri?.queryParameters['token'];
    return (tokenFromQuery ?? trimmed).trim();
  }

  /// Validates and consumes an invite token atomically, returning its coachId when valid.
  Future<String?> redeemInviteToken(String rawToken) async {
    final token = parseInviteToken(rawToken);
    if (token.isEmpty) return null;

    final coaches = await _firestore
        .collection('users')
        .where('role', isEqualTo: UserRole.coach.name)
        .where('inviteTokens.$token.token', isEqualTo: token)
        .limit(1)
        .get();

    if (coaches.docs.isEmpty) return null;
    final coachRef = coaches.docs.first.reference;
    final coachId = coaches.docs.first.id;

    return _firestore.runTransaction<String?>((tx) async {
      final coachSnap = await tx.get(coachRef);
      if (!coachSnap.exists) return null;

      final coachData = coachSnap.data() ?? {};
      final tokens = Map<String, dynamic>.from(
        coachData['inviteTokens'] as Map<String, dynamic>? ?? {},
      );
      final tokenRaw = tokens[token];
      if (tokenRaw == null) return null;

      final invite = InviteToken.fromJson(
        Map<String, dynamic>.from(tokenRaw as Map<String, dynamic>),
      );

      final now = DateTime.now();
      final isExpired = now.isAfter(invite.expiresAt);
      final hasCapacity = invite.currentUses < invite.maxUses;
      if (!invite.isActive || isExpired || !hasCapacity) return null;

      final nextUses = invite.currentUses + 1;
      final updatedInvite = InviteToken(
        token: invite.token,
        createdAt: invite.createdAt,
        expiresAt: invite.expiresAt,
        maxUses: invite.maxUses,
        currentUses: nextUses,
        isActive: nextUses < invite.maxUses,
      );
      tokens[token] = updatedInvite.toJson();

      tx.update(coachRef, {'inviteTokens': tokens});
      return coachId;
    });
  }

  String _generateSecureToken({int length = 32}) {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  _MealTotals _computeMealTotals(List<Meal> meals) {
    int calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    for (final meal in meals) {
      calories += meal.calories;
      protein += meal.protein;
      carbs += meal.carbs;
      fat += meal.fat;
    }
    return _MealTotals(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }
}

class _MealTotals {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  const _MealTotals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}
