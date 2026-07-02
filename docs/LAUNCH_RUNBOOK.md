# Valence — Android Launch Runbook

> **The single source of truth for getting Valence from "code-complete" to "live on Google Play" — and everything optional after.**
> Written 2026-07-02, after the security audit + device smoke test. Every "DONE" below was verified, not assumed.

---

## Where we stand (verified 2026-07-02)

| Area | Status |
|---|---|
| Code (both roles, all features) | ✅ Complete, smoke-tested on device |
| Security audit (rules, config, secrets) | ✅ Done — rules locked **and deployed** |
| `firebase_options.dart` → app.valence ids | ✅ Fixed, old com.example apps deleted |
| Release signing | ✅ Keystore + password backed up off-machine |
| SHA-256 (upload key) in Firebase | ✅ Registered: `C5:80:6A:36:...:11:7B` |
| Old standalone Gemini key | ✅ Deleted (live-verified dead) |
| Notifier (push worker) | ✅ Secret added, workflow on `main`, runs hourly |
| Localization | ✅ 6 languages, 596 keys, auth errors included |
| Icons | ✅ Adaptive + monochrome + notification silhouette |
| Legal docs | ✅ Written (`docs/legal/`) — **not hosted yet** |
| Firebase Storage | ⚠️ NOT enabled (Blaze-gated) → meal photos don't persist. App fine without. |
| Release build | ✅ `flutter build appbundle --release` → 54.6MB signed AAB |

**What's left = this runbook.** Phases 1–5 are the launch path (in order). The Optional track can happen anytime.

---

## Timeline at a glance

```
Day 0        Play signup ($25) + submit ID verification  ← START HERE, the clocks live here
Day 1–3      (verification wait) → create app, upload AAB to closed testing, invite testers
Day 3–17     14-day closed test runs by itself. Meanwhile: legal site, store listing,
             screenshots, Data Safety, App Check enforcement, (optional: Crashlytics, AR/FR)
Day 17       Apply for production access
Day 17–24    Google review (usually ≤7 days)
Day ~24      LAUNCH → switch to coach outreach (the real work)
```

Realistic total: **3–4 weeks from the day you sign up.** Nothing compresses the two waits, so sign up first, polish during.

---

# PHASE 1 — Google Play account + closed test (the clock)

