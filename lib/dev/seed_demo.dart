/// DEV-ONLY demo seeder. Run with:
///
///     flutter run -t lib/dev/seed_demo.dart -d <device>
///
/// It is a separate ENTRYPOINT, not a standalone Dart tool, and that is
/// deliberate: there is no service-account key for the Admin SDK, and App Check
/// enforcement blocks the Firestore REST path. Booting the real app stack
/// (Firebase + App Check) is the only way to write this data — and because the
/// seeder signs in as each identity in turn and writes exactly what the app
/// writes, a successful run is also an end-to-end proof that `firestore.rules`
/// permits everything the product actually does.
///
/// WHY IT EXISTS: the demo video's three strongest beats do not exist on a
/// fresh account. `ClientAnalysisService.minLoggedDays` is 3, so the AI card
/// renders its empty state; `WinSummary.hasAnything` needs two weigh-ins at
/// least a week apart before weight can be the hero; and the share card's month
/// grid is 30 blank cells. This produces a roster with a real history behind it.
///
/// THE DATA IS DELIBERATELY IMPERFECT. Gaps, a client who stopped, a client who
/// recovered. A roster where everyone is perfect looks fabricated, and the share
/// card's whole argument is that the missed days stay visible.
library;

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import '../services/adherence.dart';

// ---------------------------------------------------------------------------
// Tweakables
// ---------------------------------------------------------------------------

// Read from the build environment, NOT hardcoded. These are real accounts on a
// live Firebase project and this repo is public — a hardcoded password is a
// working credential anyone can read. Pass it at run time:
//
//   flutter run -t lib/dev/seed_demo.dart --dart-define=VALENCE_DEMO_PW=...
//
// Empty by default, and the seeder refuses to run without it (see main()).
const String kPassword = String.fromEnvironment('VALENCE_DEMO_PW');
const String kCoachEmail = 'coach.demo@valence.app';
const String kCoachName = 'Karim Mansour';

/// Fixed seed so a re-run produces the same roster — the video can be reshot
/// without the numbers moving underneath it.
final Random _rng = Random(20260930);

/// How far back the history runs. 21 completed days + today.
const int kWindowDays = 22;

// ---------------------------------------------------------------------------
// Client stories — one per roster state the video needs to show
// ---------------------------------------------------------------------------

class _ClientSpec {
  final String email;
  final String name;
  final String sex; // 'male' | 'female'
  final int age;
  final double heightCm;
  final String goal; // 'lose' | 'maintain' | 'gain'
  final double startKg;
  final double endKg;
  final int joinedDaysAgo;

  /// Day offsets (0 = today) with NO log at all. The gaps are the point.
  final Set<int> silentDays;

  /// Skew protein DOWN on weekdays and up at weekends. This is what makes the
  /// AI card produce the exact line the demo script promises — "protein
  /// averages N g under target on weekdays, on target Sat/Sun" — instead of a
  /// generic restatement. Shape the data to the story you are telling.
  final bool weekdayProteinDip;

  /// null = never configured (lands in the roster's Setup bucket).
  final Map<String, int>? macros;

  final List<Map<String, String>> habits;

  const _ClientSpec({
    required this.email,
    required this.name,
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.goal,
    required this.startKg,
    required this.endKg,
    required this.joinedDaysAgo,
    required this.silentDays,
    this.weekdayProteinDip = false,
    this.macros,
    this.habits = const [],
  });

  bool get configured => macros != null;
}

