# Valence

**A coaching app that keeps coaches and their clients accountable, day by day.**

Valence is a role-based fitness-coaching platform. Coaches manage their clients'
nutrition and training adherence; clients log daily execution — meals, habits,
workouts, weight — and their coach sees consistency at a glance instead of
chasing spreadsheets.

Built with Flutter and Firebase, localized in six languages (including RTL
Arabic), and monetized with RevenueCat.

---

## What it does

**For coaches**
- A roster that surfaces who needs attention today (on-track / watch / alert / setup)
- Assign and edit workouts from reusable templates
- Configure per-client macro targets
- AI client analysis that reads a client's own logged numbers and surfaces the
  patterns worth a conversation *(paid tier)*

**For clients**
- Log meals in seconds — manual, AI text, or **AI photo scan**
- Track water, sleep, weight, and daily habits
- Follow assigned workouts set by set
- Get coach notes and stay accountable

---

## Tech

| Area | Choice |
|------|--------|
| App | Flutter (Dart), Cupertino-flavoured custom design system |
| Backend | Firebase — Auth, Cloud Firestore, Storage, App Check, Crashlytics, Cloud Messaging |
| AI | Google Gemini via Firebase AI Logic (meal scan + client analysis) |
| Payments | RevenueCat (Free / Pro / Elite tiers) |
| Push (no Blaze) | A scheduled GitHub Actions worker talks to Firestore + FCM via a service account |
| i18n | 6 languages: English, Arabic (RTL), French, Spanish, Portuguese, German |

Security is enforced by Firestore/Storage rules (a document is readable only by
the client it is about and that client's coach) — see
[`firestore.rules`](firestore.rules), [`storage.rules`](storage.rules), and the
two-role smoke test in [`docs/RULES_SMOKE_TEST.md`](docs/RULES_SMOKE_TEST.md).

---

## Running it

```bash
flutter pub get
flutter gen-l10n
flutter run
```

Firebase is already configured for the project's own backend. RevenueCat runs
against its Test Store in debug/profile builds, so the paywall transacts without
any store account (see [`lib/config/revenuecat_config.dart`](lib/config/revenuecat_config.dart)).

To seed demo data for a walkthrough:

```bash
flutter run -t lib/dev/seed_demo.dart --dart-define=VALENCE_DEMO_PW=<password>
```

---

## Documentation

See [`docs/`](docs/) — product description, architecture, database schema,
tech stack, security rules, and the privacy policy / terms.

---

## Design

The full design system — tokens, components, motion, and the screen-by-screen
spec — lives in [`design.md`](design.md).
