# VALENCE — Firebase Security Rules

Complete Firestore and Storage security rules for the Valence platform.

---

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ================================================================
    // HELPER FUNCTIONS
    // ================================================================

    // Returns true if the authenticated user is the coach of the given clientId
    function isCoachOf(clientId) {
      return get(/databases/$(database)/documents/users/$(clientId))
             .data.coachId == request.auth.uid;
    }

    // Returns true if the authenticated user owns the log document
    // Log ID format: "{clientId}_{YYYY-MM-DD}"
    function isOwnerOfLog(logId) {
      return request.auth.uid == resource.data.clientId;
    }

    // Returns true if the authenticated user is the coach of the log's client
    function isCoachOfLog(logId) {
      return request.auth.uid == resource.data.coachId;
    }

    // Returns true if the incoming data only modifies the coachNote field
    function onlyCoachNoteField(data) {
      return data.keys().hasOnly(['coachNote', 'coachNoteAt']);
    }

    // Returns true if the incoming data only modifies coach-writable client fields
    function onlyCoachClientFields(data) {
      return data.keys().hasOnly([
        'targetCalories', 'targetProtein', 'targetCarbs', 'targetFat',
        'targetWaterLiters', 'statusColor', 'statusUpdatedAt'
      ]);
    }

    // ================================================================
    // USERS
    // ================================================================

    match /users/{uid} {
      // User reads own doc; coach reads client's doc
      allow read: if request.auth != null
                  && (request.auth.uid == uid || isCoachOf(uid));

      // User writes only their own doc
      allow create: if request.auth.uid == uid;

      // Full self-update
      allow update: if request.auth.uid == uid;

      // Coach can update only specific target/status fields for their client
      allow update: if request.auth != null
                    && isCoachOf(uid)
                    && onlyCoachClientFields(request.resource.data);

      // Nobody deletes user documents via client SDK
      allow delete: if false;
    }

    // ================================================================
    // DAILY LOGS
    // ================================================================

    match /daily_logs/{logId} {
      // Owner (client) or coach can read
      allow read: if request.auth != null
                  && (isOwnerOfLog(logId) || isCoachOfLog(logId));

      // Only the client (owner) can create
      allow create: if request.auth != null && isOwnerOfLog(logId);

      // Client can update any field; coach can only update coachNote
      allow update: if request.auth != null
                    && (
                      isOwnerOfLog(logId)
                      || (isCoachOfLog(logId) && onlyCoachNoteField(request.resource.data))
                    );

      allow delete: if false;
    }

    // ================================================================
    // ASSIGNED WORKOUTS
    // ================================================================

    match /assigned_workouts/{workoutId} {
      // Client reads their own workouts; coach reads workouts they assigned
      allow read: if request.auth != null
                  && (
                    request.auth.uid == resource.data.clientId
                    || request.auth.uid == resource.data.coachId
                  );

      // Coach creates and updates workout assignments
      allow create, update: if request.auth != null
                             && request.auth.uid == request.resource.data.coachId;

      // Client can update (log sets, complete workout)
      allow update: if request.auth != null
                    && request.auth.uid == resource.data.clientId;

      allow delete: if request.auth != null
                    && request.auth.uid == resource.data.coachId;
    }

    // ================================================================
    // WORKOUT PLANS
    // ================================================================

    match /workout_plans/{planId} {
      allow read: if request.auth != null
                  && (
                    request.auth.uid == resource.data.clientId
                    || request.auth.uid == resource.data.coachId
                  );

      allow create, update, delete: if request.auth != null
                                    && request.auth.uid == request.resource.data.coachId;
    }

    // ================================================================
    // WORKOUT LOGS
    // ================================================================

    match /workout_logs/{logId} {
      allow read: if request.auth != null
                  && (
                    request.auth.uid == resource.data.clientId
                    || request.auth.uid == resource.data.coachId
                  );

      allow create, update: if request.auth != null
                             && request.auth.uid == request.resource.data.clientId;

      allow delete: if false;
    }

    // ================================================================
    // TEMPLATES (coach-owned)
    // ================================================================

    match /templates/{templateId} {
      // Only the owning coach can read/write their templates
      allow read, write: if request.auth != null
                          && request.auth.uid == resource.data.coachId;

      allow create: if request.auth != null
                    && request.auth.uid == request.resource.data.coachId;
    }

    // ================================================================
    // EXERCISE LIBRARY
    // ================================================================

    match /exercise_library/{exerciseId} {
      // Anyone authenticated can read global exercises
      allow read: if request.auth != null
                  && (resource.data.isGlobal == true
                      || request.auth.uid == resource.data.coachId);

      // Coach can create/update/delete their own exercises
      allow create: if request.auth != null
                    && request.auth.uid == request.resource.data.coachId;

      allow update, delete: if request.auth != null
                             && request.auth.uid == resource.data.coachId;
    }

    // ================================================================
    // NUDGES
    // ================================================================

    match /nudges/{nudgeId} {
      // Only the coach who sent or the client who received can read
      allow read: if request.auth != null
                  && (
                    request.auth.uid == resource.data.coachId
                    || request.auth.uid == resource.data.clientId
                  );

      // Nudges are created by Cloud Functions (server-side) — deny direct client writes
      allow write: if false;
    }

    // ================================================================
    // DEFAULT DENY
    // ================================================================
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## Firebase Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // ── Meal photos ──────────────────────────────────────────────────
    // Path: meals/{clientId}/{date}/{mealId}.jpg
    match /meals/{clientId}/{date}/{mealId} {
      // Only the client can upload their own meal photos
      allow write: if request.auth != null
                   && request.auth.uid == clientId
                   && request.resource.size < 5 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');

      // Client + their coach can read (coach reads via Firestore coachId check)
      allow read: if request.auth != null && request.auth.uid == clientId;
    }

    // ── User avatars ─────────────────────────────────────────────────
    // Path: avatars/{uid}/profile.jpg
    match /avatars/{uid}/{filename} {
      allow write: if request.auth != null
                   && request.auth.uid == uid
                   && request.resource.size < 2 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');

      allow read: if request.auth != null;
    }

    // Default deny
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

