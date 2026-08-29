import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:valence/models/user_model.dart';

import '../models/client_analysis.dart';
import '../models/daily_log_model.dart';
import '../models/habit_model.dart';
import '../models/invite_token_model.dart';
import '../models/meal_model.dart';
import '../models/target_macros.dart';
import '../models/workout_models.dart';
import 'adherence.dart';

/// Central service for ALL Firestore reads/writes — screens never touch
/// `FirebaseFirestore` directly (except AuthProvider for the user doc).
///
/// Collections:
///   users/{uid}                          — profiles, both roles (see AppUser)
///   daily_logs/{clientId_YYYY-MM-DD}     — one tracking doc per client per day
///   assigned_workouts/{clientId_YYYY-MM-DD} — one workout per client per day
///   workout_templates/{autoId}           — coach library
///   invites/{CODE}                       — invite codes, doc id = the code
///   client_analyses/{clientId}           — coach-private AI read of a client
///   outbound_notifications/{autoId}      — push queue drained by the external worker
///
/// Two conventions to respect when adding methods:
///  1. Date-keyed doc ids ("{clientId}_{YYYY-MM-DD}") give direct gets, no
///     queries, and a hard one-per-day guarantee. Always build them via
///     [dailyLogId]/[workoutAssignmentId], never by hand.
///  2. Any write that changes what a client "did" (meals, water, sleep,
///     weight, workout progress) must end with `_refreshClientStatus` so the
///     coach roster's status/summary stays truthful.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generates the deterministic Firestore document ID for a client's daily log.
  String dailyLogId(String clientId, DateTime date) {
    final dateString = _dateKey(date);
    return '${clientId}_$dateString';
  }

  /// Normalizes a date into a stable day key so date comparisons remain
  /// consistent. Delegates to [dateKeyFor] so doc ids and the adherence
  /// scoring can never disagree about what a "day" is.
  String _dateKey(DateTime date) => dateKeyFor(date);

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

    await _markActivity(clientId);
    await _refreshClientStatus(clientId);
  }

  /// Replaces one meal inside today's log and recomputes macro totals from source meals.
  ///
  /// Runs in a transaction (unlike [addMealToLog]'s cheap increments) because
  /// editing requires read-modify-write of the whole array — totals are
  /// recomputed from scratch so they can never drift from the meals.
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
    await _refreshClientStatus(clientId);
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
    await _refreshClientStatus(clientId);
  }

  /// Fully removes a client from app data so they no longer appear in any coach roster.
  ///
  /// If [requestedByCoachId] is provided, an admin-task document is also written
  /// so backend automation can delete the Firebase Auth account server-side.
  Future<void> deleteClientCompletely(
    String clientId, {
    String? requestedByCoachId,
  }) async {
    final userRef = _firestore.collection('users').doc(clientId);
    final logs = await _firestore
        .collection('daily_logs')
        .where('clientId', isEqualTo: clientId)
        .get();
    final workouts = await _firestore
        .collection('assigned_workouts')
        .where('clientId', isEqualTo: clientId)
        .get();

    final batch = _firestore.batch();
    for (final doc in logs.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in workouts.docs) {
      batch.delete(doc.reference);
    }
    // The AI analysis is ABOUT this person — it must not outlive them.
    batch.delete(_firestore.collection('client_analyses').doc(clientId));

    if (requestedByCoachId != null && requestedByCoachId.trim().isNotEmpty) {
      final requestRef = _firestore
          .collection('admin_tasks')
          .doc('auth_user_deletion_requests')
          .collection('requests')
          .doc(clientId);
      batch.set(
        requestRef,
        {
          'clientId': clientId,
          'requestedByCoachId': requestedByCoachId,
          'status': 'pending',
          'source': 'coach_client_delete',
          'requestedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    batch.delete(userRef);
    await batch.commit();
  }

  /// Deletes a CLIENT's own account data: every daily log + assigned workout
  /// keyed to them, plus their user doc. Removing the user doc also drops them
  /// from their coach's roster (a live query on `coachId`). The Firebase Auth
  /// account itself is deleted by [AuthProvider.deleteAccount] after this.
  /// (Pre-launch volumes fit a single batch; chunk if logs ever exceed ~450.)
  Future<void> deleteOwnClientData(String clientId) async {
    final batch = _firestore.batch();

    final logs = await _firestore
        .collection('daily_logs')
        .where('clientId', isEqualTo: clientId)
        .get();
    for (final doc in logs.docs) {
      batch.delete(doc.reference);
    }

    final workouts = await _firestore
        .collection('assigned_workouts')
        .where('clientId', isEqualTo: clientId)
        .get();
    for (final doc in workouts.docs) {
      batch.delete(doc.reference);
    }

    // Coach-private, but it is the CLIENT's personal data being described — a
    // self-delete must take it with them.
    batch.delete(_firestore.collection('client_analyses').doc(clientId));

    batch.delete(_firestore.collection('users').doc(clientId));
    await batch.commit();
  }

  /// Deletes a COACH's own account data: their workout templates + invite codes,
  /// then unlinks every client (so they aren't orphaned to a deleted coach —
  /// they get routed back to the link-coach screen), then their user doc. The
  /// Firebase Auth account is deleted by [AuthProvider.deleteAccount] after this.
  /// Client data itself is preserved (those are separate accounts).
  Future<void> deleteCoachData(String coachId) async {
    final batch = _firestore.batch();

    final templates = await _firestore
        .collection('workout_templates')
        .where('coachId', isEqualTo: coachId)
        .get();
    for (final doc in templates.docs) {
      batch.delete(doc.reference);
    }

    final invites = await _firestore
        .collection('invites')
        .where('coachId', isEqualTo: coachId)
        .get();
    for (final doc in invites.docs) {
      batch.delete(doc.reference);
    }

    final analyses = await _firestore
        .collection('client_analyses')
        .where('coachId', isEqualTo: coachId)
        .get();
    for (final doc in analyses.docs) {
      batch.delete(doc.reference);
    }

    final clients = await _firestore
        .collection('users')
        .where('coachId', isEqualTo: coachId)
        .get();
    for (final doc in clients.docs) {
      batch.update(doc.reference, {'coachId': null, 'status': 'unconfigured'});
    }

    batch.delete(_firestore.collection('users').doc(coachId));
    await batch.commit();
  }

  /// Updates the water intake (in litres) for today's log.
  Future<void> updateWater(String clientId, double liters) async {
    final docId = dailyLogId(clientId, DateTime.now());
    final logRef = _firestore.collection('daily_logs').doc(docId);

    await logRef.update({'waterLiters': liters});
    if (liters > 0) await _markActivity(clientId);
    await _refreshClientStatus(clientId);
  }

  /// Saves the client's sleep quality rating (1–5) for today.
  Future<void> updateSleep(String clientId, int rating) async {
    final docId = dailyLogId(clientId, DateTime.now());
    final logRef = _firestore.collection('daily_logs').doc(docId);

    await logRef.update({'sleepRating': rating});
    if (rating > 0) await _markActivity(clientId);
    await _refreshClientStatus(clientId);
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
    if (kg > 0) await _markActivity(clientId);
    await _refreshClientStatus(clientId);
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

  /// Real-time stream of today's [DailyLog], returning null when none exists yet.
  Stream<DailyLog?> streamTodayLogNullable(String clientId) {
    final docId = dailyLogId(clientId, DateTime.now());

    return _firestore.collection('daily_logs').doc(docId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return DailyLog.fromJson(doc.data()!, doc.id);
    });
  }

  /// Real-time stream for a specific day log, returning null when none exists.
  Stream<DailyLog?> streamLogForDateNullable(String clientId, DateTime date) {
    final docId = dailyLogId(clientId, date);

    return _firestore.collection('daily_logs').doc(docId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return DailyLog.fromJson(doc.data()!, doc.id);
    });
  }

  /// Real-time stream of recent daily logs for a client, sorted oldest -> newest.
  ///
  /// This avoids requiring a composite index by sorting in memory after filtering.
  Stream<List<DailyLog>> streamRecentLogs(String clientId, {int days = 14}) {
    final safeDays = days <= 0 ? 14 : days;
    return _firestore
        .collection('daily_logs')
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((event) {
      final now = DateTime.now();
      final cutoff = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: safeDays - 1));

      final logs = event.docs
          .map((doc) => DailyLog.fromJson(doc.data(), doc.id))
          .where((log) {
        final d = DateTime(log.date.year, log.date.month, log.date.day);
        return !d.isBefore(cutoff);
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      return logs;
    });
  }

  /// Real-time stream for a single user profile document.
  Stream<AppUser?> streamUserById(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromJson(doc.data()!, doc.id);
    });
  }

  /// Saves a coach note into today's existing log.
  ///
  /// Returns false when today's log does not exist yet.
  Future<bool> saveCoachNoteForToday(String clientId, String note) async {
    return saveCoachNoteForDate(clientId, DateTime.now(), note);
  }

  /// Stores the user's app language code ('en'/'ar'/…) so the notifier can
  /// localize pushes for them (the sender's locale ≠ the recipient's).
  Future<void> saveUserLocale(String uid, String code) async {
    await _firestore.collection('users').doc(uid).set(
      {'locale': code},
      SetOptions(merge: true),
    );
  }

  /// Queues a push for [toUid], delivered by the external notifier job. Best
  /// effort — never blocks the primary write. The app can't send FCM itself (no
  /// server credential), so the free worker drains `outbound_notifications` and
  /// renders the text in the recipient's language from [type] + [params].
  Future<void> _enqueueNotification({
    required String toUid,
    required String type,
    Map<String, dynamic> params = const {},
  }) async {
    try {
      await _firestore.collection('outbound_notifications').add({
        'toUid': toUid,
        'type': type,
        'params': params,
        'sent': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Saves a coach note into a specific day's existing log (overwrite, not
  /// append) and queues a push to the client. Returns false when that day has
  /// no log yet — a note can't exist on a day the client never opened.
  Future<bool> saveCoachNoteForDate(
    String clientId,
    DateTime date,
    String note,
  ) async {
    final docId = dailyLogId(clientId, date);
    final docRef = _firestore.collection('daily_logs').doc(docId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) return false;

    await docRef.update({
      'coachNote': note.trim(),
      'coachNoteAt': FieldValue.serverTimestamp(),
    });
    await _enqueueNotification(toUid: clientId, type: 'coach_note');
    return true;
  }

  /// Saves a client note into a specific day's existing log.
  ///
  /// Returns false when the selected day's log does not exist yet.
  Future<bool> saveClientNoteForDate(
    String clientId,
    DateTime date,
    String note,
  ) async {
    final docId = dailyLogId(clientId, date);
    final docRef = _firestore.collection('daily_logs').doc(docId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) return false;

    await docRef.update({
      'clientNote': note.trim(),
      'clientNoteAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  /// Records that the client DID SOMETHING today: advances `lastLogDate` and
  /// their streak.
  ///
  /// Call this from every write that represents real activity — and only when
  /// the write is positive (water set to 0 or a habit un-checked is not a sign
  /// of life). For a long time this was called from `addMealToLog` and nowhere
  /// else, which meant a client who logged water, sleep and weight every single
  /// day still had `lastLogDate` frozen at their last meal. Three separate
  /// things read that field and all three lied because of it:
  ///
  ///   • the coach roster's live recency bucket, which escalated them to Alert
  ///     and printed "Quiet for 3 days";
  ///   • their own streak, shown on Home, on the share card, and fed into
  ///     `computeWinSummary`;
  ///   • the external at-risk worker, which pushed their coach
  ///     "X hasn't logged in 3 days".
  ///
  /// Meanwhile `anyActivity()` in the adherence engine counted a single glass
  /// of water as a sign of life, so the two halves of the same judgement
  /// disagreed about the same client. The guards at each call site mirror that
  /// function deliberately — keep them in step.
  Future<void> _markActivity(String clientId) => _updateStreak(clientId);

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

  /// THE adherence engine. Recomputes the client's [ClientStatus] +
  /// human-readable `statusSummary` and denormalizes both onto the user doc,
  /// so the coach roster renders from one query. Called after EVERY logging
  /// mutation (meals, water, sleep, weight, workouts, assignment changes) —
  /// if you add a new logging write, call this at the end.
  /// The scoring rules are documented in the block comment below; don't
  /// tweak thresholds casually, they were tuned across several iterations.
  Future<void> _refreshClientStatus(String clientId) async {
    final userRef = _firestore.collection('users').doc(clientId);
    final userDoc = await userRef.get();
    if (!userDoc.exists) return;

    final userData = userDoc.data() ?? {};
    final hasMacros = userData['targetMacros'] != null;
    final existingStatus = (userData['status'] as String?) ?? 'unconfigured';
    if (!hasMacros || existingStatus == 'unconfigured') {
      await userRef.set({
        'status': 'unconfigured',
        'statusSummary': 'Needs initial configuration from coach.',
      }, SetOptions(merge: true));
      return;
    }

    // ------------------------------------------------------------------
    // Robust adherence model (high-end coaching app):
    //   • Rolling 7-day window of COMPLETED days (today is in-progress and is
    //     never penalised — it can only improve the picture).
    //   • Window is bounded by the client's signup date (no pre-signup days).
    //   • Status = the WORST of two independent signals:
    //       - Recency: how many consecutive recent days they went fully silent.
    //       - Consistency: average share of expected pillars met per day.
    //   • Per-pillar expectations: Nutrition + Habits are daily; Training only
    //     counts on days a workout was actually assigned.
    // ------------------------------------------------------------------
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    const windowDays = kAdherenceWindowDays; // today + 7 completed days
    final windowKeys = List.generate(
      windowDays,
      (i) => _dateKey(normalizedToday.subtract(Duration(days: i))),
    ).toSet();

    DateTime? createdAt;
    final createdRaw = userData['createdAt'];
    if (createdRaw is Timestamp) {
      final d = createdRaw.toDate();
      createdAt = DateTime(d.year, d.month, d.day);
    }

    final logsSnap = await _firestore
        .collection('daily_logs')
        .where('clientId', isEqualTo: clientId)
        .get();
    final workoutsSnap = await _firestore
        .collection('assigned_workouts')
        .where('clientId', isEqualTo: clientId)
        .get();

    final logsByDay = <String, Map<String, dynamic>>{};
    for (final doc in logsSnap.docs) {
      final key = _extractDateKeyFromDocId(doc.id);
      if (key == null || !windowKeys.contains(key)) continue;
      logsByDay[key] = doc.data();
    }
    final workoutsByDay = <String, Map<String, dynamic>>{};
    for (final doc in workoutsSnap.docs) {
      final key = _extractDateKeyFromDocId(doc.id);
      if (key == null || !windowKeys.contains(key)) continue;
      workoutsByDay[key] = doc.data();
    }

    // The scoring itself is pure and lives in services/adherence.dart, where it
    // is unit-tested. This method stays responsible only for the I/O around it.
    final result = computeAdherence(
      normalizedToday: normalizedToday,
      createdAt: createdAt,
      logsByDay: logsByDay,
      workoutsByDay: workoutsByDay,
      windowDays: windowDays,
    );

    await userRef.set({
      'status': result.status,
      'statusSummary': result.summary,
    }, SetOptions(merge: true));
  }

  /// Pulls the 'YYYY-MM-DD' suffix out of a date-keyed doc id — lets the
  /// status engine bucket logs/workouts by day without parsing Timestamps.
  String? _extractDateKeyFromDocId(String docId) {
    final idx = docId.lastIndexOf('_');
    if (idx == -1 || idx >= docId.length - 1) return null;
    return docId.substring(idx + 1);
  }

  /// The coach's latest AI analysis for [clientId], or null if none yet.
  ///
  /// One doc per client (id = clientId, same deterministic-id convention as
  /// daily logs) — this is the CURRENT read, not a history. A one-shot get,
  /// not a stream: an analysis only changes when the coach asks for one, so a
  /// live listener would just cost reads for nothing.
  Future<ClientAnalysis?> getClientAnalysis(String clientId) async {
    final doc = await _firestore.collection('client_analyses').doc(clientId).get();
    if (!doc.exists) return null;
    return ClientAnalysis.fromJson(doc.data()!, doc.id);
  }

  /// Stores/overwrites the latest analysis for a client.
  ///
  /// NOTE: `client_analyses` is coach-private (see firestore.rules) — this is
  /// deliberately NOT written onto the user doc, which any signed-in user
  /// (including the client) can read.
  Future<void> saveClientAnalysis(ClientAnalysis analysis) async {
    await _firestore
        .collection('client_analyses')
        .doc(analysis.clientId)
        .set(analysis.toJson());
  }

  /// Recent assigned workouts for a client, for the AI analysis window.
  /// Sorted oldest -> newest in memory (same no-composite-index approach as
  /// [streamRecentLogs]).
  Future<List<AssignedWorkout>> getRecentWorkouts(
    String clientId, {
    int days = 14,
  }) async {
    final snap = await _firestore
        .collection('assigned_workouts')
        .where('clientId', isEqualTo: clientId)
        .get();
    final now = DateTime.now();
    final cutoff =
        DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    return snap.docs
        .map((d) => AssignedWorkout.fromJson(d.data(), d.id))
        .where((w) {
          final d = DateTime(w.date.year, w.date.month, w.date.day);
          return !d.isBefore(cutoff);
        })
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Real-time stream of all clients assigned to [coachId].
  ///
  /// PITFALL: every call returns a NEW stream. Cache it in your State and
  /// only recreate when coachId changes — calling this inline in build()
  /// above a StreamBuilder resets it to `waiting` on every setState (this
  /// caused the "skeleton flashes on every search keystroke" bug).
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

  /// Deterministic doc id for an assigned workout — same "{clientId}_{day}"
  /// scheme as daily logs, so one workout per client per day.
  String workoutAssignmentId(String clientId, DateTime date) {
    final dateString = _dateKey(date);
    return '${clientId}_$dateString';
  }

  /// Creates a reusable workout template in coach library.
  Future<String> createWorkoutTemplate({
    required String coachId,
    required String name,
    required List<WorkoutExercise> exercises,
  }) async {
    final ref = _firestore.collection('workout_templates').doc();
    await ref.set({
      'coachId': coachId,
      'name': name.trim(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Real-time stream of workout templates for one coach.
  Stream<List<WorkoutTemplate>> streamWorkoutTemplates(String coachId) {
    return _firestore
        .collection('workout_templates')
        .where('coachId', isEqualTo: coachId)
        .snapshots()
        .map((event) {
      final templates = event.docs
          .map((doc) => WorkoutTemplate.fromJson(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return templates;
    });
  }

  /// One-shot fetch of the coach's templates (for pickers like the swap/assign
  /// sheets, where a live stream isn't needed).
  Future<List<WorkoutTemplate>> getWorkoutTemplates(String coachId) async {
    final snapshot = await _firestore
        .collection('workout_templates')
        .where('coachId', isEqualTo: coachId)
        .get();
    final templates = snapshot.docs
        .map((doc) => WorkoutTemplate.fromJson(doc.data(), doc.id))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return templates;
  }

  /// Edits a library template. Does NOT touch already-assigned workouts —
  /// assignments hold their own frozen copy of the exercises by design.
  Future<void> updateWorkoutTemplate({
    required String templateId,
    required String name,
    required List<WorkoutExercise> exercises,
  }) async {
    await _firestore.collection('workout_templates').doc(templateId).update({
      'name': name.trim(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteWorkoutTemplate(String templateId) async {
    await _firestore.collection('workout_templates').doc(templateId).delete();
  }

  /// Builds the Firestore payload for a freshly-assigned workout on [date]:
  /// resets per-set progress so the client starts clean each day.
  Map<String, dynamic> _assignmentData({
    required String coachId,
    required String clientId,
    required DateTime date,
    required String title,
    required List<WorkoutExercise> exercises,
  }) {
    return {
      'coachId': coachId,
      'clientId': clientId,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'title': title.trim(),
      'exercises': exercises
          .map(
            (e) => e
                .copyWith(
                  completedSets: 0,
                  loggedRepsBySet: List.generate(e.sets, (_) => 0),
                  targetWeightKgBySet: e.targetWeightKgBySet.length >= e.sets
                      ? e.targetWeightKgBySet.take(e.sets).toList()
                      : [
                          ...e.targetWeightKgBySet,
                          ...List.generate(
                            e.sets - e.targetWeightKgBySet.length,
                            (_) => null,
                          ),
                        ],
                  loggedWeightKgBySet: List.generate(e.sets, (_) => null),
                )
                .toJson(),
          )
          .toList(),
      'isCompleted': false,
      'completedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Assigns a workout to a client for a specific day.
  Future<void> assignWorkoutToClient({
    required String coachId,
    required String clientId,
    required DateTime date,
    required String title,
    required List<WorkoutExercise> exercises,
  }) async {
    final docId = workoutAssignmentId(clientId, date);
    await _firestore.collection('assigned_workouts').doc(docId).set(
          _assignmentData(
            coachId: coachId,
            clientId: clientId,
            date: date,
            title: title,
            exercises: exercises,
          ),
        );
    await _refreshClientStatus(clientId);
  }

  /// Assigns the same workout across multiple days in one batch (recurring /
  /// repeating programming). Each day is its own assignment doc, so an existing
  /// assignment on any of [dates] is overwritten. Returns the number of days
  /// written. Duplicate dates are de-duplicated by their day key.
  Future<int> assignWorkoutToClientDates({
    required String coachId,
    required String clientId,
    required List<DateTime> dates,
    required String title,
    required List<WorkoutExercise> exercises,
  }) async {
    // De-dupe by day key so the same day isn't written twice in one batch
    // (Firestore rejects two writes to the same doc in a single batch).
    final byKey = <String, DateTime>{};
    for (final d in dates) {
      byKey[_dateKey(d)] = DateTime(d.year, d.month, d.day);
    }
    final uniqueDates = byKey.values.toList();
    if (uniqueDates.isEmpty) return 0;

    final batch = _firestore.batch();
    for (final date in uniqueDates) {
      final ref =
          _firestore.collection('assigned_workouts').doc(workoutAssignmentId(clientId, date));
      batch.set(
        ref,
        _assignmentData(
          coachId: coachId,
          clientId: clientId,
          date: date,
          title: title,
          exercises: exercises,
        ),
      );
    }
    await batch.commit();
    await _refreshClientStatus(clientId);
    await _enqueueNotification(
      toUid: clientId,
      type: 'new_workout',
      params: {'title': title},
    );
    return uniqueDates.length;
  }

  /// Real-time stream for a specific assigned workout day.
  Stream<AssignedWorkout?> streamAssignedWorkoutForDate(String clientId, DateTime date) {
    final docId = workoutAssignmentId(clientId, date);
    return _firestore.collection('assigned_workouts').doc(docId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AssignedWorkout.fromJson(doc.data()!, doc.id);
    });
  }

  /// Updates completed sets for a specific exercise in an assigned workout.
  ///
  /// This and the two set-level writers below all use a transaction: the
  /// exercises array must be read-modify-written as a whole, and rapid taps
  /// on set rows would otherwise race and lose updates. Each also derives
  /// `isCompleted` from the full exercise list so the day's done-state can
  /// never disagree with the per-set data.
  Future<void> updateWorkoutExerciseProgress({
    required String clientId,
    required DateTime date,
    required int exerciseIndex,
    required int completedSets,
  }) async {
    final docId = workoutAssignmentId(clientId, date);
    final docRef = _firestore.collection('assigned_workouts').doc(docId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;

      final data = snap.data()!;
      final exerciseRaw = (data['exercises'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (exerciseIndex < 0 || exerciseIndex >= exerciseRaw.length) return;

      final current = exerciseRaw[exerciseIndex];
      final sets = (current['sets'] as num?)?.toInt() ?? 0;
      final safeCompleted = completedSets.clamp(0, sets);
      current['completedSets'] = safeCompleted;
      exerciseRaw[exerciseIndex] = current;

      final done = _areAllExercisesComplete(exerciseRaw);

      tx.update(docRef, {
        'exercises': exerciseRaw,
        'isCompleted': done,
        'completedAt': done ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    if (completedSets > 0) await _markActivity(clientId);
    await _refreshClientStatus(clientId);
  }

  /// Updates reps done for a specific set in a specific exercise.
  Future<void> updateWorkoutSetRep({
    required String clientId,
    required DateTime date,
    required int exerciseIndex,
    required int setIndex,
    required int repsDone,
  }) async {
    final docId = workoutAssignmentId(clientId, date);
    final docRef = _firestore.collection('assigned_workouts').doc(docId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;

      final data = snap.data()!;
      final exerciseRaw = (data['exercises'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (exerciseIndex < 0 || exerciseIndex >= exerciseRaw.length) return;

      final current = exerciseRaw[exerciseIndex];
      final sets = (current['sets'] as num?)?.toInt() ?? 0;
      if (setIndex < 0 || setIndex >= sets) return;

      final rawList = (current['loggedRepsBySet'] as List<dynamic>? ?? const [])
          .map((e) => (e as num?)?.toInt() ?? 0)
          .toList();
      final padded = rawList.length >= sets
          ? rawList.take(sets).toList()
          : [...rawList, ...List.generate(sets - rawList.length, (_) => 0)];
      padded[setIndex] = repsDone.clamp(0, 1000);
      current['loggedRepsBySet'] = padded;
      current['completedSets'] = padded.where((v) => v > 0).length;
      exerciseRaw[exerciseIndex] = current;

      final done = _areAllExercisesComplete(exerciseRaw);
      tx.update(docRef, {
        'exercises': exerciseRaw,
        'isCompleted': done,
        'completedAt': done ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    if (repsDone > 0) await _markActivity(clientId);
    await _refreshClientStatus(clientId);
  }

  /// Updates lifted weight (kg) for a specific set in a specific exercise.
  Future<void> updateWorkoutSetWeight({
    required String clientId,
    required DateTime date,
    required int exerciseIndex,
    required int setIndex,
    required double? weightKg,
  }) async {
    final docId = workoutAssignmentId(clientId, date);
    final docRef = _firestore.collection('assigned_workouts').doc(docId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;

      final data = snap.data()!;
      final exerciseRaw = (data['exercises'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (exerciseIndex < 0 || exerciseIndex >= exerciseRaw.length) return;

      final current = exerciseRaw[exerciseIndex];
      final sets = (current['sets'] as num?)?.toInt() ?? 0;
      if (setIndex < 0 || setIndex >= sets) return;

      final rawList = (current['loggedWeightKgBySet'] as List<dynamic>? ?? const [])
          .map((e) => e == null ? null : (e as num).toDouble())
          .toList();
      final padded = rawList.length >= sets
          ? rawList.take(sets).toList()
          : [...rawList, ...List.generate(sets - rawList.length, (_) => null)];
      padded[setIndex] = weightKg?.clamp(0, 1000).toDouble();
      current['loggedWeightKgBySet'] = padded;
      exerciseRaw[exerciseIndex] = current;

      final done = _areAllExercisesComplete(exerciseRaw);
      tx.update(docRef, {
        'exercises': exerciseRaw,
        'isCompleted': done,
        'completedAt': done ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    if ((weightKg ?? 0) > 0) await _markActivity(clientId);
    await _refreshClientStatus(clientId);
  }

  /// Updates an existing assigned workout with new title/exercises.
  Future<void> updateAssignedWorkout({
    required String clientId,
    required DateTime date,
    required String title,
    required List<WorkoutExercise> exercises,
  }) async {
    final docId = workoutAssignmentId(clientId, date);
    final docRef = _firestore.collection('assigned_workouts').doc(docId);
      final normalized = exercises
        .map((e) {
          final repsBySet = e.loggedRepsBySet.length >= e.sets
              ? e.loggedRepsBySet.take(e.sets).toList()
              : [...e.loggedRepsBySet, ...List.generate(e.sets - e.loggedRepsBySet.length, (_) => 0)];
          return e.copyWith(
            completedSets: repsBySet.where((v) => v > 0).length,
            loggedRepsBySet: repsBySet,
            targetWeightKgBySet: e.targetWeightKgBySet.length >= e.sets
                ? e.targetWeightKgBySet.take(e.sets).toList()
                : [
                    ...e.targetWeightKgBySet,
                    ...List.generate(e.sets - e.targetWeightKgBySet.length, (_) => null),
                  ],
            loggedWeightKgBySet: e.loggedWeightKgBySet.length >= e.sets
                ? e.loggedWeightKgBySet.take(e.sets).toList()
                : [
                    ...e.loggedWeightKgBySet,
                    ...List.generate(e.sets - e.loggedWeightKgBySet.length, (_) => null),
                  ],
          );
        })
        .toList();
    final done = normalized.every((e) => e.sets > 0 && e.completedSets >= e.sets);
    await docRef.update({
      'title': title.trim(),
      'exercises': normalized.map((e) => e.toJson()).toList(),
      'isCompleted': done,
      'completedAt': done ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _refreshClientStatus(clientId);
  }

  Future<void> deleteAssignedWorkout({
    required String clientId,
    required DateTime date,
  }) async {
    final docId = workoutAssignmentId(clientId, date);
    await _firestore.collection('assigned_workouts').doc(docId).delete();
    await _refreshClientStatus(clientId);
  }

  /// Toggles done state for assigned workout.
  Future<void> setAssignedWorkoutDone({
    required String clientId,
    required DateTime date,
    required bool isDone,
  }) async {
    final docId = workoutAssignmentId(clientId, date);
    await _firestore.collection('assigned_workouts').doc(docId).update({
      'isCompleted': isDone,
      'completedAt': isDone ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (isDone) await _markActivity(clientId);
    await _refreshClientStatus(clientId);
  }

  /// A workout day counts as complete when every exercise has all its sets
  /// logged. Prefers per-set reps when present; falls back to the legacy
  /// `completedSets` counter for docs that predate per-set logging.
  bool _areAllExercisesComplete(List<Map<String, dynamic>> exerciseRaw) {
    return exerciseRaw.every((e) {
      final eSets = (e['sets'] as num?)?.toInt() ?? 0;
      final repsBySet = (e['loggedRepsBySet'] as List<dynamic>? ?? const [])
          .map((v) => (v as num?)?.toInt() ?? 0)
          .toList();
      if (eSets <= 0) return false;
      if (repsBySet.isNotEmpty) {
        final repsFilled = repsBySet.length >= eSets
            ? repsBySet.take(eSets).toList()
            : [...repsBySet, ...List.generate(eSets - repsBySet.length, (_) => 0)];
        return repsFilled.every((v) => v > 0);
      }
      final eDone = (e['completedSets'] as num?)?.toInt() ?? 0;
      return eDone >= eSets;
    });
  }

  /// Updates a client's macro targets and optionally marks the profile configured.
  Future<void> updateClientMacros(
    String clientId,
    TargetMacros macros, {
    bool markConfigured = true,
  }) async {
    final payload = <String, dynamic>{
      'targetMacros': macros.toJson(),
    };
    if (markConfigured) {
      payload['status'] = 'on_track';
    }
    await _firestore.collection('users').doc(clientId).update(payload);
    await _refreshClientStatus(clientId);
  }

  /// Saves a client's intake (stats + goal) plus the auto-calculated targets,
  /// and marks them configured so they leave "setup" mode.
  Future<void> saveClientIntake(
    String clientId, {
    required int age,
    required double heightCm,
    required double currentWeight,
    required double targetWeight,
    required String sex,
    required String activityLevel,
    required String goal,
    required TargetMacros macros,
    String? priorTracking,
    String? weightUnit,
  }) async {
    await _firestore.collection('users').doc(clientId).set({
      'age': age,
      'heightCm': heightCm,
      'currentWeight': currentWeight,
      'targetWeight': targetWeight,
      'sex': sex,
      'activityLevel': activityLevel,
      'goal': goal,
      'targetMacros': macros.toJson(),
      'status': 'on_track',
      // Captured for product insight only (never gates the app).
      'priorTracking': ?priorTracking,
      // Display preference; values stay canonical metric regardless.
      'weightUnit': ?weightUnit,
    }, SetOptions(merge: true));
    await _refreshClientStatus(clientId);
  }

  /// Sets the coach-defined custom habits for a client. Additive — these
  /// supplement the core water/sleep/weight pillars and do not affect the
  /// adherence status engine.
  Future<void> setClientHabits(
    String clientId,
    List<HabitDefinition> habits,
  ) async {
    await _firestore.collection('users').doc(clientId).set({
      'customHabits': habits.map((h) => h.toJson()).toList(),
    }, SetOptions(merge: true));
  }

  /// Toggles a custom habit's completion for the client's CURRENT day. Merges a
  /// single key into `habitChecks` so it can't clobber meals or other habits.
  Future<void> toggleHabitCompletion(
    String clientId,
    String coachId,
    String habitId,
    bool done,
  ) async {
    await getOrCreateTodayLog(clientId, coachId);
    final docId = dailyLogId(clientId, DateTime.now());
    await _firestore.collection('daily_logs').doc(docId).set({
      'habitChecks': {habitId: done},
    }, SetOptions(merge: true));
    if (done) await _markActivity(clientId);
  }

  /// Saves a coach's first-run intake (profile + business context) and marks
  /// them onboarded so they aren't routed back through it.
  Future<void> saveCoachIntake(
    String coachId, {
    required List<String> specialties,
    required String experience,
    required String rosterBand,
    required String priorTool,
  }) async {
    await _firestore.collection('users').doc(coachId).set({
      'specialties': specialties,
      'coachExperience': experience,
      'rosterBand': rosterBand,
      'priorTool': priorTool,
      'coachOnboarded': true,
    }, SetOptions(merge: true));
  }

  /// Saves this device's FCM push token to the user doc so the send-worker can
  /// target it. Stored canonically; the worker prunes invalid ones on send.
  Future<void> saveFcmToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  /// Removes the push token on sign-out so a shared device doesn't keep getting
  /// the previous user's pushes.
  Future<void> clearFcmToken(String uid) async {
    await _firestore.collection('users').doc(uid).set(
      {'fcmToken': FieldValue.delete()},
      SetOptions(merge: true),
    );
  }

  /// Sets a coach's subscription tier (the entitlement source the app gates on).
  /// Called after a successful purchase/restore; `tierId` is a [PlanDef.id].
  Future<void> setSubscriptionTier(
    String coachId,
    String tierId, {
    DateTime? expiry,
  }) async {
    await _firestore.collection('users').doc(coachId).set({
      'subscriptionTier': tierId,
      if (expiry != null) 'subscriptionExpiryDate': Timestamp.fromDate(expiry),
    }, SetOptions(merge: true));
  }

  /// Updates the user's display name in Firestore.
  Future<void> updateUserName(String userId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }
    await _firestore.collection('users').doc(userId).update({'name': trimmed});
  }

  /// Merges lightweight user preferences/settings onto the user profile.
  ///
  /// Intended for profile/settings toggles (for example notifications and units).
  Future<void> updateUserSettings(
    String userId,
    Map<String, dynamic> settings,
  ) async {
    if (settings.isEmpty) return;
    await _firestore.collection('users').doc(userId).set(
      settings,
      SetOptions(merge: true),
    );
  }

  /// Creates a secure random invite token. The source of truth for redemption
  /// is a top-level `invites/{token}` doc (direct lookup by id, no fragile
  /// nested-map query). A copy is also kept on the coach doc for record-keeping.
  Future<String> createCoachInviteToken(
    String coachId, {
    Duration ttl = const Duration(days: 7),
    int maxUses = 1,
  }) async {
    final token = await _generateUniqueInviteCode();
    final now = DateTime.now();
    final invite = InviteToken(
      token: token,
      createdAt: now,
      expiresAt: now.add(ttl),
      maxUses: maxUses,
      currentUses: 0,
      isActive: true,
    );

    await _firestore.collection('invites').doc(token).set({
      'coachId': coachId,
      ...invite.toJson(),
    });

    await _firestore.collection('users').doc(coachId).set({
      'inviteTokens': {token: invite.toJson()},
    }, SetOptions(merge: true));

    return token;
  }

  /// Returns a shareable invite URL that can be pasted into chat/email.
  String buildInviteLink(String token) {
    return 'https://valence.app/invite?token=$token';
  }

  /// Normalises a client's input into an invite code. Accepts a bare code or a
  /// legacy link containing `token=`; codes are uppercase + space-insensitive.
  String parseInviteToken(String input) {
    final trimmed = input.trim();
    final uri = Uri.tryParse(trimmed);
    final tokenFromQuery = uri?.queryParameters['token'];
    return (tokenFromQuery ?? trimmed).trim().replaceAll(' ', '').toUpperCase();
  }

  bool _inviteUsable(Map<String, dynamic> data) {
    final isActive = data['isActive'] as bool? ?? false;
    if (!isActive) return false;
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
    if (expiresAt != null && DateTime.now().isAfter(expiresAt)) return false;
    final maxUses = (data['maxUses'] as num?)?.toInt() ?? 1;
    final currentUses = (data['currentUses'] as num?)?.toInt() ?? 0;
    return currentUses < maxUses;
  }

  /// Checks an invite WITHOUT consuming it, returning its coachId when valid.
  /// Used before account creation so a failed signup never burns the link.
  Future<String?> validateInviteToken(String rawToken) async {
    final token = parseInviteToken(rawToken);
    if (token.isEmpty) return null;
    final snap = await _firestore.collection('invites').doc(token).get();
    if (!snap.exists) return null;
    final data = snap.data()!;
    if (!_inviteUsable(data)) return null;
    return data['coachId'] as String?;
  }

  /// Atomically validates and CONSUMES one use of an invite, returning its
  /// coachId. The transaction guarantees a single-use link can never be
  /// redeemed by two clients (the second redeem sees no remaining capacity).
  Future<String?> redeemInviteToken(String rawToken) async {
    final token = parseInviteToken(rawToken);
    if (token.isEmpty) return null;
    final ref = _firestore.collection('invites').doc(token);

    return _firestore.runTransaction<String?>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return null;
      final data = snap.data()!;
      if (!_inviteUsable(data)) return null;

      final coachId = data['coachId'] as String?;
      if (coachId == null) return null;

      final maxUses = (data['maxUses'] as num?)?.toInt() ?? 1;
      final nextUses = ((data['currentUses'] as num?)?.toInt() ?? 0) + 1;
      tx.update(ref, {
        'currentUses': nextUses,
        'isActive': nextUses < maxUses,
        'lastRedeemedAt': FieldValue.serverTimestamp(),
      });
      return coachId;
    });
  }

  /// Short, human-friendly, unambiguous invite code (no I/L/O/0/1), checked for
  /// uniqueness so two coaches never collide on the same code.
  Future<String> _generateUniqueInviteCode({int length = 7}) async {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    String make(int n) =>
        List.generate(n, (_) => chars[random.nextInt(chars.length)]).join();
    for (var attempt = 0; attempt < 6; attempt++) {
      final code = make(length);
      final existing = await _firestore.collection('invites').doc(code).get();
      if (!existing.exists) return code;
    }
    return make(length + 3); // collision-proof fallback
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
