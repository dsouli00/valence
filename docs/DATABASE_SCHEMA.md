# VALENCE — Firebase Database Schema

Complete Firestore data model for the Valence fitness coaching platform.

---

## Collection: `users/{uid}`

Single document per user (coach or client). Role-specific fields are conditionally populated.

```json
{
  "uid": "string",
  "email": "string",
  "displayName": "string",
  "role": "coach | client",
  "photoUrl": "string | null",
  "createdAt": "timestamp",
  "fcmToken": "string | null",

  // ── Coach-only fields ──────────────────────────────────────
  "inviteCode": "string | null",          // 6-char unique code (indexed)
  "stripeCustomerId": "string | null",
  "subscriptionTier": "free | pro | elite",
  "subscriptionStatus": "active | trialing | canceled",
  "clientCount": "number",                // denormalized counter
  "brandColor": "string | null",          // hex color for Elite branding

  // ── Client-only fields ─────────────────────────────────────
  "coachId": "string | null",

  // Client plan targets (set by coach)
  "targetCalories": "number | null",
  "targetProtein": "number | null",
  "targetCarbs": "number | null",
  "targetFat": "number | null",
  "targetWaterLiters": "number | null",

  // Status (computed daily by Cloud Function)
  "statusColor": "green | yellow | red",
  "statusUpdatedAt": "timestamp",
  "currentStreak": "number",
  "lastLogDate": "string | null",         // "YYYY-MM-DD"

  // Account status
  "accountStatus": "active | archived",
  "tosAcceptedAt": "timestamp | null"
}
```

### Firestore Indexes Required
- `inviteCode` (single-field, ascending) — for invite code lookup
- `coachId` + `role` (composite) — for coach → client queries

---

## Collection: `daily_logs/{clientId}_{YYYY-MM-DD}`

Composite document ID: `{clientId}_{YYYY-MM-DD}`. One document per client per calendar day.

```json
{
  "clientId": "string",
  "coachId": "string",
  "date": "string",           // "YYYY-MM-DD"
  "createdAt": "timestamp",
  "updatedAt": "timestamp",

  // ── Nutrition ──────────────────────────────────────────────
  "meals": [
    {
      "id": "string",
      "name": "string",
      "calories": "number",
      "protein": "number",
      "carbs": "number",
      "fat": "number",
      "imageUrl": "string | null",
      "aiConfidence": "high | medium | low | manual",
      "loggedAt": "timestamp"
    }
  ],
  "totalCalories": "number",
  "totalProtein": "number",
  "totalCarbs": "number",
  "totalFat": "number",

  // ── Body metrics ───────────────────────────────────────────
  "weightKg": "number | null",
  "sleepRating": "number | null",   // 1–5 stars
  "sleepHours": "number | null",
  "waterLiters": "number | null",

  // ── Notes ──────────────────────────────────────────────────
  "clientNote": "string | null",
  "coachNote": "string | null",
  "coachNoteAt": "timestamp | null",

  // ── Workout adherence (denormalized) ──────────────────────
  "workoutCompleted": "boolean",
  "workoutAdherencePct": "number | null"
}
```

---

## Collection: `workout_plans/{planId}`

A structured multi-week workout program assigned by a coach to a client.

```json
{
  "id": "string",
  "coachId": "string",
  "clientId": "string",
  "name": "string",
  "startDate": "string",          // "YYYY-MM-DD"
  "endDate": "string | null",     // "YYYY-MM-DD"
  "isActive": "boolean",
  "createdAt": "timestamp",

  "weeks": [
    {
      "weekNumber": "number",
      "days": [
        {
          "dayOfWeek": "number",   // 1 = Monday … 7 = Sunday
          "label": "string",       // "Push Day", "Legs", "Rest"
          "isRestDay": "boolean",
          "exercises": [
            {
              "id": "string",
              "name": "string",
              "sets": "number",
              "reps": "string",           // "8-12" or "AMRAP"
              "restSeconds": "number",
              "weightKg": "number | null",
              "notes": "string | null",
              "videoUrl": "string | null"
            }
          ]
        }
      ]
    }
  ]
}
```