### 1.1 Create the developer account
1. Go to **https://play.google.com/console/signup**
2. Sign in with the Google account that should **own Valence permanently** (transfers are painful — pick deliberately).
3. Choose **"Yourself"** (personal account). Fill legal name + address exactly as on your ID.
4. Pay the **$25** one-time fee (any Visa/MC).
5. Complete **identity verification** — photo of passport or CIN. Takes hours to a few days. **Everything else in this phase waits on it, so do 1.1 before anything.**
6. You do NOT need a D-U-N-S number (that's only for organization accounts).

### 1.2 Create the app
Play Console → **Create app**:
- App name: `Valence` · Default language: `English (United States)` · **App** · **Free**
- Declarations: not primarily for children; accept policies.

> ⚠️ "Free" is **irreversible** — a free app can never become paid. Fine for us: revenue = subscriptions (in-app), not a paid download.

### 1.3 Build + upload to Closed testing
1. Fresh AAB (bump the build number **every** upload — Play rejects reused versionCodes):
   ```bash
   # pubspec.yaml → version: 1.0.0+1  → next upload 1.0.0+2, then +3 ...
   flutter build appbundle --release
   # → build/app/outputs/bundle/release/app-release.aab
   ```
2. Play Console → **Test and release → Testing → Closed testing** → **Create track** (name: `beta`) → **Create new release**.
3. First upload: accept **Play App Signing** (Google holds the distribution key; your .jks stays the *upload* key). Say yes — it's also your disaster recovery if the upload key is ever lost.
4. Upload the AAB, write trivial release notes ("First beta"), save + review + roll out to the track.

### 1.4 ⚠️ Immediately after first upload — Google's signing key → Firebase
Play re-signs your app with **its** key, so Play-delivered installs have a different SHA-256 than your upload key. Play Integrity / App Check will fail without it:
1. Play Console → **Setup → App signing** → copy the **App signing key certificate → SHA-256**.
2. Firebase console → ⚙️ Project settings → General → **Android app app.valence** → **Add fingerprint** → paste → Save.
(Both SHA-256s — upload + app-signing — should now be listed. Upload key's is already there.)

### 1.5 Recruit the 12 testers (rule verified current, 2026)
- Requirement: **≥12 testers opted-in continuously for the last 14 days** at the moment you apply. Personal accounts created after 2023-11-13 only — that's you.
- Track page → **Testers** tab → *Create email list* → add 14–15 Gmail addresses (buffer: if one drops out, the clock doesn't restart as long as ≥12 remain).
- Copy the **opt-in link** from the track page → send to each tester. Each must: open link → **Accept invitation** → install from the Play link.
- Tell them: *keep it installed the whole time*, open it occasionally. (Engagement isn't formally scored but Google reviews "how you tested".)
- **Who:** family, friends, cousins — AND 3–5 real coaches you want as design partners. The tester ask is a perfect first DM: *"I'm launching a coaching app, can you be an early tester? Free forever for you."* Testing = the start of sales.

### 1.6 During the 14 days (parallel work — Phases 2, 3, 4 below)

### 1.7 Apply for production
- After 14 continuous days with ≥12 opted-in: **Dashboard → Apply for access to production**.
- They ask: how you tested, who your users are, what feedback you got and changed. Answer honestly and concretely (e.g. "14-day closed test with 14 testers incl. 4 fitness coaches; fixed a dialog crash and a layout overflow found in testing").
- Review usually **≤7 days**.

### 1.8 Production release
- **Countries:** select **all countries** (free app, no reason to gate; your privacy policy already covers GDPR basics). You can narrow later.
- First rollout: 100% is fine at zero users (staged rollout matters when you have an install base).
- Optional: enable **Managed publishing** so approved changes go live only when you press the button.

---

# PHASE 2 — Legal hosting + landing site (Play hard requirements)

Play requires: a **privacy policy URL** + a **web page where users can request account deletion** (the in-app deletion you built is necessary but NOT sufficient).

### 2.1 Decide the domain
- **Do you own `valence.app`?** If yes → Option B. If no/unsure → Option A now (works today, upgrade later).

### 2.2 Option A — GitHub Pages (free, 15 min)
1. https://github.com/new → name `valence-site` → **Public** (Pages is paid-only on private repos) → Create.
2. **Tell Claude** → the site gets generated + pushed: `index.html` (landing: hero, features, contact), `privacy.html`, `terms.html`, `delete-account.html` (from `docs/legal/*.md`, brand dark+gold).
3. Repo → Settings → **Pages** → Source: *Deploy from a branch* → `main` / root → Save.
4. URLs: `https://dsouli00.github.io/valence-site/privacy.html` etc. → paste into Play (Phase 3).

### 2.3 Option B — custom domain (adds ~15 min)
Same as A, plus: Settings → Pages → **Custom domain** = `valence.app`; at the registrar add A-records `185.199.108.153 / .109 / .110 / .111` + CNAME `www → dsouli00.github.io`. Enforce HTTPS once the cert issues.

---

# PHASE 3 — Store listing + declarations (do during the 14 days)

### 3.1 Assets
| Asset | Spec | How |
|---|---|---|
| App icon | 512×512 PNG, 32-bit | Have it (generated from logo) |
| Feature graphic | 1024×500 JPG/PNG | Claude generates from brand |
| Phone screenshots | 2–8, 9:16, each side 320–3840px | `adb exec-out screencap -p > s1.png` |

**Recommended shots (dark theme, consistent):** client home dashboard · AI meal-scan result · coach roster with status pills · client details (coach view) · workout logging · progress charts. Clean status bar (full battery, no notification icons) — or Claude frames them with device bezels + captions.

### 3.2 Copy (Claude drafts all of it, 6 languages)
- Title ≤30 chars: `Valence — Coaching Client Tracker` (fits: 33 → trim to `Valence: Coach & Client Tracker`)
- Short description ≤80 chars, full ≤4000 — work in the phrases coaches search: *fitness coach app, client tracking, macro tracking, workout plans, check-ins*.

### 3.3 App content forms (Play Console → Policy → App content) — the exact answers
- **Privacy policy:** the Phase-2 URL.
- **App access:** ⚠️ *the classic rejection trap for login-gated apps.* Select "All or some functionality is restricted" → provide **demo credentials**:
  - Create `demo.coach@valence.app`-style throwaway coach + client accounts with stable passwords (do this in-app; note credentials somewhere safe).
  - Instructions for the reviewer: "Coach role: log in with X. Client role: log in with Y. Clients join coaches via invite codes generated in the coach's Settings."
- **Ads:** No ads.
- **Content rating (IARC questionnaire):** category *Utility/Productivity/Health*; no violence/sex/language/gambling/drugs; no user-to-user unmoderated content (no chat — by design); result: **Everyone / PEGI 3**.
- **Target audience:** **18+ only** (avoids the entire Families policy surface; coaching clients are adults).
- **News app:** No. **COVID app:** No. **Government app:** No.
- **Data safety** — declare:
  - *Collected:* Personal info (name, email) · Health & fitness (weight, height, age, sex, activity, nutrition logs) · Photos (meal photos — processed for AI analysis; not stored unless Storage is enabled) · App identifiers (user ID, push token).
  - *NOT collected:* location, contacts, financial info, browsing, analytics/ads identifiers (no analytics SDK!).
  - *Sharing:* none (Firebase/Google = service provider, which Play does not count as "sharing").
  - *Security:* encrypted in transit ✔ · user can request deletion ✔ → **deletion URL** = `delete-account.html` from Phase 2.
  - Coach↔client visibility (coach sees client logs) is the app's stated purpose — covered by the privacy policy.
- **Health apps declaration:** declare Health & Fitness features (fitness tracking / coaching). No medical-device claims — Valence tracks habits, it doesn't diagnose.
- **Financial features:** none.

---

# PHASE 4 — App Check enforcement (the final security switch)

Do this **during** the closed test — the closed-test build IS Play-delivered, which is exactly what Play Integrity needs:

1. Prereq: both SHA-256s in Firebase (1.4 done).
2. Firebase console → **App Check → Apps** → `app.valence` Android → register **Play Integrity** provider (if not already).
3. Install Valence **from the closed-test Play link** on a real device → run the AI meal scan → must work.
4. App Check → **Products** (APIs) tab → **Firebase AI Logic** → **Enforce**.
5. Re-run the meal scan from the Play build immediately. Works → locked (only genuine Play installs + your allowlisted debug devices can call Gemini). Breaks → click Unenforce (instant rollback), investigate.
6. Dev phones keep working via the debug provider token (`8cefcf18-…` allowlisted; a reinstall generates a new token — grab it from `adb logcat | grep -i "app check"` → App Check → Manage debug tokens).
7. Leave Firestore/Storage **unenforced** for now (rules already protect them; enforce later as hardening).

---

# PHASE 5 — Launch day + the real work

**Launch-day checklist:**
1. Production approved → release live → install from the public Play page on your phone.
2. Verify: signup → login → AI scan → log everything → push notification arrives (assign a workout from coach → client phone).
3. Check **Play Console → Vitals** after a few days (crashes/ANRs — your only crash signal until Crashlytics is added).

**Then immediately — the first-20-coaches motion (the launch IS this, not the store listing):**
- List 20 Tunisian/Maghreb online coaches (Instagram fitness coaches with 5–40 clients, visibly using WhatsApp/spreadsheets).
- DM (FR/AR), personal, short: *"Salut [name] — j'ai créé une app qui remplace WhatsApp + Excel pour le suivi de tes clients (repas photo-scannés par IA, habitudes, workouts). Je cherche 3 coachs fondateurs — gratuit à vie pour eux. Ça t'intéresse d'essayer 2 semaines?"*
- Goal: **3 coaches actively using it with real clients.** Their feedback > any feature you could build.
- Track in a simple sheet: name / handle / date DM'd / reply / status.
- Per the locked strategy: NO TikTok, NO forum, NO CI/CD, no feature-building marathons until 3 coaches are active.

---

# OPTIONAL TRACK (anytime, none block launch)

### O1 — Storage / meal-photo persistence (needs Blaze)
Photos currently do NOT persist (never have — Storage was never enabled; upload fails silently and meals save without the image; coach doesn't see photos).
1. Firebase console → bottom-left **Upgrade** → **Blaze** (needs a card; $0 at current volume).
2. During setup, set a **budget alert: $5**.
3. **Build → Storage → Get started** → location `europe-west1` → Done.
4. **Tell Claude** → `firebase deploy --only storage` (owner-only rules are already written in `storage.rules`).
5. Verify: client logs a meal with photo → coach sees the photo in client details. Cost: ~pennies/month.

### O2 — Crashlytics (recommended BEFORE real users; free on Spark; ~20 min, Claude does the code)
Without it, a crash on a coach's phone is invisible. Adds: `firebase_crashlytics` dep + `FlutterError.onError` / `PlatformDispatcher.onError` hooks in `main.dart` + enable the Crashlytics page in console. No analytics needed (Data Safety answer unchanged: crash logs = "App info and performance", update the form when added).

### O3 — Arabic/French native review + RTL pass (you + Claude, ~1 hour)
1. In-app: Settings → Language → **العربية** → walk every screen. Then **Français**.
2. Note anything unnatural (wording, tone, taglines) — screen + current text + better text. Claude applies via `tool/l10n_add.py`.
3. RTL visual bugs (padding stuck on the wrong side, chevrons pointing wrong): screenshot each → Claude converts `EdgeInsets.only(left/right)` → `EdgeInsetsDirectional` per case.

### O4 — Payments activation (RevenueCat) — when the first coach hits the 3-client cap
**✅ Verified 2026-07: Tunisia IS a supported Google Play merchant country (since 2018) — native IAP from a Tunisian account is possible.**
1. Play Console → **Setup → Payments profile** → create merchant account (bank details for payouts, tax info).
2. Play Console → **Monetize → Products → Subscriptions** → create `valence_pro_monthly` ($19) and `valence_studio_monthly` ($39), each with a monthly base plan.
3. https://app.revenuecat.com (free) → new project → add Android app (package `app.valence`) → connect Play service credentials (RevenueCat's guided flow).
4. RevenueCat: **Entitlements** `pro` + `studio` → attach the two products → add both to the default **Offering**.
5. Paste the public SDK key (`goog_…`) into `lib/config/revenuecat_config.dart → androidApiKey` → the paywall goes live automatically (`configured` flips true; everything is already wired).
6. Test with **License testers** (Play Console → Settings → License testing — test cards, no real charges).
7. Later hardening: RevenueCat **webhook** → write `subscriptionTier` server-side + pin the field in `firestore.rules` (currently client-writable = soft gate, fine while free).
8. Revenue < $1M: enroll in Play's **15% service fee** tier (automatic-ish; check Monetize settings).

### O5 — iOS (phase 2; the wildcard — never built once)
1. Apple Developer Program: $99/yr (developer.apple.com; DUNS not needed for individual).
2. Xcode → open `ios/Runner.xcworkspace` → signing team = your Apple account → bundle `app.valence` registers automatically.
3. First `flutter build ios` — expect CocoaPods friction; budget an afternoon.
4. Push: Apple Developer → Keys → create **APNs Auth Key (.p8)** → upload in Firebase console → Project settings → Cloud Messaging → Apple app.
5. App Check: register **App Attest** for the iOS app.
6. App Store Connect: create app → TestFlight (internal) → App Privacy questionnaire (mirror the Play Data Safety answers) → review with the same demo accounts.
7. No Sign-in-with-Apple obligation (email/password only, no third-party login).

### O6 — Housekeeping (grab-bag, whenever)
- Audit the edit-workout dialog's caller-owned `TextEditingController`s in `client_details_screen.dart` (~line 1518) — same pattern that crashed the macros dialog (fixed 2026-07-02, see the StatefulWidget-owns-controllers rule).
- Prune unused `onboardHook*` / `onboardBenefit*` l10n keys (×6 files).
- `withOpacity` → `withValues` sweep (118 info lints; skip `client_home_screen` per the golden rule).
- Social login (Apple/Google) = v1.1: needs packages + Apple Services ID + rework of the EmailAuthProvider reauth/delete flow for passwordless users.
- Periodic manual Firestore export once there's real data (console → Import/Export; scheduled exports need Blaze).

---

# APPENDIX — values & commands you'll need again

```
Firebase project:        valence-d72c4
Package / bundle id:     app.valence
Upload keystore:         ~/valence-upload-keystore.jks   (alias: upload)
Keystore passwords:      android/key.properties          (gitignored; backed up with the .jks)
Upload-key SHA-256:      C5:80:6A:36:05:6C:50:50:3C:2C:9E:E8:76:E2:86:9F:50:DB:71:9B:CB:BA:95:5C:02:02:1C:7B:37:1C:11:7B
App Check debug token:   8cefcf18-78fb-44fd-a21f-f206a72864b8 (dev phone)
Notifier:                GitHub Actions "Valence notifier", hourly, secret FIREBASE_SERVICE_ACCOUNT
Support email:           support@valence.app

# Release build (bump pubspec version: 1.0.0+N first!)
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab

# Deploy security rules
firebase deploy --only firestore:rules --project valence-d72c4
firebase deploy --only storage --project valence-d72c4          # after Storage is enabled

# Screenshots
adb exec-out screencap -p > s1.png

# Keystool (system /usr/bin/keytool is a stub — use Android Studio's)
"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" -list -v \
  -keystore ~/valence-upload-keystore.jks -alias upload
```

**Reference links:** [Play testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465) · [Merchant countries](https://support.google.com/googleplay/android-developer/answer/9306917) · [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469)