---

## Security Principles

### Data Isolation
- Coach A can **never** read another coach's clients
- Clients can **never** read each other's data
- Clients can **never** edit their coach's notes
- All cross-user reads (e.g., coach reading client data) require the `coachId` relationship

### API Key Protection
- **Zero secrets in Flutter code**
- Gemini AI calls go through a Cloud Function proxy
- RevenueCat webhook calls go through Cloud Functions
- FCM push notifications sent server-side via Cloud Functions

### App Check
Enable on all Firebase services:
- **iOS:** DeviceCheck
- **Android:** Play Integrity
- **Web:** reCAPTCHA v3

This blocks API abuse and fake clients from day 1.

### Cloud Function Auth Checks
Every callable Cloud Function must begin with:
```javascript
if (!context.auth) {
  throw new HttpsError('unauthenticated', 'Must be authenticated');
}
```

And ownership checks where applicable:
```javascript
const client = await db.doc(`users/${clientId}`).get();
if (client.data()?.coachId !== context.auth.uid) {
  throw new HttpsError('permission-denied', 'Not your client');
}
```

### Rate Limiting
- Nudge sends: max 10 per hour per coach (enforced in Cloud Function)
- Food AI analysis: max 50 per day per client (enforced in Cloud Function)

### Archived Clients
Archived clients (`users/{uid}.accountStatus == 'archived'`) cannot create new `daily_logs` or `workout_logs` documents. Enforced via Firestore rules:
```javascript
allow create: if request.auth != null
              && isOwnerOfLog(logId)
              && get(/databases/$(database)/documents/users/$(request.auth.uid))
                 .data.accountStatus == 'active';
```

---

*Last updated: April 2026*
