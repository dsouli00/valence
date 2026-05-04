# VALENCE — Firebase Setup Guide

Step-by-step guide to configure all Firebase services required for the Valence platform.

---

## Prerequisites

- Flutter 3.x installed
- Firebase CLI installed: `npm install -g firebase-tools`
- FlutterFire CLI installed: `dart pub global activate flutterfire_cli`
- Node.js 18+ (for Cloud Functions)

---

## Step 1: Create Firebase Project

1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project** → name it `valence-app`
3. Enable Google Analytics (recommended)
4. Wait for project creation

---

## Step 2: Enable Authentication

1. In Firebase console → **Authentication** → **Get started**
2. Enable **Email/Password** provider
3. Enable **Google** provider (requires SHA-1 fingerprint for Android)

### Add Android SHA-1 Fingerprint
```bash
# Debug fingerprint
./gradlew signingReport

# Or via keytool
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

---

## Step 3: Enable Cloud Firestore

1. **Firestore Database** → **Create database**
2. Choose **production mode** (security rules deployed separately)
3. Select nearest region (e.g., `us-east1` or `europe-west1`)
4. Deploy security rules from `docs/SECURITY_RULES.md`

### Create Required Indexes
Go to **Firestore** → **Indexes** → **Add index**:

| Collection | Fields | Query Scope |
|-----------|--------|------------|
| `users` | `inviteCode` ASC | Collection |
| `users` | `coachId` ASC, `role` ASC | Collection |
| `daily_logs` | `clientId` ASC, `date` DESC | Collection |

Or deploy via `firestore.indexes.json`:
```json
{
  "indexes": [
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "coachId", "order": "ASCENDING" },
        { "fieldPath": "role", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "daily_logs",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "clientId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

### Enable Offline Persistence (Flutter)
```dart
// main.dart — before Firebase.initializeApp()
FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
```

---

## Step 4: Enable Firebase Storage

1. **Storage** → **Get started**
2. Choose production mode
3. Deploy storage rules from `docs/SECURITY_RULES.md`

---

## Step 5: Configure FlutterFire

```bash
# From project root
flutterfire configure --project=valence-app
```

This generates `lib/firebase_options.dart` with platform-specific configuration.

Then in `main.dart`:
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

## Step 6: Enable Firebase App Check

### iOS — DeviceCheck
1. Firebase console → **App Check** → iOS app → **DeviceCheck**
2. Upload APNs key from Apple Developer Portal
3. In `AppDelegate.swift`:
```swift
import FirebaseAppCheck

// In application(_:didFinishLaunchingWithOptions:)
let providerFactory = AppCheckDebugProviderFactory()
AppCheck.setAppCheckProviderFactory(providerFactory) // Debug only
```

### Android — Play Integrity
1. Firebase console → **App Check** → Android app → **Play Integrity**
2. No extra code needed if using `firebase_app_check` Flutter package

### Web — reCAPTCHA v3
1. Firebase console → **App Check** → Web app → **reCAPTCHA v3**
2. Register site on [https://www.google.com/recaptcha](https://www.google.com/recaptcha)
3. Add site key to Firebase

### Flutter Initialization
```dart
// main.dart
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
  appleProvider: AppleProvider.deviceCheck,
  webProvider: ReCaptchaV3Provider('your-recaptcha-site-key'),
);
```

---

## Step 7: Enable Firebase Cloud Messaging (FCM)

### iOS Setup
1. In Apple Developer Portal → create APNs authentication key (.p8 file)
2. Firebase console → Project Settings → Cloud Messaging → upload .p8 key
3. Add capability in Xcode: Push Notifications + Background Modes (Remote notifications)
4. In `Info.plist`:
```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

### Android Setup
No additional steps if `google-services.json` is configured.

### Flutter FCM Token Registration
```dart
// Called on login, saves token to Firestore
Future<void> _registerFcmToken(String uid) async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'fcmToken': token});
  }
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'fcmToken': newToken});
  });
}
```

---

## Step 8: Enable Firebase Crashlytics

1. **Crashlytics** → **Get started** → follow setup guide
2. Flutter package: `firebase_crashlytics`

```dart
// main.dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

---

## Step 9: Cloud Functions Setup

```bash
# From project root
firebase init functions
# Choose TypeScript
# Install dependencies: Yes

cd functions
npm install @google/generative-ai firebase-admin firebase-functions
```

### Environment Variables
```bash
# Set Gemini API key (never put in Flutter code)
firebase functions:config:set gemini.key="YOUR_GEMINI_API_KEY"
```

Or use Firebase Secret Manager (recommended for production):
```bash
firebase functions:secrets:set GEMINI_API_KEY
```

### Deploy Functions
```bash
firebase deploy --only functions
```

---

## Step 10: Firestore Daily Backups

1. GCP Console → **Cloud Firestore** → **Backups**
2. Create a backup schedule: daily, retain 7 days
3. Set Cloud Storage bucket: `gs://valence-app-backups`

This ensures data recovery in case of incidents.

---

## Step 11: Firebase Extensions (Optional)

### Trigger Email (for coach onboarding sequence)
1. Firebase console → **Extensions** → search "Trigger Email"
2. Install and configure with SendGrid or SMTP credentials
3. Write to `mail/{docId}` collection to trigger emails

---

## Step 12: Web Hosting

```bash
# Build Flutter web
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

Configure `firebase.json`:
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      { "source": "**", "destination": "/index.html" }
    ]
  }
}
```

---

## Environment Checklist

| Service | Dev | Staging | Prod |
|---------|-----|---------|------|
| Auth (Email/Password) | ✅ | ✅ | ✅ |
| Auth (Google) | ✅ | ✅ | ✅ |
| Firestore | ✅ | ✅ | ✅ |
| Firestore Security Rules | ✅ | ✅ | ✅ |
| Storage | ✅ | ✅ | ✅ |
| Storage Security Rules | ✅ | ✅ | ✅ |
| App Check | ❌ (debug) | ✅ | ✅ |
| FCM | ✅ | ✅ | ✅ |
| Crashlytics | ❌ | ✅ | ✅ |
| Cloud Functions | ✅ (emulator) | ✅ | ✅ |
| Daily Backups | ❌ | ❌ | ✅ |

---

*Last updated: April 2026*