final List<_ClientSpec> _kClients = [
  // 1. THE HERO — the client we open on. Consistent but human: four missed
  //    days, a real weight trend, and the weekday protein dip for the AI to
  //    find. Last five days unbroken, so the streak reads 5.
  _ClientSpec(
    email: 'amina.demo@valence.app',
    name: 'Amina Belhadj',
    sex: 'female',
    age: 29,
    heightCm: 167,
    goal: 'lose',
    startKg: 68.4,
    endKg: 65.6,
    joinedDaysAgo: 24,
    silentDays: {17, 12, 11, 5},
    weekdayProteinDip: true,
    macros: {'calories': 1850, 'protein': 130, 'carbs': 190, 'fat': 55},
    habits: [
      {'id': 'h_steps', 'name': '10k steps', 'icon': 'footprints'},
      {'id': 'h_creatine', 'name': 'Creatine', 'icon': 'pill'},
    ],
  ),

  // 2. AT RISK — logged well, then went silent four days ago. Produces the
  //    breathing Alert dot and "Quiet for 4 days" on the roster.
  _ClientSpec(
    email: 'youssef.demo@valence.app',
    name: 'Youssef Haddad',
    sex: 'male',
    age: 34,
    heightCm: 178,
    goal: 'lose',
    startKg: 92.0,
    endKg: 90.8,
    joinedDaysAgo: 30,
    silentDays: {0, 1, 2, 3, 4},
    macros: {'calories': 2200, 'protein': 165, 'carbs': 210, 'fat': 70},
  ),

  // 3. RECOVERING — a bad first week, then fixed it. This is the client that
  //    gives the AI something worth saying: the slip is RESOLVED, and saying so
  //    is more useful to a coach than flagging it.
  _ClientSpec(
    email: 'marco.demo@valence.app',
    name: 'Marco Ricci',
    sex: 'male',
    age: 41,
    heightCm: 181,
    goal: 'gain',
    startKg: 74.2,
    endKg: 76.1,
    joinedDaysAgo: 28,
    silentDays: {21, 20, 19, 17, 16, 14, 8},
    macros: {'calories': 2900, 'protein': 175, 'carbs': 330, 'fat': 88},
  ),

  // 4. SETUP — joined yesterday, no plan yet. Renders the "Setup →" action so
  //    the roster shows a pending COACH action, not just client states.
  _ClientSpec(
    email: 'sarah.demo@valence.app',
    name: 'Sarah Okafor',
    sex: 'female',
    age: 26,
    heightCm: 171,
    goal: 'maintain',
    startKg: 63.0,
    endKg: 63.0,
    joinedDaysAgo: 1,
    silentDays: {},
    macros: null,
  ),
];

// ---------------------------------------------------------------------------
// Meal bank
// ---------------------------------------------------------------------------

class _MealTpl {
  final String name;
  final int kcal;
  final double p, c, f;
  const _MealTpl(this.name, this.kcal, this.p, this.c, this.f);
}

const _breakfasts = [
  _MealTpl('Oats with banana & whey', 480, 38, 62, 11),
  _MealTpl('Greek yogurt & berries', 320, 28, 34, 8),
  _MealTpl('Eggs on rye toast', 430, 26, 38, 20),
];
const _lunches = [
  _MealTpl('Grilled chicken & rice bowl', 640, 52, 72, 14),
  _MealTpl('Tuna salad wrap', 520, 40, 48, 18),
  _MealTpl('Lentil soup & flatbread', 560, 26, 82, 12),
];
const _dinners = [
  _MealTpl('Salmon, potatoes & greens', 700, 46, 58, 30),
  _MealTpl('Beef stir-fry with noodles', 760, 48, 78, 26),
  _MealTpl('Chicken couscous', 680, 44, 84, 18),
];
const _snacks = [
  _MealTpl('Protein shake', 220, 30, 12, 4),
  _MealTpl('Apple & peanut butter', 260, 8, 28, 14),
  _MealTpl('Cottage cheese & honey', 240, 26, 18, 6),
];

// ---------------------------------------------------------------------------
// Entrypoint
// ---------------------------------------------------------------------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    providerAndroid: AndroidDebugProvider(),
    providerApple: AppleDebugProvider(),
  );
  runApp(const _SeedApp());
}

class _SeedApp extends StatelessWidget {
  const _SeedApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: const _SeedScreen(),
      );
}

class _SeedScreen extends StatefulWidget {
  const _SeedScreen();

