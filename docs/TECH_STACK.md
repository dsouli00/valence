# VALENCE — Current Tech Stack

This document reflects the stack actually present in the repository now.

---

## 1) Application Stack

| Layer | Current Choice |
|------|-----------------|
| Frontend | Flutter (single codebase) |
| State management | Provider (`AuthProvider`, `ThemeProvider`) |
| Backend services | Firebase Auth, Cloud Firestore, Firebase Storage |
| UI navigation | `MaterialApp` + in-app tab shells |
| Charting | `fl_chart` |
| AI meal analysis | `google_generative_ai` package (client-side integration currently present) |

---

## 2) Key Runtime Dependencies

From `pubspec.yaml` (current):

- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_storage`
- `provider`
- `flutter_screenutil`
- `persistent_bottom_nav_bar_v2`
- `google_fonts`
- `phosphor_flutter`
- `google_generative_ai`
- `image_picker`
- `flutter_svg`

---

## 3) Development Dependencies

- `flutter_test`
- `flutter_lints`

---

## 4) Observed Implementation Notes

- App is structured around role-based pages for coach/client.
- Firestore service centralizes most data writes/reads.
- Daily logs use deterministic date-keyed document IDs.

---

## 5) Security Note (Action Required)

The current codebase includes a hardcoded Gemini API key in `lib/services/food_ai_service.dart`.

Recommended fix path:
1. Move AI calls to a trusted backend endpoint/Cloud Function.
2. Store API secrets in server-side secret management.
3. Keep mobile/web clients free of long-lived AI keys.
