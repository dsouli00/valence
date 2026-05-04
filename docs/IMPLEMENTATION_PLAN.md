# VALENCE — Implementation Plan

Phase-by-phase development roadmap for the Valence B2B2C fitness coaching platform.

---

## Phase 0 — Project Setup (Days 1–2)

### Goals
Bootstrap the Flutter project, configure Firebase, establish folder structure, and wire up core packages.

### Flutter Project Structure
```
lib/
  core/
    constants/          ← enums, app constants
    theme/              ← AppTheme, AppColors, AppSpacing
    router/             ← GoRouter config + auth guards
    errors/             ← AppException, error boundary
  features/
    auth/
      screens/          ← LoginScreen, RegisterScreen, SplashScreen
    coach/
      dashboard/        ← RosterScreen, coach nav tabs
      client_detail/    ← ClientDetailScreen (tabbed)
      plan_builder/     ← CreateTemplateScreen, AssignWorkoutSheet
      nudge/            ← NudgeScreen, nudge templates
    client/
      home/             ← HomeScreen, daily summary
      food_log/         ← LogMealBottomSheet, macro rings
      workout/          ← WorkoutScreen, set logger
      progress/         ← ProgressScreen, charts
  shared/
    models/             ← AppUser, DailyLog, Meal, AssignedWorkout, Template
    services/           ← AuthService, FirestoreService
    widgets/            ← reusable UI components
  providers/            ← AuthProvider, ClientProvider, CoachProvider, ThemeProvider
  firebase_options.dart
  main.dart
```

### Firebase Services to Enable
- Authentication (Email/Password + Google Sign-In)
- Cloud Firestore
- Firebase Storage
- Cloud Functions
- Firebase Cloud Messaging (FCM)
- Firebase App Check
- Firebase Crashlytics

### Firestore Offline Persistence
```dart
// In main.dart, before runApp
FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
```

### Key Packages
```yaml
dependencies:
  firebase_core: ^4.x
  firebase_auth: ^6.x
  cloud_firestore: ^6.x
  firebase_storage: ^12.x
  firebase_messaging: ^15.x
  firebase_app_check: ^0.x
  firebase_crashlytics: ^4.x
  flutter_screenutil: ^5.x
  google_fonts: ^8.x
  provider: ^6.x
  fl_chart: ^1.x
  image_picker: ^1.x
  persistent_bottom_nav_bar_v2: ^6.x
```

---

## Phase 1 — Auth + Onboarding (Days 3–5)

### Coach Sign-Up Flow
1. Email/password or Google Sign-In
2. Role selection: "I'm a Coach" / "I'm a Client"
3. Profile setup: name, optional photo upload to Firebase Storage
4. Auto-generate 6-char unique invite code stored in `users/{uid}.inviteCode`
5. Invite code display screen with copy + share button

### Client Sign-Up Flow
1. Enter invite code → `FirestoreService.getCoachByInviteCode()` validates it
2. Email/password registration
3. Profile setup: name, weight, height
4. Automatic redirect to client home screen via `AuthWrapper`

### Invite Code Generation
```dart
static String _generateInviteCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I confusion
  final rng = Random.secure();
  return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
}
```

### Auth Guard (AuthWrapper)
- Shows `SplashScreen` while loading
- Routes to `LoginScreen` if unauthenticated
- Routes to `CoachPersistantTabs` if role = coach
- Routes to `ClientPersistantTabs` if role = client

### Deliverables
- [ ] `LoginScreen` — email/password form, forgot password dialog
- [ ] `RegisterScreen` — role selection, invite code field for clients
- [ ] `SplashScreen` — loading indicator
- [ ] `AuthWrapper` — role-based routing
- [ ] `AuthService` — sign in, sign out, register, forgot password
- [ ] `FirestoreService.getCoachByInviteCode()` — invite code lookup

---

## Phase 2 — Client Daily Logging (Days 6–12)

### Food Logging with AI

**AI Stack:** Gemini 1.5 Flash via Firebase Cloud Function proxy (never expose API key in Flutter).

**Cloud Function — `analyzeFood`:**
```javascript
// Accepts: { imageBase64?, description? }
// Returns: { name, calories, protein_g, carbs_g, fat_g, confidence, portion }
```

**Client Flow:**
1. Bottom sheet: "📷 Take Photo" or "✏️ Describe it"
2. Photo path: compress to max 800px → base64 → Cloud Function → AI result card
3. Text path: description string → same Cloud Function
4. Client edits any field → confirms → saves to `daily_logs.meals[]`
5. Image uploaded to Firebase Storage

**Macro Progress Rings:**
- 4 rings: Calories, Protein, Carbs, Fat
- Green ≥ 90% of target, Yellow 60–89%, Red < 60%
- Implemented with `fl_chart` PieChart or custom `CustomPainter`

