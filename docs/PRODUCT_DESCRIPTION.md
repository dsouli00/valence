# VALENCE — Product Description (Current App)

This document describes the **actual shipped product behavior** in the current Valence app.
It replaces the earlier concept/first-look product copy.

---

## 1) Product Summary

**Valence** is a role-based coaching app that connects:
- **Coaches** who manage client nutrition/workout adherence
- **Clients** who log daily execution (meals, habits, workouts)

The core value is a single coach-client workflow around:
- daily logging,
- assigned workouts,
- macro targets,
- and adherence visibility.

---

## 2) Who the Product Serves

### Coaches
Coaches who need to:
- track client consistency without spreadsheets,
- assign/edit workouts from reusable templates,
- configure macro targets,
- review client daily logs and progress trends.

### Clients
Clients who need to:
- log meals quickly (manual, AI text, AI photo),
- track water/sleep/weight,
- complete assigned workouts set-by-set,
- receive coach notes and stay accountable.

---

## 3) Current Feature Set (Implemented)

### 3.1 Authentication & Account Setup
- Email/password auth with role-based onboarding (Coach vs Client).
- Client-coach linking via secure invite token/link.
- Coach can generate one-time invite links from Settings.

### 3.2 Client App
- Tabs: **Today**, **Workouts**, **Progress**, **Profile**.
- Today view includes:
  - nutrition dashboard (calories + macros vs targets),
  - meal history with edit/delete,
  - daily habits (water, sleep, weight),
  - coach note display,
  - client note to coach (today only),
  - “Share Daily Win” text copy action.
- Meal logging — entered from a compact creation sheet on Home, which offers
  four paths (`LogMealChooserSheet` → full-screen `LogMealScreen`):
  - **Scan** — a custom in-app camera/viewfinder with a working torch; the
    shot freezes in place and the analyzing moment plays on it,
  - **Gallery** — pick an existing photo,
  - **Describe + AI** — text only,
  - **Manual entry** — type the numbers.
  The result screen offers a portion multiplier (½×–2×) that scales both the
  displayed and saved values, and confirms with a "N kcal left today" toast.
  NOTE: meal photos are analyzed but NOT stored — Firebase Storage is not
  enabled (see docs/ARCHITECTURE.md §5), so coaches see the numbers, not the
  image.
- Workouts:
  - day-based workout view,
  - set-level reps logging,
  - set-level weight logging via direct numeric text fields,
  - progress/completion indicators,
  - past days are read-only (only today is editable).
- Progress:
  - recent trend charts from daily logs.

### 3.3 Coach App
- Tabs: **Clients**, **Library**, **Profile**.
- Client roster:
  - status chips (on track / slipping / at risk / unconfigured),
  - streak and status summary.
- Client details:
  - configure target macros,
  - save coach notes by date,
  - review log/workout/progress sections.
- Workout Library:
  - create, edit, delete templates,
  - assign template workouts to clients and dates,
  - set exercise sets/reps and **weight using text inputs** (not +/- steppers),
  - minor per-assignment exercise adjustments.
- Coach settings:
  - profile name edit,
  - preferences,
  - secure invite link generation.

### 3.4 Adherence Status Engine
- Client status is recalculated from recent behavior using:
  - nutrition logging,
  - habit tracking signals,
  - workout completion.
- Stored on user profile as status + status summary text for coach visibility.

---

## 4) Product Positioning (Current)

Valence is currently positioned as an **MVP execution platform** for coach-client accountability:
- structured daily tracking for clients,
- operational visibility for coaches,
- lightweight but real AI assistance in meal logging.

It is not yet positioned as a full enterprise coaching suite.

---

## 5) What Is Explicitly Out of Scope Right Now

Not currently implemented in the app:
- in-app payments/subscription enforcement,
- coach-client chat/messaging threads,
- automated push nudge orchestration,
- multi-coach team workspaces/white-label,
- marketplace or public program catalog.

These may exist in planning docs, but are not part of the current shipped product behavior.

---

## 6) Product Principles for Ongoing Development

When updating product messaging, keep it:
1. **Implementation-accurate** (no speculative claims as current features)
2. **Coach-client workflow first**
3. **Outcome-oriented** (adherence, consistency, visibility)
4. **MVP-realistic** (clear distinction between “live now” vs “future”)

---

## 7) Short Product Pitch (Current)

Valence helps coaches and clients stay aligned every day.
Clients log meals, habits, and workouts in one app; coaches assign plans, review adherence, and adjust targets based on real data.

---

*Last updated: May 2026*