  @override
  State<_SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends State<_SeedScreen> {
  final List<String> _log = [];
  final ScrollController _scroll = ScrollController();
  bool _running = false;
  bool _done = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _say(String line) {
    debugPrint('[seed] $line');
    if (!mounted) return;
    setState(() => _log.add(line));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _run() async {
    setState(() {
      _running = true;
      _done = false;
      _log.clear();
    });
    if (kPassword.isEmpty) {
      _say('No demo password. Re-run with:');
      _say('  --dart-define=VALENCE_DEMO_PW=<password>');
      setState(() => _running = false);
      return;
    }
    try {
      await _Seeder(_say).run();
      _say('');
      _say('DONE. Signed in as $kCoachEmail');
      setState(() => _done = true);
    } catch (e, st) {
      _say('');
      _say('FAILED: $e');
      debugPrint('$st');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Valence demo seeder',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Creates 1 coach + ${_kClients.length} clients with $kWindowDays days of history.',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _running ? null : _run,
                child: Text(_running
                    ? 'Seeding…'
                    : _done
                        ? 'Run again'
                        : 'Seed demo data'),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListView.builder(
                    controller: _scroll,
                    itemCount: _log.length,
                    itemBuilder: (_, i) => Text(
                      _log[i],
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 11.5, height: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The seeder
// ---------------------------------------------------------------------------

class _Seeder {
  _Seeder(this.say);
  final void Function(String) say;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late String _coachUid;
  final Map<String, String> _clientUids = {}; // email -> uid

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime _day(int daysAgo) => _today.subtract(Duration(days: daysAgo));

  /// Creates the account, or signs in when it already exists. Returns the uid.
  /// Re-running the seeder must be safe — that is the whole point of doing it
  /// this way rather than assuming a clean project.
  Future<String> _authAs(String email) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: kPassword);
      return cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') rethrow;
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: kPassword);
      return cred.user!.uid;
    }
  }

  Future<void> run() async {
    await _auth.signOut();

    // ---- 1. Coach ----------------------------------------------------
    say('coach: $kCoachEmail');
    _coachUid = await _authAs(kCoachEmail);
    await _db.collection('users').doc(_coachUid).set({
      'role': 'coach',
      'name': kCoachName,
      'email': kCoachEmail,
      'createdAt': Timestamp.fromDate(_day(60)),
      'coachOnboarded': true,
      'specialties': ['weightLoss', 'nutrition', 'strength'],
      'coachExperience': 'threeToFive',
      'rosterBand': 'small',
      'priorTool': 'spreadsheets',
      // MUST be a paid tier, or ClientAnalysisCard renders LOCKED and the
      // strongest beat in the demo video does not exist.
      'subscriptionTier': 'pro',
      'locale': 'en',
      'weightUnit': 'kg',
    }, SetOptions(merge: true));
    say('  uid ${_coachUid.substring(0, 8)}…  tier=pro');

    await _seedTemplates();

    // ---- 2. Clients --------------------------------------------------
    for (final spec in _kClients) {
      await _seedClient(spec);
    }

    // ---- 3. Back to the coach for everything cross-cutting -----------
    // Assignments, notes and the denormalized roster fields all need to be
    // written by the coach, and the status calculation needs the logs AND the
    // workouts to exist first — which is why it is a separate final pass.
    say('');
    say('coach pass: workouts, notes, roster status');
    await _auth.signInWithEmailAndPassword(
        email: kCoachEmail, password: kPassword);

    for (final spec in _kClients) {
      if (!spec.configured) continue;
      await _seedWorkouts(spec);
    }
    await _seedNotes();
    for (final spec in _kClients) {
      await _refreshStatus(spec);
    }
  }

  // -------------------------------------------------------------------
  // Templates
  // -------------------------------------------------------------------

  Future<void> _seedTemplates() async {
    final existing = await _db
        .collection('workout_templates')
        .where('coachId', isEqualTo: _coachUid)
        .get();
    for (final d in existing.docs) {
      await d.reference.delete();
    }

    const templates = {
      'Upper Body — Push': [
        ['Bench press', 4, 8, 60.0],
        ['Overhead press', 3, 10, 35.0],
        ['Incline dumbbell press', 3, 12, 20.0],
        ['Triceps rope pushdown', 3, 15, 25.0],
      ],
      'Lower Body — Strength': [
        ['Back squat', 5, 5, 80.0],
        ['Romanian deadlift', 4, 8, 70.0],
        ['Walking lunges', 3, 12, 16.0],
      ],
      'Full Body — Conditioning': [
        ['Kettlebell swing', 4, 20, 24.0],
        ['Push-ups', 4, 15, null],
        ['Rowing intervals', 5, 1, null],
      ],
    };

    for (final entry in templates.entries) {
      await _db.collection('workout_templates').add({
        'coachId': _coachUid,
        'name': entry.key,
        'exercises': [
          for (final e in entry.value)
            {
              'name': e[0],
              'sets': e[1],
              'reps': e[2],
              'completedSets': 0,
              'loggedRepsBySet': List.filled(e[1] as int, 0),
              'targetWeightKgBySet': List.filled(e[1] as int, e[3]),
              'loggedWeightKgBySet': List.filled(e[1] as int, null),
              'notes': null,
            }
        ],
        'createdAt': Timestamp.fromDate(_day(45)),
      });
    }
    say('  ${templates.length} templates');
  }

  // -------------------------------------------------------------------
  // One client: account, profile, daily logs
  // -------------------------------------------------------------------

  Future<void> _seedClient(_ClientSpec spec) async {
    say('');
    say('client: ${spec.name}');

    // The invite has to be created by the coach and redeemed by the client, so
    // make it now while we still hold the coach session.
    await _auth.signInWithEmailAndPassword(
        email: kCoachEmail, password: kPassword);
    final code = _inviteCode(spec.email);
    final existing = await _db.collection('invites').doc(code).get();
    if (existing.exists) {
      final owner = existing.data()?['coachId'] as String?;
      say('  invite $code exists — coachId '
          '${owner == _coachUid ? "OURS" : "FOREIGN:$owner"}');
    } else {
      say('  invite $code is new');
    }
    await _db.collection('invites').doc(code).set({
      'coachId': _coachUid,
      'token': code,
      'createdAt': Timestamp.fromDate(_day(spec.joinedDaysAgo + 1)),
      'expiresAt': Timestamp.fromDate(_today.add(const Duration(days: 365))),
      'maxUses': 1,
      'currentUses': 1,
      'isActive': false,
      'lastRedeemedAt': Timestamp.fromDate(_day(spec.joinedDaysAgo)),
    });

    final uid = await _authAs(spec.email);
    _clientUids[spec.email] = uid;

    final joined = _day(spec.joinedDaysAgo);
    await _db.collection('users').doc(uid).set({
      'role': 'client',
      'name': spec.name,
      'email': spec.email,
      'createdAt': Timestamp.fromDate(joined),
      'coachId': _coachUid,
      'sex': spec.sex,
      'age': spec.age,
      'heightCm': spec.heightCm,
      'goal': spec.goal,
      'currentWeight': spec.endKg,
      'targetWeight': spec.goal == 'gain' ? spec.endKg + 4 : spec.endKg - 4,
      'activityLevel': 'moderate',
      'weightUnit': 'kg',
      'locale': 'en',
      'status': spec.configured ? 'on_track' : 'unconfigured',
      if (spec.macros != null) 'targetMacros': spec.macros,
      if (spec.habits.isNotEmpty) 'customHabits': spec.habits,
    }, SetOptions(merge: true));

    // Idempotency: clear anything a previous run left behind.
    final old = await _db
        .collection('daily_logs')
        .where('clientId', isEqualTo: uid)
        .get();
    for (final d in old.docs) {
      await d.reference.delete();
    }

    if (!spec.configured) {
      say('  no plan yet — lands in the Setup bucket');
      return;
    }

    var written = 0;
    final span = spec.joinedDaysAgo < kWindowDays ? spec.joinedDaysAgo : kWindowDays - 1;
    for (var d = span; d >= 0; d--) {
      if (spec.silentDays.contains(d)) continue;
      await _writeLog(spec, uid, d);
      written++;
    }
    say('  $written logged days, ${spec.silentDays.length} gaps');
  }

  /// Deterministic 7-char code per client so re-runs reuse the same doc.
  String _inviteCode(String email) {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    var h = 0;
    for (final u in email.codeUnits) {
      h = (h * 31 + u) & 0x7fffffff;
    }
    final out = StringBuffer();
    for (var i = 0; i < 7; i++) {
      out.write(chars[h % chars.length]);
      h ~/= chars.length;
    }
    return out.toString();
  }

  Future<void> _writeLog(_ClientSpec spec, String uid, int daysAgo) async {
    final date = _day(daysAgo);
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    // Meals: breakfast + lunch + dinner, plus a snack most days.
    //
    // `scale` moves the whole meal; `proteinScale` moves ONLY protein. They
    // were one parameter, which is why the weekday protein dip never existed:
    // scaling by 0.72 shrank calories, carbs and fat along with it, so the day
    // was uniformly smaller and there was no protein-specific pattern for the
    // AI to find. It correctly reported none.
    final meals = <Map<String, dynamic>>[];
    void add(_MealTpl t, int hour, int minute, double scale,
        {double proteinScale = 1.0}) {
      meals.add({
        'id': '${date.millisecondsSinceEpoch}_${meals.length}',
        'name': t.name,
        'calories': (t.kcal * scale).round(),
        'protein':
            double.parse((t.p * scale * proteinScale).toStringAsFixed(1)),
        'carbs': double.parse((t.c * scale).toStringAsFixed(1)),
        'fat': double.parse((t.f * scale).toStringAsFixed(1)),
        'imageUrl': null,
        'aiConfidence': _rng.nextInt(10) < 7 ? 'high' : 'medium',
        'loggedAt': Timestamp.fromDate(
            DateTime(date.year, date.month, date.day, hour, minute)),
      });
    }

    // The weekday protein dip — the pattern the AI is meant to find. Applied
    // to protein only, and across EVERY meal: it used to hit breakfast and
    // lunch alone, so even a correct implementation would have left dinner
    // carrying the day back up to target.
    final proteinScale =
        (spec.weekdayProteinDip && !isWeekend) ? 0.72 : 1.0;
    final jitter = 0.9 + _rng.nextDouble() * 0.2;

    add(_breakfasts[_rng.nextInt(_breakfasts.length)], 7, 40, jitter,
        proteinScale: proteinScale);
    add(_lunches[_rng.nextInt(_lunches.length)], 13, 10, jitter,
        proteinScale: proteinScale);
    add(_dinners[_rng.nextInt(_dinners.length)], 20, 5, jitter,
        proteinScale: proteinScale);
    if (_rng.nextInt(10) < 7) {
      add(_snacks[_rng.nextInt(_snacks.length)], 16, 30, jitter,
          proteinScale: proteinScale);
    }

    var kcal = 0;
    var p = 0.0, c = 0.0, f = 0.0;
    for (final m in meals) {
      kcal += m['calories'] as int;
      p += m['protein'] as double;
      c += m['carbs'] as double;
      f += m['fat'] as double;
    }

    // Weight: a weigh-in every ~3 days along the trend, WITH noise.
    //
    // Straight interpolation drew a perfect diagonal on the Progress chart.
    // Real weight wobbles — water, salt, time of day — and a ruler-straight
    // line reads as fabricated, which is the last thing this data should look
    // like on camera. ±0.3kg of deterministic noise: derived from the date so
    // a re-seed reproduces the same wobble rather than a new one.
    double? weight;
    if (daysAgo % 3 == 0) {
      final total = spec.joinedDaysAgo.clamp(1, kWindowDays);
      final t = ((total - daysAgo) / total).clamp(0.0, 1.0);
      final trend = spec.startKg + (spec.endKg - spec.startKg) * t;
      final noise = ((date.day * 37 + date.month * 11) % 13 - 6) / 20.0;
      weight = double.parse((trend + noise).toStringAsFixed(1));
    }

    await _db.collection('daily_logs').doc('${uid}_${dateKeyFor(date)}').set({
      'clientId': uid,
      'coachId': _coachUid,
      'date': Timestamp.fromDate(date),
      'meals': meals,
      'totalCalories': kcal,
      'totalProtein': double.parse(p.toStringAsFixed(1)),
      'totalCarbs': double.parse(c.toStringAsFixed(1)),
      'totalFat': double.parse(f.toStringAsFixed(1)),
      'waterLiters': [1.5, 2.0, 2.5, 3.0][_rng.nextInt(4)],
      'sleepRating': 3 + _rng.nextInt(3),
      'weightKg': ?weight,
      if (spec.habits.isNotEmpty)
        'habitChecks': {
          for (final h in spec.habits) h['id']!: _rng.nextInt(10) < 7,
        },
    });
  }

  // -------------------------------------------------------------------
  // Workouts (written as the coach)
  // -------------------------------------------------------------------

  Future<void> _seedWorkouts(_ClientSpec spec) async {
    final uid = _clientUids[spec.email]!;
    final old = await _db
        .collection('assigned_workouts')
        .where('clientId', isEqualTo: uid)
        .where('coachId', isEqualTo: _coachUid)
        .get();
    for (final d in old.docs) {
      await d.reference.delete();
    }

    const titles = [
      'Upper Body — Push',
      'Lower Body — Strength',
      'Full Body — Conditioning',
    ];
    const plans = [
      [
        ['Bench press', 4, 8, 60.0],
        ['Overhead press', 3, 10, 35.0],
        ['Triceps rope pushdown', 3, 15, 25.0],
      ],
      [
        ['Back squat', 5, 5, 80.0],
        ['Romanian deadlift', 4, 8, 70.0],
        ['Walking lunges', 3, 12, 16.0],
      ],
      [
        ['Kettlebell swing', 4, 20, 24.0],
        ['Push-ups', 4, 15, null],
      ],
    ];

    var assigned = 0, completed = 0;
    final span = spec.joinedDaysAgo < kWindowDays ? spec.joinedDaysAgo : kWindowDays - 1;
    for (var d = span; d >= 0; d--) {
      final date = _day(d);
      // Mon / Wed / Fri programming.
      if (![DateTime.monday, DateTime.wednesday, DateTime.friday]
          .contains(date.weekday)) {
        continue;
      }
      final idx = assigned % 3;
      // Done unless the client was silent that day.
      final done = !spec.silentDays.contains(d) && _rng.nextInt(10) < 8;

      await _db
          .collection('assigned_workouts')
          .doc('${uid}_${dateKeyFor(date)}')
          .set({
        'clientId': uid,
        'coachId': _coachUid,
        'date': Timestamp.fromDate(date),
        'title': titles[idx],
        'exercises': [
          for (final e in plans[idx])
            {
              'name': e[0],
              'sets': e[1],
              'reps': e[2],
              'completedSets': done ? e[1] : 0,
              'loggedRepsBySet':
                  List.filled(e[1] as int, done ? e[2] as int : 0),
              'targetWeightKgBySet': List.filled(e[1] as int, e[3]),
              'loggedWeightKgBySet': List.filled(e[1] as int, done ? e[3] : null),
              'notes': null,
            }
        ],
        'isCompleted': done,
        'completedAt': done ? Timestamp.fromDate(date) : null,
        'updatedAt': Timestamp.fromDate(date),
      });
      assigned++;
      if (done) completed++;
    }
    say('  ${spec.name}: $completed/$assigned sessions done');
  }

  // -------------------------------------------------------------------
  // Notes
  // -------------------------------------------------------------------

  Future<void> _seedNotes() async {
    final amina = _clientUids['amina.demo@valence.app'];
    if (amina == null) return;

    await _db
        .collection('daily_logs')
        .doc('${amina}_${dateKeyFor(_day(2))}')
        .set({
      'clientNote':
          'Travelled for work Tue–Thu, ate out most nights. Back on plan now.',
      'clientNoteAt': Timestamp.fromDate(_day(2)),
    }, SetOptions(merge: true));

    await _db
        .collection('daily_logs')
        .doc('${amina}_${dateKeyFor(_day(1))}')
        .set({
      'coachNote':
          'Saw the trip in your logs — no problem. Protein is the one to watch '
              'on weekdays; aim for a shake with breakfast.',
      'coachNoteAt': Timestamp.fromDate(_day(1)),
    }, SetOptions(merge: true));
    say('  notes: 1 client check-in, 1 coach note');
  }

  // -------------------------------------------------------------------
  // Denormalized roster fields — computed with the REAL engine
  // -------------------------------------------------------------------

  Future<void> _refreshStatus(_ClientSpec spec) async {
    final uid = _clientUids[spec.email]!;
    if (!spec.configured) {
      await _db.collection('users').doc(uid).set({
        'status': 'unconfigured',
        'statusSummary': 'Needs initial configuration from coach.',
      }, SetOptions(merge: true));
      say('  ${spec.name}: unconfigured');
      return;
    }

    // Coach pass: a clientId-only query is not provably safe for a coach, so
    // both of these name the coach too. See FirestoreService._scopedByClient.
    final logs = await _db
        .collection('daily_logs')
        .where('clientId', isEqualTo: uid)
        .where('coachId', isEqualTo: _coachUid)
        .get();
    final workouts = await _db
        .collection('assigned_workouts')
        .where('clientId', isEqualTo: uid)
        .where('coachId', isEqualTo: _coachUid)
        .get();

    String? keyOf(String docId) {
      final i = docId.lastIndexOf('_');
      return i == -1 ? null : docId.substring(i + 1);
    }

    final logsByDay = <String, Map<String, dynamic>>{};
    for (final d in logs.docs) {
      final k = keyOf(d.id);
      if (k != null) logsByDay[k] = d.data();
    }
    final woByDay = <String, Map<String, dynamic>>{};
    for (final d in workouts.docs) {
      final k = keyOf(d.id);
      if (k != null) woByDay[k] = d.data();
    }

    final result = computeAdherence(
      normalizedToday: _today,
      createdAt: _day(spec.joinedDaysAgo),
      logsByDay: logsByDay,
      workoutsByDay: woByDay,
    );

    // Streak + lastLogDate, matching what `_updateStreak` would have produced:
    // find the most recent day carrying a log, then count consecutive logged
    // days back from THERE.
    //
    // Anchoring on the most recent log rather than on today matters for the
    // at-risk client: they last logged 5 days ago, and a walk that gave up at
    // the first empty day would leave lastLogDate null. The roster would then
    // print "No logs yet" instead of "Quiet for 5 days" — right bucket, wrong
    // and much weaker sentence, on the row the video lingers on.
    int? mostRecent;
    for (var d = 0; d < kWindowDays; d++) {
      if (logsByDay.containsKey(dateKeyFor(_day(d)))) {
        mostRecent = d;
        break;
      }
    }
    var streak = 0;
    String? lastLog;
    if (mostRecent != null) {
      lastLog = dateKeyFor(_day(mostRecent));
      for (var d = mostRecent; d < kWindowDays; d++) {
        if (!logsByDay.containsKey(dateKeyFor(_day(d)))) break;
        streak++;
      }
    }

    await _db.collection('users').doc(uid).set({
      'status': result.status,
      'statusSummary': result.summary,
      'currentStreak': streak,
      'lastLogDate': ?lastLog,
    }, SetOptions(merge: true));

    say('  ${spec.name}: ${result.status}, streak $streak — ${result.summary}');
  }
}
