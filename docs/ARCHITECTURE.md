# VALENCE — Current Architecture

Implementation-focused architecture summary for the live codebase.

---

## 1) Runtime Layers

Valence currently follows this runtime flow:

```
UI (lib/pages/*)
  -> Providers (AuthProvider, ThemeProvider)
  -> Services (AuthService, FirestoreService, FoodAiService, StorageService)
  -> Firebase (Auth, Firestore, Storage)
```

`main.dart` wires only:
- `ThemeProvider`
- `AuthProvider`

There are no dedicated ClientProvider/CoachProvider classes in use.

---

## 2) Code Structure (Current)

```
lib/
  main.dart
  firebase_options.dart
  models/
  pages/
    auth/
    client/
    coach/
    shared/
  providers/
    auth_provider.dart
    theme_provider.dart
  services/
    auth_service.dart
    firestore_service.dart
    food_ai_service.dart
    storage_service.dart
  theme/
```

---

## 3) Role-Based UX

### Coach App
- Tabs: Clients, Library, Profile
- Main capabilities:
  - roster stream by coach
  - client detail review
  - macro target configuration
  - workout template CRUD and assignment
  - invite-link generation

### Client App
- Tabs: Today, Workouts, Progress, Profile
- Main capabilities:
  - meal logging (manual + AI-assisted)
  - daily habits (water/sleep/weight)
  - assigned workout execution
  - progress charts from recent logs

---

## 4) Data Flow Highlights

### Authentication
1. App boots and initializes Firebase.
2. `AuthProvider` tracks auth state and user profile.
3. App routes to coach/client tab shell based on user role.

### Daily Tracking
1. Client writes to daily log document (`daily_logs/{clientId}_{yyyy-mm-dd}`).
2. Firestore streams update screens in real time.
3. Service layer recomputes status/streak-related fields where applicable.

### Workout Assignment & Logging
1. Coach assigns workout for a date.
2. Client logs reps/weights per set.
3. Completion and progress persist in Firestore and feed coach/client views.

---

## 5) Important Current Constraints

- Some older docs previously described planned flows that are not implemented.
- Current architecture is intentionally lightweight and service-driven.
- Keep product and technical docs implementation-accurate as features evolve.
