# Rules smoke test

Run this after every `firebase deploy --only firestore:rules`. It takes ~10 minutes
on a device and it exists because **rules are not filters**: a query whose
constraints don't match the rule fails *entirely* rather than returning fewer
rows, so a rules regression shows up as a whole screen going blank, not as
missing data.

You need two accounts: one coach, one client linked to that coach.

## Deploy

```bash
firebase deploy --only firestore:rules --project valence-d72c4
```

Verify first with `--dry-run` — it compiles the file without publishing it.

---

## A · Client account

| # | Do this | Passes when | Breaks if the rule is wrong on |
|---|---|---|---|
| 1 | Cold start, log in | Lands on Today with your name and streak | `users` read (self) |
| 2 | Log a meal | Meal row appears, calorie hero moves | `daily_logs` create + update |
| 3 | Tap water +, set sleep, log weight | All three persist after a pull-to-refresh | `daily_logs` update |
| 4 | Open Workouts on a day the coach assigned one | Workout renders with its sets | `assigned_workouts` read |
| 5 | Log a set | Check fills, progress bar moves | `assigned_workouts` update |
| 6 | Open Progress | Charts render (not the "couldn't load" text) | `daily_logs` **list** — the `where clientId ==` query |
| 7 | Home → Share your progress | Card renders **and shows "Coached by …"** | `users` read (client → their own coach). If the name is missing but the card renders, branch 3 of the users rule is failing |
| 8 | Send a note to coach | Toast confirms | `daily_logs` update |
| 9 | Settings → delete account (use a throwaway) | Completes, returns to Get Started | `daily_logs`/`assigned_workouts` list + delete, storage list |

## B · Coach account

| # | Do this | Passes when | Breaks if the rule is wrong on |
|---|---|---|---|
| 10 | Cold start, log in | Roster lists your clients | `users` **list** — `where coachId == uid AND role == client` |
| 11 | Check a client row | Status pill + the three pillar bars render | `users` read (denormalized fields) |
| 12 | Open a client → Today | Their meals, water, sleep, weight all show | `daily_logs` read (coach branch) |
| 13 | Scroll to their workout | Per-set reps/weights show | `assigned_workouts` read (coach branch) |
| 14 | Save a coach note | Toast confirms | `daily_logs` update + `outbound_notifications` create |
| 15 | Analytics tab | Charts render | `daily_logs` list (coach branch) |
| 16 | Analytics → Analyze with AI | Returns a report | `client_analyses` read/write, and App Check |
| 17 | Plan tab → edit macros | Saves, status leaves Setup | `users` update (coach branch) |
| 18 | Plan tab → manage habits | Saves | `users` update (coach branch) |
| 19 | Library | Templates list | `workout_templates` **list** — newly restricted to `coachId == uid` |
| 20 | Assign a workout, weekly × 2 weeks | Toast reports the day count | `assigned_workouts` create (batch) |
| 21 | Settings → Invite a client → Generate | A 7-char code appears | `invites` create |
| 22 | Roster → long-press a client → Remove | Client disappears | `users` delete + `admin_tasks` create |

## C · The joining flow (needs a third, fresh account)

| # | Do this | Passes when |
|---|---|---|
| 23 | Sign up as a client with the code from step 21 | Account is created and lands on intake, linked to the coach |
| 24 | Try the same code again on another new account | Rejected as invalid — it was single-use |

---

## D · What must now FAIL

These are the whole point of the change. If any of them succeeds, the deploy did
not take. Easiest way to check is the Rules Playground in the Firebase console
(Firestore → Rules → Playground), authenticated as client A's uid.

| Simulate | Expected |
|---|---|
| `get` on `users/{a different client's uid}` | **Denied** |
| `get` on `daily_logs/{otherClientId}_2026-08-27` | **Denied** |
| `list` on `daily_logs` with no `clientId` constraint | **Denied** |
| `list` on `invites` (no constraint) | **Denied** — this is the one that let anyone enumerate every coach's codes |
| `get` on `invites/SOMECODE` | **Allowed** — redemption needs this, it is not a bug |
| `update` on someone else's invite setting `isActive: false` | **Denied** |
| `list` on `workout_templates` with no `coachId` constraint | **Denied** |
| `get` on `client_analyses/{own uid}` as the client | **Denied** — the client must never read what the AI wrote about them |

---

## Known limitation, tracked

A `daily_logs` document carries the `coachId` it was created under. If a client
re-links to a **different** coach, their older logs remain readable only by the
previous coach, so the new coach's Analytics starts empty. That is the
privacy-correct default. The fix belongs in code — backfill `coachId` on the
client's existing logs inside `AuthProvider.linkClientToCoach` — **not** in a
looser rule.
