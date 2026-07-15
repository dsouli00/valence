# VALENCE — Current Architecture

Implementation-focused architecture summary for the live codebase.
Last verified against the code: 2026-07-15.

---

## 1) Runtime Layers

```
UI (lib/pages/*, composed from lib/ui/ V-components)
  -> Providers (AuthProvider, ThemeProvider, LocaleProvider)
  -> Services (FirestoreService, FoodAiService, StorageService,
               NotificationService, PushService, PurchaseService)
  -> Firebase (Auth, Firestore, Storage, AI Logic, App Check, Messaging)
```

`main.dart` wires three providers, created once at the root:
- `ThemeProvider` — light/dark override
- `AuthProvider` — session + the app's routing brain
- `LocaleProvider` — language override (null = follow device)

There are no dedicated ClientProvider/CoachProvider classes. There is no
`AuthService` — authentication lives in `AuthProvider`, which is the only
place besides `FirestoreService` that touches Firestore directly (for the
user doc).

Boot order in `main.dart` matters and is load-bearing: Firebase core →
Crashlytics (early, so it catches everything after it) → App Check (must
precede any Firebase AI Logic call) → notifications → FCM background handler
→ PushService → PurchaseService.

---

## 2) Code Structure (Current)

```
lib/
  main.dart
  firebase_options.dart
  config/        plans.dart, revenuecat_config.dart
  l10n/          6 ARB files + generated AppLocalizations (see valence i18n)
  models/        user, daily_log, meal, workout, habit, invite, target_macros
  pages/
    auth/        splash, get_started, role_intro, login, signup, link_coach,
                 client_intake, coach_intake
    client/      home, workouts, progress, settings, log_meal, tabs
    coach/       clients (roster), client_details, library, template_editor,
                 settings, upgrade (paywall), tabs
    shared/      settings_ui, progress_charts_section, language_picker,
                 delete_account
  providers/     auth_provider, theme_provider, locale_provider
  services/      firestore_service, adherence, food_ai_service,
                 storage_service, notification_service, push_service,
                 purchase_service
  theme/         tokens.dart (ValenceTokens), app_theme.dart, typography.dart
  ui/            the V-component design system (see design.md §2/§3)
  utils/         units.dart (canonical-metric conversion), app_info.dart
```

---

## 3) Role-Based UX

### Coach App
- Tabs: Clients, Library, Profile
- roster stream by coach (sorted by risk), client detail review,
  macro target configuration, workout template CRUD + assignment,
  invite-code generation, paywall/plan gating

### Client App
- Tabs: Today, Workouts, Progress, Profile
- meal logging (in-app camera scan / gallery / describe / manual),
  daily habits (water/sleep/weight) + coach-defined custom habits,
  assigned workout execution (per-set reps + weight), progress charts

---

## 4) Data Flow Highlights

### Authentication & routing
1. App boots, initializes Firebase, restores the session via
   `AuthProvider.initializeAuth()` (called once by `SplashScreen`).
2. `AuthProvider` holds the `AppUser` and exposes the `needs*` getters that
   drive routing: `needsCoachLink` → `needsIntake` / `needsCoachIntake` →
   the role's tab shell.
3. The provider has no BuildContext, so it returns typed `AuthErrorCode`s;
   screens localize them via `result.localizedMessage(context.l10n)`.

### Daily tracking
1. Client writes to `daily_logs/{clientId}_{YYYY-MM-DD}` through
   `FirestoreService` (screens never touch Firestore directly).
2. Firestore streams update screens in real time. Streams are CACHED in State
   — never built inline in `build()` above a StreamBuilder.
3. Every write that changes what a client "did" ends with
   `_refreshClientStatus`, which recomputes the adherence verdict and
   denormalizes `status` + `statusSummary` onto the user doc so the coach
   roster renders from a single query.

### Adherence (the core model)
The scoring math is pure and lives in `services/adherence.dart`
(`computeAdherence`), unit-tested in `test/adherence_test.dart`;
`FirestoreService` owns the I/O around it. Rules: rolling 7 completed days
(today never counts against the client), bounded by signup date, status =
the WORST of recency (silent-day gap) and consistency (share of expected
pillars met). Training is only expected on days a workout was assigned.

### Workout assignment & logging
1. Coach assigns a template for a date — the exercises are COPIED into
   `assigned_workouts/{clientId}_{YYYY-MM-DD}`, so later template edits never
   mutate already-assigned days.
2. Client logs per-set reps/weights; set-level writes use transactions
   (rapid taps would otherwise race and lose updates).
3. `isCompleted` is always DERIVED from the full exercise list, so the day's
   done-state can never disagree with the per-set data.

---

## 5) Important Current Constraints

- **Date-keyed doc ids** (`{clientId}_{YYYY-MM-DD}`) give direct gets, no
  queries, and a hard one-per-day guarantee. Build them via
  `dailyLogId`/`workoutAssignmentId`, never by hand.
- **All queries are equality-only** — no composite indexes are required.
  Recent-log filtering sorts in memory on purpose.
- **Weights/heights are canonical metric** (kg/cm) in Firestore; `weightUnit`
  on the user doc is a display preference only (`utils/units.dart`).
- **Meal photos do not persist**: Firebase Storage was never enabled on the
  project (needs Blaze). `StorageService.uploadMealPhoto` throws, the caller
  catches it, and the meal saves with `imageUrl: null`. The AI scan itself is
  unaffected — it sends bytes straight to Gemini. Coaches see no photo.
- **Push sending is external**: the app can't send FCM (no server credential).
  It enqueues to `outbound_notifications`, drained by the free worker in
  `tool/notifier`. The app only RECEIVES.
- **No API key in the app**: Gemini is proxied via Firebase AI Logic, gated by
  App Check (enforcement still OFF/monitoring until launch).
- Any user signed in can READ the `users` collection (deliberate — the roster
  and coach lookups rely on it), but WRITES are owner-only. See
  `firestore.rules` and docs/SECURITY_RULES.md.
- UI is governed by `design.md` (repo root) — it is locked law. Screens compose
  the `lib/ui/` V-components and the `ValenceTokens` theme extension; they
  never invent colors, radii or type.
- Keep product and technical docs implementation-accurate as features evolve.
