# Valence — instructions for Claude

## Design work (redesign v2 — ACTIVE)
- Before ANY UI/design work, read **`design.md`** (repo root). It is 🔒 LOCKED law:
  layout/IA stays, skin changes, logic/streams/services untouched. Never invent
  colors, radii, or type outside its tokens.
- Work ONE screen (or one foundation step) at a time, in the §7 phase order. Yassine
  phone-tests and approves before the next unit starts.
- After every approved unit: commit, then tick the §7 checklist in design.md and log
  Yassine's verdict in one line. §7 is the redesign changelog — keep it current.
- Color law: sandy gold = brand identity (rings, highlights, charts, moments);
  ink = structure (button fills, active states). Gold never fills large areas.

## Always
- `flutter analyze` = 0 before handoff. `withValues(alpha:)`, never `withOpacity`.
- Every user-facing string via l10n (`context.l10n`, 6 languages — add keys to ALL
  six .arb files via `tool/l10n_add.py`, then `flutter gen-l10n`).
- New layout code uses `EdgeInsetsDirectional`/`AlignmentDirectional` (Arabic RTL).
- Never build a Stream inline in `build()` above a StreamBuilder — cache in State.
- Sheets/dialogs with TextFields own their controllers (dispose in their own State).