### Sleep, Water, Weight Logging
- **Sleep:** 5-star rating + optional hours input (bottom sheet)
- **Water:** Tap to add 250 ml increments
- **Weight:** Numeric input in kg (settings toggle for lbs)
- All saved to today's `daily_logs` document via merge writes

### Streak Engine
- On first log of the day: `FirestoreService.updateStreak()` called
- Compares `lastLogDate` to today: consecutive = streak + 1, gap > 1 = reset to 1
- Result written to `users/{uid}.currentStreak` and `lastLogDate`

### Deliverables
- [ ] `HomeScreen` — macro rings, streak badge, log buttons
- [ ] `LogMealBottomSheet` — photo/text input, AI result card, edit + confirm
- [ ] `WeightLogDialog` — weight input
- [ ] Sleep bottom sheet — star rating + hours
- [ ] Water bottom sheet — 250 ml increment buttons
- [ ] `ClientProvider.addMeal()`, `updateWater()`, `updateSleep()`, `updateWeight()`
- [ ] `FirestoreService.addMealToLog()`, `_recomputeMacros()`

---

## Phase 3 — Workout System (Days 13–20)

### Coach — Plan Builder

**Exercise Library:**
- Searchable list, filter by muscle group / equipment
- Pre-seeded with ~100 common exercises from a JSON asset on first launch
- Coach can add custom exercises (stored in `exercise_library` with `coachId`)

**Plan Builder UI:**
- Select number of weeks: 4, 8, or 12
- For each week → tap day → day editor → add exercises
- Per exercise: sets, reps, weight, rest time, notes
- "Copy week 1 to all weeks" button
- Save as Template or assign directly to a client

**Assign to Client:**
- Pick client from roster → set start date → publish
- Creates `workout_plans` document; sets `isActive = true`

### Client — Workout Execution

**Today's Workout Card (Home Screen):**
- Pulls from active `workout_plans` based on current day of week
- Shows exercise count, estimated duration

