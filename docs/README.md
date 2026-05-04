# VALENCE — Documentation Index

Reference documents for the Valence B2B2C fitness coaching platform.

---

| Document | Description |
|----------|-------------|
| [PRODUCT_DESCRIPTION.md](../PRODUCT_DESCRIPTION.md) | Brand vision, user personas, monetization strategy, launch plan |
| [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) | Complete Firestore data model for all collections |
| [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) | Phase-by-phase development roadmap (Phases 0–9) |
| [SECURITY_RULES.md](SECURITY_RULES.md) | Firestore + Storage security rules with explanations |
| [FIREBASE_SETUP.md](FIREBASE_SETUP.md) | Step-by-step guide to configure all Firebase services |
| [TECH_STACK.md](TECH_STACK.md) | Technology decisions, package list, architecture diagrams |

---

## Quick Reference

### Development Phases

| Phase | Focus | Days |
|-------|-------|------|
| 0 | Project setup, Firebase config | 1–2 |
| 1 | Auth, invite code, onboarding | 3–5 |
| 2 | Client daily logging (food, sleep, water, weight) | 6–12 |
| 3 | Workout plan builder + client execution | 13–20 |
| 4 | Coach dashboard + client detail | 21–28 |
| 5 | Push notifications + nudges | 29–33 |
| 6 | Analytics + progress screens | 34–40 |
| 7 | Monetization (RevenueCat) | 41–50 |
| 8 | Security hardening, error handling | 51–55 |
| 9 | Beta testing, App Store submission | 56–60 |

### Core Collections

| Collection | Key |
|-----------|-----|
| `users/{uid}` | Coach + client profiles |
| `daily_logs/{clientId}_{date}` | Daily nutrition, sleep, water, weight, workout |
| `workout_plans/{planId}` | Multi-week plans assigned to clients |
| `workout_logs/{clientId}_{date}` | What clients actually logged during a workout |
| `nudges/{nudgeId}` | Coach → client push notifications |
| `exercise_library/{exerciseId}` | Global + coach-custom exercises |
| `coach_templates/{templateId}` | Reusable workout plan templates |

### Subscription Tiers

| Tier | Price | Client Limit |
|------|-------|-------------|
| free | $0/mo | 5 clients |
| pro | $49/mo | Unlimited |
| elite | $199/mo | Unlimited + white-label |
