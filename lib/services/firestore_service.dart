import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:valence/models/user_model.dart';

import '../models/daily_log_model.dart';
import '../models/meal_model.dart';

/// Central service for all Firestore reads/writes.
///
/// Convention: daily log documents are keyed as "{clientId}_{YYYY-MM-DD}"
/// so each client has exactly one log per calendar day.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generates the deterministic Firestore document ID for a client's daily log.
  String dailyLogId(String clientId, DateTime date) {
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${clientId}_$dateString';
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
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final userRef = _firestore.collection('users').doc(clientId);
    final userDoc = await userRef.get();

    if (!userDoc.exists) return;

    final data = userDoc.data()!;
    final lastLogDate = data['lastLogDate'];
    int currentStreak = data['currentStreak'] ?? 0;

    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final yesterdayString =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

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
}