**Workout Execution Screen:**
- Exercise-by-exercise view
- Previous performance auto-filled from last `workout_logs` entry
- Set logger: rows of [Set #] [Reps] [Weight] [✓]
- Rest timer auto-starts after completing a set (configurable per exercise)
- "Finish Workout" → saves `workout_logs`, updates `daily_logs.workoutCompleted = true`
- Confetti animation on completion

### Deliverables
- [ ] `LibraryScreen` — exercise list, search, filter, add custom
- [ ] `CreateTemplateScreen` — week/day/exercise builder
- [ ] `AssignWorkoutSheet` — pick client, pick start date, publish
- [ ] `WorkoutScreen` — set logger, rest timer, finish flow
- [ ] `ClientProvider.saveWorkoutExercises()`, `completeWorkout()`
- [ ] `FirestoreService.saveAssignedWorkout()`, `streamTodayWorkout()`

---

## Phase 4 — Coach Dashboard (Days 21–28)

### Client Status Computation

**Algorithm (run nightly by Cloud Function or on demand in app):**
```
Score = (workoutAdherence × 40%) + (nutritionAdherence × 30%) + (logStreak × 30%)
green:  score >= 75
yellow: score 40–74
red:    score < 40
```

**Simplified client-side version (`FirestoreService.refreshClientStatuses()`):**
- `on_track` if `lastLogDate == today`
- `slipping` if `lastLogDate == yesterday`
- `at_risk` otherwise

### Dashboard (RosterScreen)
- Grid of client cards (2 columns mobile, 4 columns web)
- Each card: avatar initial, name, status dot, streak, sleep label, weight, "View Details" button
- Summary row: total clients, alert/watch/good counts with colored pulse dots
- Sorted by risk (atRisk → slipping → onTrack) by default
- Pull-to-refresh re-fetches from Firestore

### Client Detail Screen
Tabbed view with 5 tabs:

| Tab | Content |
|-----|---------|
| Overview | Macro progress bars vs targets, sleep, water, 7-day weight sparkline |
| Nutrition | Meal list with images, AI confidence badge, daily totals |
| Workout | Today's workout log — sets/reps/weights completed |
| History | 30-day calendar heatmap (green = logged, red = missed) |
| Plan | Current assigned plan, weekly structure with exercises |

**Coach FAB Actions:**
- ✏️ Edit Macro Targets → saves to `users/{clientId}`
- 💪 Edit Workout Plan → opens plan builder pre-filled
- 🔔 Send Nudge → nudge sheet
- 📝 Add Note → text input → saves to `daily_logs.coachNote`

### Deliverables
- [ ] `RosterScreen` — grid view, summary cards, sort
- [ ] `ClientDetailScreen` — 5-tab layout, FAB menu
- [ ] `CoachProvider.clients`, `atRiskCount`, `slippingCount`, `onTrackCount`
- [ ] `FirestoreService.streamClientsByCoach()`, `refreshClientStatuses()`

---

## Phase 5 — Push Notifications + Nudges (Days 29–33)

### FCM Setup
1. On login: `FirebaseMessaging.instance.getToken()` → saved to `users/{uid}.fcmToken`
2. Token refresh listener: `onTokenRefresh` → update Firestore
3. Foreground messages: shown as local notification banner
4. Background tap: navigates to relevant screen

### Nudge Flow (Coach → Client)
**Cloud Function — `sendNudge`:**
1. Verifies caller is the client's coach
2. Sends FCM push to client's `fcmToken`
3. Logs nudge to `nudges/{nudgeId}`

### Nudge Templates
```
🔥 Great job! Keep it up!
📈 Try increasing your carbs by 30g today
💧 Don't forget to hit your water goal!
💪 You're close to your streak record — don't break it!
[Custom message]
```

### Automated Smart Nudges (Nightly Cloud Function)
- If client hasn't logged in 48h → auto-nudge: "We miss you! Log today to keep your streak 🔥"
- Opt-in per client (coach configures)

### Deliverables
- [ ] FCM token registration on login
- [ ] `NudgeScreen` with template picker + custom input
- [ ] Cloud Function `sendNudge` (TypeScript)
- [ ] Nightly smart nudge Cloud Function

---

## Phase 6 — Analytics + Progress (Days 34–40)

### Client Progress Screen
- **Weight trend:** `fl_chart` LineChart — 30 days
- **Macro adherence:** Bar chart — 7 days (hit vs missed per macro)
- **Streak calendar:** GitHub-style contribution grid
- **Personal bests:** Heaviest lift, longest streak, best macro week

### Coach Analytics
- Per-client: 30-day adherence %, average macros hit, weight trend
- Portfolio view: % green / yellow / red over time
- Churn risk list: clients with declining 2-week trend

### Deliverables
- [ ] `ProgressScreen` (client) — charts, streak calendar, personal bests
- [ ] Coach analytics tab — portfolio heatmap, churn risk
- [ ] `FirestoreService.streamClientLogs()` — 30-day history stream

---

## Phase 7 — Monetization (Days 41–50)

### RevenueCat Integration
```dart
await Purchases.configure(PurchasesConfiguration(apiKey));
final offerings = await Purchases.getOfferings();
```

### Entitlement Tiers
| Tier | Max Clients | Monthly Price |
|------|------------|---------------|
| free | 5 | $0 |
| pro | Unlimited | $49 |
| elite | Unlimited | $199 |

### Feature Gate
- If `clientCount > 5 && tier == 'free'` → show paywall modal
- RevenueCat is the source of truth (not Firestore)

### Webhook → Cloud Function
- RevenueCat subscription change → Cloud Function → updates `users/{uid}.subscriptionTier`

---

## Phase 8 — Security Hardening (Throughout)

See `SECURITY_RULES.md` for Firestore rules.

### Checklist
- [ ] Firebase App Check enabled (DeviceCheck iOS, Play Integrity Android, reCAPTCHA v3 Web)
- [ ] Firestore rules deployed and tested
- [ ] All Cloud Functions check `context.auth` first
- [ ] Zero secrets in Flutter code — all AI/external calls via Cloud Functions
- [ ] Storage rules: max 5 MB, images only
- [ ] Rate limiting on nudge sends (max 10/hour/coach)

---

## Phase 9 — Polish + Launch Prep (Days 51–60)

### Checklist
- [ ] Shimmer loading skeletons on all list screens
- [ ] Beautiful empty states ("No clients yet — share your code!")
- [ ] First-run coach walkthrough overlay
- [ ] Error boundary with Crashlytics integration
- [ ] App icons + splash screen (`flutter_launcher_icons`, `flutter_native_splash`)
- [ ] iOS: TestFlight (50 beta testers)
- [ ] Android: Google Play internal track
- [ ] Web: `firebase deploy --only hosting`
- [ ] Data export (GDPR) — "Export my data" button → Cloud Function → email CSV
- [ ] ToS acceptance timestamp stored in `users/{uid}.tosAcceptedAt`

---

## Development Timeline Summary

| Phase | Focus | Days |
|-------|-------|------|
| 0 | Project setup, Firebase config | 1–2 |
| 1 | Auth, invite code, onboarding | 3–5 |
| 2 | Client daily logging (food, sleep, water, weight) | 6–12 |
| 3 | Workout plan builder + client execution | 13–20 |
| 4 | Coach dashboard + client detail | 21–28 |
| 5 | Push notifications + nudges | 29–33 |
| 6 | Analytics + progress screens | 34–40 |
| 7 | Monetization (RevenueCat) | 41–50 |
| 8 | Security hardening, error handling | 51–55 |
| 9 | Beta testing, App Store submission | 56–60 |

---

*Last updated: April 2026*
