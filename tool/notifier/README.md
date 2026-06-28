# At-risk notifier (free push, no Blaze)

A scheduled job that pushes a coach when one of their clients has gone silent.
It runs on **GitHub Actions** (free) and talks to **Firestore + FCM** through a
Firebase **service account** using `firebase-admin` — so it needs **no Cloud
Functions and no Blaze plan**.

## How it decides
For each `users` doc with `role == 'client'` and a `coachId`, it checks the
client's `lastLogDate` (written on every log). If that's more than
`AT_RISK_DAYS` (default **3**) old, it sends the coach one push and records
`lastAtRiskNotified` on the client doc. It only sends **once per silence
streak** — it re-arms after the client logs again. Invalid device tokens are
pruned automatically.

## One-time setup
1. **Get a service account key:** Firebase console → Project settings →
   Service accounts → **Generate new private key** → download the JSON.
2. **Add it as a GitHub secret:** your repo → Settings → Secrets and variables →
   Actions → **New repository secret**:
   - Name: `FIREBASE_SERVICE_ACCOUNT`
   - Value: paste the entire JSON file contents.
3. **Commit** `tool/notifier/` and `.github/workflows/at-risk-notifier.yml`
   (already in the repo).
4. Keep the service-account JSON **out of git** — it lives only in the secret.

## Test it
- GitHub → **Actions** tab → "At-risk notifier" → **Run workflow** (manual run).
- Make sure a coach has signed into the app on a device (so their `fcmToken` is
  stored) and has a client whose `lastLogDate` is ≥ 3 days old.

## Tune it
- **Schedule:** edit the `cron` in the workflow (default daily 17:00 UTC).
- **Threshold:** change `AT_RISK_DAYS` in the workflow `env`.

## Run locally (optional)
```bash
cd tool/notifier
npm install
FIREBASE_SERVICE_ACCOUNT="$(cat /path/to/serviceAccount.json)" node notify.js
```

## What it sends
- **At-risk alert** — coach gets pushed when a client goes silent.
- **Event pushes** — the app queues a doc in `outbound_notifications` when a
  coach assigns a workout or leaves a note; this job drains and sends them.

Each push is rendered in the **recipient's language** (their `locale` field on
the user doc, written by the app on sign-in). Add a new language by extending the
`STRINGS` table in `notify.js`.

## Notes
- iOS push also needs an **APNs key** uploaded to Firebase (from a paid Apple
  Developer account); Android works as soon as the app stores a token.
