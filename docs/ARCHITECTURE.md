# VALENCE — Architecture Documentation

Complete guide to understanding the Valence codebase architecture, data flow, and how everything connects.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Folder Structure](#folder-structure)
3. [Data Flow](#data-flow)
4. [Provider Architecture](#provider-architecture)
5. [Service Layer](#service-layer)
6. [Model Layer](#model-layer)
7. [Firebase Integration](#firebase-integration)
8. [Authentication Flow](#authentication-flow)
9. [Client Data Flow](#client-data-flow)
10. [Coach Data Flow](#coach-data-flow)

---

## Architecture Overview

Valence uses a **Provider-based state management architecture** with Firebase as the backend.

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                              │
│  (Screens, Widgets, Components)                               │
└──────────────────────┬──────────────────────────────────────┘
                       │ watches
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    Provider Layer                             │
│  (AuthProvider, ClientProvider, CoachProvider, ThemeProvider)│
└──────────────────────┬──────────────────────────────────────┘
                       │ calls
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    Service Layer                             │
│  (AuthService, FirestoreService)                             │
└──────────────────────┬──────────────────────────────────────┘
                       │ reads/writes
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    Firebase                                   │
│  (Firebase Auth, Cloud Firestore)                            │
└─────────────────────────────────────────────────────────────┘
```

---

## Folder Structure

```
lib/
├── main.dart                          # App entry point, Provider setup
├── firebase_options.dart              # Firebase configuration
│
├── core/                              # Core app components
│   ├── constants/
│   │   └── enums.dart                 # UserRole, ClientStatus, SleepQuality
│   └── theme/
│       └── app_theme.dart             # Colors, spacing, themes
│
├── features/                          # Feature-specific screens
│   ├── auth/
│   │   └── screens/
│   │       ├── login_screen.dart
│   │       ├── register_screen.dart
│   │       ├── splash_screen.dart
│   │       ├── onboarding_screen.dart
│   │       ├── coach_onboarding_screen.dart
│   │       └── client_onboarding_screen.dart
│   ├── coach/
│   │   └── screens/
│   │       ├── coach_persistant_tab.dart
│   │       ├── roster_screen.dart
│   │       ├── client_detail_screen.dart
│   │       ├── create_template_screen.dart
│   │       ├── assign_workout_sheet.dart
│   │       ├── library_screen.dart
│   │       └── coach_settings_screen.dart
│   ├── client/
│   │   └── screens/
│   │       ├── client_persistant_tabs.dart
│   │       ├── home_screen.dart
│   │       ├── workout_screen.dart
│   │       ├── progress_screen.dart
│   │       └── client_settings_screen.dart
│   └── shared/
│       └── auth_wrapper.dart           # Auth-based routing
│
├── models/                            # Data models
│   ├── app_user.dart                  # User profile
│   ├── daily_log.dart                 # Daily tracking data
│   ├── meal.dart                      # Meal data
│   ├── assigned_workout.dart          # Workout assignment
│   ├── template.dart                  # Workout template
│   └── target_macros.dart              # Macro targets
│
├── providers/                         # State management
│   ├── auth_provider.dart             # Auth state
│   ├── client_provider.dart           # Client data
│   ├── coach_provider.dart            # Coach data
│   └── theme_provider.dart            # Theme preference
│
└── services/                          # Business logic
    ├── auth_service.dart             # Firebase Auth operations
    └── firestore_service.dart        # Firestore operations
```

---

## Data Flow

### 1. Authentication Flow

```
User opens app
    ↓
main.dart initializes Firebase
    ↓
AuthProvider listens to Firebase Auth
    ↓
AuthWrapper watches AuthProvider
    ↓
If not authenticated → LoginScreen
    ↓
User signs in → AuthService.signIn()
    ↓
Firebase Auth authenticates
    ↓
AuthProvider fetches user profile from Firestore
    ↓
AuthProvider notifies listeners
    ↓
AuthWrapper routes to coach/client tabs
```

### 2. Client Data Flow

```
Client logs meal
    ↓
ClientProvider.addMeal(meal)
    ↓
FirestoreService.addMealToLog()
    ↓
Firestore updates meals array
    ↓
FirestoreService.recomputeMacros()
    ↓
Firestore updates consumedMacros
    ↓
Firestore emits update
    ↓
ClientProvider stream receives update
    ↓
ClientProvider notifies listeners
    ↓
UI rebuilds with new data
```

### 3. Coach Data Flow

```
Coach creates template
    ↓
CoachProvider.saveTemplate(template)
    ↓
FirestoreService.saveTemplate()
    ↓
Firestore creates/updates template document
    ↓
Firestore emits update
    ↓
CoachProvider stream receives update
    ↓
CoachProvider notifies listeners
    ↓
UI rebuilds with new template list
```

---

## Provider Architecture

### Provider Hierarchy

```
MultiProvider
├── AuthProvider (always available)
├── ThemeProvider (always available)
├── ClientProvider (only for clients)
│   └── ChangeNotifierProxyProvider<AuthProvider, ClientProvider>
└── CoachProvider (only for coaches)
    └── ChangeNotifierProxyProvider<AuthProvider, CoachProvider>
```

### Provider Responsibilities

| Provider | Responsibility | Key Methods |
|-----------|---------------|-------------|
| **AuthProvider** | Auth state, user profile | `signIn()`, `register()`, `signOut()` |
| **ClientProvider** | Client data, daily logs, workouts | `addMeal()`, `updateWater()`, `completeWorkout()` |
| **CoachProvider** | Coach data, clients, templates | `saveTemplate()`, `assignWorkout()`, `addCoachNote()` |
| **ThemeProvider** | Theme preference | `toggleTheme()` |

### Provider Initialization

```dart
// In main.dart
ChangeNotifierProxyProvider<AuthProvider, ClientProvider>(
  create: (_) => ClientProvider(),
  update: (_, auth, client) {
    // Only initialize if user is authenticated and is a client
    if (auth.currentUser != null &&
        auth.currentUser!.role == UserRole.client) {
      client!.init(auth.currentUser!);
    }
    return client!;
  },
),
```

---

## Service Layer

### AuthService

Handles Firebase Authentication operations.

**Key Methods:**
- `signIn(email, password)` - Sign in with email/password
- `register(email, password, name, role, inviteCode)` - Register new user
- `signOut()` - Sign out current user
- `forgotPassword(email)` - Send password reset email
- `getUserData(uid)` - Fetch user profile from Firestore

**Data Flow:**
```
AuthProvider → AuthService → Firebase Auth
                          → Firestore (user profile)
```

### FirestoreService

Handles Firestore database operations.

**Key Methods:**
- `getUserById(uid)` - Fetch user by ID
- `getCoachByInviteCode(code)` - Fetch coach by invite code
- `streamClientsByCoach(coachId)` - Stream coach's clients
- `getOrCreateTodayLog(clientId, coachId, date)` - Get or create daily log
- `streamTodayLog(clientId, date)` - Stream today's log
- `addMealToLog(logId, meal)` - Add meal to log
- `saveAssignedWorkout(workout)` - Save workout assignment
- `saveTemplate(template)` - Save template
- `updateStreak(client, today)` - Update client streak
- `refreshClientStatuses(clients)` - Refresh client statuses

**Data Flow:**
```
Provider → FirestoreService → Firestore
```

---

## Model Layer

### AppUser

Represents a user profile in the system.

**Fields:**
- Common: `uid`, `role`, `name`, `email`, `createdAt`
- Client: `coachId`, `currentStreak`, `lastLogDate`, `status`, `currentWeight`, `lastSleepRating`, `targetMacros`
- Coach: `subscriptionTier`, `inviteCode`

**Methods:**
- `fromJson(json, documentId)` - Parse Firestore document
- `toJson()` - Convert to Firestore document
- `copyWith(...)` - Immutable update

### DailyLog

Represents a client's daily tracking data.

**Fields:**
- `logId`, `clientId`, `coachId`, `date`
- `weight`, `waterLiters`, `sleepRating`
- `consumedMacros`, `meals`
- `clientNote`, `coachNote`

**Methods:**
- `fromJson(json, documentId)` - Parse Firestore document
- `toJson()` - Convert to Firestore document
- `copyWith(...)` - Immutable update
- `withRecomputedMacros()` - Recompute macros from meals

### Meal

Represents a single meal logged by a client.

**Fields:**
- `id`, `time`, `type`, `description`, `imageUrl`
- `macros` (calories, protein, carbs, fat)

**Methods:**
- `fromJson(json)` - Parse Firestore document
- `toJson()` - Convert to Firestore document

### AssignedWorkout

Represents a workout assigned to a client.

**Fields:**
- `id`, `clientId`, `coachId`, `date`
- `isRestDay`, `title`, `isCompleted`
- `coachNote`, `clientFeedback`
- `exercises` (with logged sets)

**Methods:**
- `fromJson(json, documentId)` - Parse Firestore document
- `toJson()` - Convert to Firestore document

### Template

Represents a reusable workout or nutrition template.

**Fields:**
- `id`, `coachId`, `title`, `type`, `tags`
- `exercises` (for workout templates)
- `calories`, `protein`, `carbs`, `fat` (for nutrition templates)

**Methods:**
- `fromJson(json, documentId)` - Parse Firestore document
- `toJson()` - Convert to Firestore document

---

## Firebase Integration

### Firebase Auth

Handles authentication (email/password, tokens).

**Used by:**
- AuthService

**Operations:**
- Sign in with email/password
- Create new user
- Sign out
- Send password reset email

### Cloud Firestore

Stores user profiles, daily logs, workouts, templates.

**Collections:**
- `users/{uid}` - User profiles
- `daily_logs/{clientId}_{date}` - Daily tracking data
- `assigned_workouts/{workoutId}` - Workout assignments
- `templates/{templateId}` - Workout templates

**Security Rules:**
- Users can only read/write their own data
- Coaches can read/write their clients' data
- See `docs/SECURITY_RULES.md` for details

---

## Authentication Flow

### 1. App Startup

```
main.dart
    ↓
Initialize Firebase
    ↓
Create Provider tree
    ↓
AuthProvider._init() - Listen to Firebase Auth
    ↓
AuthWrapper watches AuthProvider
    ↓
If loading → SplashScreen
If not authenticated → LoginScreen
If authenticated → Route by role
```

### 2. Sign In

```
User enters email/password
    ↓
LoginScreen → AuthProvider.signIn()
    ↓
AuthProvider → AuthService.signIn()
    ↓
AuthService → Firebase Auth.signInWithEmailAndPassword()
    ↓
Firebase Auth returns User
    ↓
AuthService → Firestore (fetch user profile)
    ↓
AuthService returns AppUser
    ↓
AuthProvider updates currentUser
    ↓
AuthProvider notifies listeners
    ↓
AuthWrapper routes to coach/client tabs
```

### 3. Register (Client)

```
User enters invite code, email, password, name
    ↓
ClientOnboardingScreen → AuthProvider.register()
    ↓
AuthProvider → AuthService.register()
    ↓
AuthService → FirestoreService.getCoachByInviteCode()
    ↓
FirestoreService validates invite code
    ↓
AuthService → Firebase Auth.createUserWithEmailAndPassword()
    ↓
AuthService → Firestore (create user profile)
    ↓
AuthService returns AppUser
    ↓
AuthProvider updates currentUser
    ↓
AuthProvider notifies listeners
    ↓
AuthWrapper routes to client tabs
```

### 4. Register (Coach)

```
User enters email, password, name
    ↓
CoachOnboardingScreen → AuthProvider.register()
    ↓
AuthProvider → AuthService.register()
    ↓
AuthService → Firebase Auth.createUserWithEmailAndPassword()
    ↓
AuthService → Firestore (create user profile)
    ↓
AuthService generates invite code
    ↓
AuthService returns AppUser
    ↓
AuthProvider updates currentUser
    ↓
AuthProvider notifies listeners
    ↓
AuthWrapper routes to coach tabs
```

---

## Client Data Flow

### 1. Daily Log Initialization

```
Client logs in
    ↓
AuthProvider detects client login
    ↓
ClientProvider.init(client)
    ↓
ClientProvider._setupTodayLog()
    ↓
FirestoreService.getOrCreateTodayLog()
    ↓
Firestore checks if log exists
    ↓
If not exists → Firestore creates new log
    ↓
FirestoreService returns (log, isNew)
    ↓
If isNew → FirestoreService.updateStreak()
    ↓
ClientProvider starts streams
    ↓
ClientProvider.streamTodayLog()
    ↓
ClientProvider.streamTodayWorkout()
    ↓
ClientProvider.streamClientLogs()
```

### 2. Add Meal

```
Client logs meal
    ↓
HomeScreen → ClientProvider.addMeal(meal)
    ↓
ClientProvider → FirestoreService.addMealToLog()
    ↓
FirestoreService updates meals array
    ↓
FirestoreService._recomputeMacros()
    ↓
FirestoreService sums macros from all meals
    ↓
FirestoreService updates consumedMacros
    ↓
Firestore emits update
    ↓
ClientProvider stream receives update
    ↓
ClientProvider updates _todayLog
    ↓
ClientProvider notifies listeners
    ↓
UI rebuilds with new data
```

### 3. Complete Workout

```
Client completes workout
    ↓
WorkoutScreen → ClientProvider.completeWorkout(feedback)
    ↓
ClientProvider → FirestoreService.updateWorkoutFields()
    ↓
Firestore updates isCompleted and clientFeedback
    ↓
Firestore emits update
    ↓
ClientProvider stream receives update
    ↓
ClientProvider updates _todayWorkout
    ↓
ClientProvider notifies listeners
    ↓
UI rebuilds with completed status
```

---

## Coach Data Flow

### 1. Coach Initialization

```
Coach logs in
    ↓
AuthProvider detects coach login
    ↓
CoachProvider.init(coach)
    ↓
CoachProvider._startStreams()
    ↓
CoachProvider.streamClientsByCoach()
    ↓
CoachProvider.streamTemplatesByCoach()
    ↓
CoachProvider._refreshStatuses()
    ↓
FirestoreService.refreshClientStatuses()
    ↓
FirestoreService updates client statuses
```

### 2. Create Template

```
Coach creates template
    ↓
CreateTemplateScreen → CoachProvider.saveTemplate(template)
    ↓
CoachProvider → FirestoreService.saveTemplate()
    ↓
FirestoreService creates/updates template document
    ↓
Firestore emits update
    ↓
CoachProvider stream receives update
    ↓
CoachProvider updates _templates
    ↓
CoachProvider notifies listeners
    ↓
UI rebuilds with new template list
```

### 3. Assign Workout

```
Coach assigns workout
    ↓
AssignWorkoutSheet → CoachProvider.assignWorkout(workout)
    ↓
CoachProvider → FirestoreService.saveAssignedWorkout()
    ↓
FirestoreService creates/updates workout document
    ↓
ClientProvider.streamTodayWorkout() receives update
    ↓
ClientProvider updates _todayWorkout
    ↓
ClientProvider notifies listeners
    ↓
Client UI rebuilds with new workout
```

---

## Key Concepts

### 1. Streams

Streams are used for real-time data updates. When data changes in Firestore, the stream emits an update, and the provider notifies listeners, causing the UI to rebuild.

**Example:**
```dart
// In ClientProvider
_logSub = _fs.streamTodayLog(_client!.uid, today).listen((log) {
  _todayLog = log;
  notifyListeners(); // UI rebuilds
});
```

### 2. ChangeNotifierProxyProvider

This provider type allows one provider to depend on another. When the dependency changes, the dependent provider is updated.

**Example:**
```dart
ChangeNotifierProxyProvider<AuthProvider, ClientProvider>(
  create: (_) => ClientProvider(),
  update: (_, auth, client) {
    // Update ClientProvider when AuthProvider changes
    if (auth.currentUser?.role == UserRole.client) {
      client!.init(auth.currentUser!);
    }
    return client!;
  },
),
```

### 3. Immutable Updates

Models use `copyWith` for immutable updates. This ensures that state changes are predictable and easy to track.

**Example:**
```dart
final updated = user.copyWith(currentStreak: 5);
```

### 4. Firestore Document IDs

Document IDs follow specific patterns for easy querying:

- `users/{uid}` - User profile
- `daily_logs/{clientId}_{date}` - Daily log (e.g., "abc123_2026-05-01")
- `assigned_workouts/{workoutId}` - Workout assignment
- `templates/{templateId}` - Workout template

---

## Common Patterns

### 1. Watching a Provider

```dart
final provider = context.watch<ProviderName>();
```

### 2. Reading a Provider Without Rebuilding

```dart
final provider = context.read<ProviderName>();
```

### 3. Calling a Provider Method

```dart
await context.read<ClientProvider>().addMeal(meal);
```

### 4. Showing Loading State

```dart
if (provider.isLoading) {
  return CircularProgressIndicator();
}
```

### 5. Handling Errors

```dart
try {
  await provider.someMethod();
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.toString())),
  );
}
```

---

## Debugging Tips

### 1. Check Provider State

```dart
print('Current user: ${context.read<AuthProvider>().currentUser}');
print('Today log: ${context.read<ClientProvider>().todayLog}');
```

### 2. Check Firestore Data

Use Firebase Console to verify data is being written correctly.

### 3. Check Stream Updates

Add print statements in stream listeners to see when updates are received.

### 4. Check Auth State

```dart
AuthProvider().authStateChanges.listen((user) {
  print('Auth state changed: $user');
});
```

---

*Last updated: May 2026*
