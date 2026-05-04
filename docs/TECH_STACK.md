# VALENCE — Tech Stack Reference

Complete technology decisions and rationale for the Valence fitness coaching platform.

---

## Decision Table

| Layer | Choice | Why |
|-------|--------|-----|
| **Frontend** | Flutter 3.x | Cross-platform iOS / Android / Web from one codebase |
| **State Management** | Provider (ChangeNotifier) | Simple, well-understood, already in use; upgrade to Riverpod at scale |
| **Router** | MaterialApp + Navigator | Works today; migrate to go_router for web deep-link support |
| **Backend** | Firebase (full suite) | Zero infra, scales automatically, real-time Firestore streams |
| **Database** | Cloud Firestore | NoSQL, real-time listeners, offline persistence built in |
| **File Storage** | Firebase Storage | Direct client upload, CDN delivery, security rules |
| **AI Food Analysis** | Gemini 1.5 Flash via Cloud Function | Cheapest accurate vision AI; ~$0.00015/image |
| **Push Notifications** | Firebase Cloud Messaging (FCM) | Free, cross-platform, built into Firebase |
| **Payments** | RevenueCat | Handles App Store + Play Store + Stripe Web in one SDK |
| **Monitoring** | Firebase Crashlytics | Real-time crash reporting before users report |
| **Analytics** | Firebase Analytics | Free, deep integration; add Mixpanel later for funnels |
| **Charts** | fl_chart | Best Flutter charting library, highly customizable |
| **Fonts** | Google Fonts (Poppins + Inter) | Premium look, free, Flutter-native package |
| **Email** | Firebase Extensions — Trigger Email | Free automated onboarding emails, zero infrastructure |
| **Security** | Firebase App Check + Firestore rules | Block API abuse from day 1 |
| **UI Sizing** | flutter_screenutil | Responsive sizes across all screen densities |

---

## Flutter Packages

### Runtime Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^4.5.0
  firebase_auth: ^6.2.0
  cloud_firestore: ^6.1.3
  firebase_storage: ^12.3.7
  firebase_messaging: ^15.x
  firebase_app_check: ^0.x
  firebase_crashlytics: ^4.x

  # UI
  flutter_screenutil: ^5.9.3
  google_fonts: ^8.0.1
  persistent_bottom_nav_bar_v2: ^6.2.0
  fl_chart: ^1.2.0

  # State
  provider: ^6.1.5+1

  # Media
  image_picker: ^1.1.2

  # Payments (Phase 7)
  # purchases_flutter: ^7.x
```

### Dev Dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

### Planned Additions (by phase)

| Package | Phase | Purpose |
|---------|-------|---------|
| `firebase_messaging` | 5 | Push notifications |
| `flutter_local_notifications` | 5 | Foreground notification banners |
| `go_router` | 0-refactor | Web deep links + auth guards |
| `purchases_flutter` | 7 | RevenueCat payments |
| `cached_network_image` | 2 | Efficient meal photo loading |
| `intl` | 2 | Date + number formatting |
| `uuid` | 2 | Unique IDs for meals, sets |
| `connectivity_plus` | 9 | Offline detection |
| `shimmer` | 9 | Loading skeleton animations |

---

## Firebase Architecture

```
Flutter App (iOS / Android / Web)
        │
        ├── Firebase Auth ──── Email / Google Sign-In
        │
        ├── Cloud Firestore ── Real-time data (users, logs, plans)
        │        │
        │        └── Offline persistence (built-in)
        │
        ├── Firebase Storage ── Meal photos, avatars
        │
        ├── Cloud Functions ── Server-side logic
        │        ├── analyzeFood     (Gemini AI proxy)
        │        ├── sendNudge       (FCM push + nudge log)
        │        ├── computeStatus   (nightly scheduled)
        │        └── revenueCatWebhook
        │
        ├── FCM ─────────────── Push notifications to clients
        │
        ├── App Check ──────── Block fake API calls
        │
        └── Crashlytics ─────── Runtime error reporting