---

## Collection: `workout_logs/{clientId}_{YYYY-MM-DD}`

Composite document ID: `{clientId}_{YYYY-MM-DD}`. Records what actually happened during a workout session.

```json
{
  "clientId": "string",
  "coachId": "string",
  "planId": "string",
  "date": "string",               // "YYYY-MM-DD"
  "startedAt": "timestamp",
  "completedAt": "timestamp | null",

  "exercises": [
    {
      "exerciseId": "string",
      "name": "string",
      "plannedSets": "number",
      "plannedReps": "string",
      "plannedWeightKg": "number | null",

      "loggedSets": [
        {
          "setNumber": "number",
          "reps": "number",
          "weightKg": "number",
          "completedAt": "timestamp",
          "rpe": "number | null"    // Rate of Perceived Exertion 1–10
        }
      ],
      "skipped": "boolean"
    }
  ],

  "totalVolume": "number",        // sum of (reps × weightKg) across all sets
  "adherencePct": "number",       // % of planned sets completed
  "clientNote": "string | null"
}
```

---

## Collection: `nudges/{nudgeId}`

Tracks every push notification / nudge sent from coach to client.

```json
{
  "id": "string",
  "coachId": "string",
  "clientId": "string",
  "message": "string",
  "template": "string | null",    // "great_job" | "increase_carbs" | "custom"
  "sentAt": "timestamp",
  "deliveredAt": "timestamp | null",
  "openedAt": "timestamp | null"
}
```

---

## Collection: `exercise_library/{exerciseId}`

Global exercises (created by Valence team) and coach-created custom exercises.

```json
{
  "id": "string",
  "name": "string",
  "muscleGroups": ["string"],
  "equipment": ["string"],
  "videoUrl": "string | null",
  "thumbnailUrl": "string | null",
  "isGlobal": "boolean",
  "coachId": "string | null"       // null = global/shared; set = coach-owned
}
```

### Firestore Indexes Required
- `isGlobal` (single-field) — list all global exercises
- `coachId` (single-field) — list coach-specific exercises

---

## Collection: `coach_templates/{templateId}`

Reusable workout plan templates that coaches can apply to any client.

```json
{
  "id": "string",
  "coachId": "string",
  "name": "string",
  "description": "string",
  "createdAt": "timestamp",
  "weeks": [
    // Same structure as workout_plans.weeks
  ]
}
```

---

## Data Relationships Diagram

```
users/{coachId}
  └── clientCount (denormalized)
  └── inviteCode (indexed)

users/{clientId}
  └── coachId → users/{coachId}
  └── targetMacros (set by coach)
  └── statusColor (computed by Cloud Function)

daily_logs/{clientId}_{date}
  └── clientId → users/{clientId}
  └── coachId → users/{coachId}
  └── meals[] (array)

workout_plans/{planId}
  └── clientId → users/{clientId}
  └── coachId → users/{coachId}
  └── weeks[].days[].exercises[]

workout_logs/{clientId}_{date}
  └── clientId → users/{clientId}
  └── planId → workout_plans/{planId}
  └── exercises[].loggedSets[]

nudges/{nudgeId}
  └── coachId → users/{coachId}
  └── clientId → users/{clientId}

exercise_library/{exerciseId}
  └── coachId → users/{coachId} (or null for global)

coach_templates/{templateId}
  └── coachId → users/{coachId}
  └── weeks[] (same as workout_plans)
```

---

## Storage Buckets

```
gs://valence-app.appspot.com/
  meals/{clientId}/{date}/{mealId}.jpg      ← client meal photos
  avatars/{uid}/profile.jpg                 ← user profile photos
```

### Storage Security Rules
```
// File size max 5 MB, images only
allow write: if request.resource.size < 5 * 1024 * 1024
             && request.resource.contentType.matches('image/.*');

// Users can only access their own folder
allow read, write: if request.auth.uid == userId;
```

---

*Last updated: April 2026*