```

---

## State Management Pattern

The app uses Provider with ChangeNotifier. Three core providers:

| Provider | Scope | Purpose |
|----------|-------|---------|
| `AuthProvider` | Global | Firebase auth state, current user profile |
| `ClientProvider` | Client-only | Today's log stream, workout stream, 30-day history |
| `CoachProvider` | Coach-only | Client roster stream, status counts |
| `ThemeProvider` | Global | Light / dark mode preference |

### Provider Initialization Pattern
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProxyProvider<AuthProvider, ClientProvider>(
      create: (_) => ClientProvider(),
      update: (_, auth, client) {
        if (auth.currentUser?.role == UserRole.client) {
          client!.init(auth.currentUser!);
        }
        return client!;
      },
    ),
    ChangeNotifierProxyProvider<AuthProvider, CoachProvider>(
      create: (_) => CoachProvider(),
      update: (_, auth, coach) {
        if (auth.currentUser?.role == UserRole.coach) {
          coach!.init(auth.currentUser!);
        }
        return coach!;
      },
    ),
  ],
  child: const ValenceApp(),
)
```

---

## Data Model Architecture

All models follow a consistent pattern:
- `fromJson(Map<String, dynamic> json, String documentId)` — Firestore deserialization
- `toJson()` — Firestore serialization
- `copyWith(...)` — immutable updates

Models:
- `AppUser` — coach or client profile
- `DailyLog` + `MacroData` — daily tracking document
- `Meal` + `MealMacros` — individual meal entries
- `AssignedWorkout` + `WorkoutExercise` + `LoggedSet` — workout assignment and logging
- `Template` — reusable workout plan template
- `TargetMacros` — coach-set macro targets for a client

---

## AI Integration

**Gemini 1.5 Flash** is used for food photo and text analysis.

**Architecture (security-first):**
```
Client App
    │
    └── Cloud Function (analyzeFood)
              │
              └── Gemini API (API key stored in Firebase Secret Manager)
```

The Flutter app never holds the Gemini API key. All AI calls are proxied through a callable Cloud Function that verifies the caller is authenticated.

**Estimated cost:** ~$0.00015 per image analysis. At 1,000 clients logging 3 meals/day = $0.45/day = ~$165/year.

---

## Monetization Stack

**RevenueCat** manages all in-app purchases:
- iOS: App Store subscriptions
- Android: Google Play subscriptions
- Web: Stripe via RevenueCat web billing

**Flow:**
```
Client purchases on App Store / Play Store / Web
    │
    └── RevenueCat webhook
              │
              └── Firebase Cloud Function
                        │
                        └── Updates users/{uid}.subscriptionTier
```

**Tiers:**
| Tier | Price | Client Limit |
|------|-------|-------------|
| free | $0/mo | 5 clients |
| pro | $49/mo | Unlimited |
| elite | $199/mo | Unlimited + white-label |

---

## Folder Structure

```
lib/
  core/
    constants/
      enums.dart            ← UserRole, ClientStatus, SleepQuality
    theme/
      app_theme.dart        ← AppTheme, AppColors, AppSpacing
  features/
    auth/
      screens/
        login_screen.dart
        register_screen.dart
        splash_screen.dart
    client/
      screens/
        client_persistant_tabs.dart
        home_screen.dart
        workout_screen.dart
        progress_screen.dart
        client_settings_screen.dart
      widgets/
        log_meal_bottom_sheet.dart
        weight_log_dialog.dart
    coach/
      screens/
        coach_persistant_tab.dart
        roster_screen.dart
        client_detail_screen.dart
        create_template_screen.dart
        assign_workout_sheet.dart
        library_screen.dart
        coach_settings_screen.dart
    shared/
      auth_wrapper.dart
  models/
    app_user.dart
    daily_log.dart
    meal.dart
    assigned_workout.dart
    template.dart
    target_macros.dart
  providers/
    auth_provider.dart
    client_provider.dart
    coach_provider.dart
    theme_provider.dart
  services/
    auth_service.dart
    firestore_service.dart
  firebase_options.dart
  main.dart
```

---

## Future Considerations

### Riverpod Migration
The current Provider implementation is solid for MVP. When the team grows and code complexity increases, migrate to **Riverpod** for:
- Better code generation (`riverpod_generator`)
- No `BuildContext` dependency in providers
- Simpler async state with `AsyncValue`
- Better testability

### go_router Migration
Migrate from Navigator-based routing to **go_router** when:
- Web deep links are required (e.g., `app.valenceapp.com/coach/clients/abc123`)
- Auth guards need to be centralized
- The app grows to 10+ routes

### freezed + json_serializable
Consider migrating models to **freezed** for:
- Immutable value objects with generated `copyWith`, `==`, `hashCode`
- Automatic `fromJson`/`toJson` via `json_serializable`
- Union types for loading/error/data states

---

*Last updated: April 2026*
