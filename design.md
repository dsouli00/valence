# VALENCE DESIGN SYSTEM — design.md

**Version 2.2 · 2026-07-12 · Owner: Yassine · Status: 🔒 LOCKED (changes only with Yassine's explicit sign-off; §7 checklist ticks + verdict notes are the only edits allowed without asking)**

This file is the single source of truth for how Valence looks and feels. It was decided
WITH Yassine across a reference-driven brainstorm (3 batches + Q&A) and supersedes every
previous design decision wherever they conflict. The old "alive premium" language
(gradient rings, glow pills, container-color chips, two-layer shadows) is RETIRED.

---

## HOW TO USE THIS FILE (rules for Claude — read first)

1. **Read this file before touching ANY Valence UI.** Follow it mechanically.
2. **Layout stays, skin changes.** Existing screens keep their information architecture
   and section order (explicitly confirmed by Yassine). You are re-clothing screens,
   not re-arranging them. If you believe a layout itself must change, STOP and ask.
3. **Visual-only migration.** Never touch logic, streams, services, or data flow while
   reskinning. Keep the stream-caching patterns (never build a Stream inline in
   `build()`). Dialogs/sheets with TextFields own their controllers.
4. When this file is silent, resolve by: nearest **Archetype** (§4) → **Hard Rules**
   (§6). Never invent colors, radii, or type sizes outside the tokens.
5. Build screens by composing the **shared primitives** (§3, implemented in `lib/ui/`)
   — never copy-paste styling into screens.
6. Every user-facing string goes through l10n (6 languages, `context.l10n`). All new
   layout code uses `EdgeInsetsDirectional` / `AlignmentDirectional` (Arabic RTL).
7. Definition of done per screen: `flutter analyze` = 0 · light AND dark verified ·
   RTL spot-check · Yassine tests on his phone before the next screen starts.

---

## 0 · NORTH STAR

**"A calm, warm, purely-iOS tool that feels hand-made — nothing cheap."**

The app is designed for iOS sensibilities on both platforms (Yassine's explicit call).
Premium comes from restraint and craft: warm paper surfaces, ink authority, gold used
like jewelry, editorial typography, data as typography, one considered detail per
screen. If a screen looks "designed," remove the last thing you added.

**The seven principles**
1. **Warm paper, not chrome.** Content sits on a warm cream canvas; cards are soft and
   borderless. The screen is never a stack of outlined boxes.
2. **Ink acts, gold accents.** Authority (buttons, active states) is ink. Warmth
   (selection, highlights, charts, moments) is gold. Gold never carries structure.
3. **Color is state or data — never decoration.** Status hues appear only where status
   is the message. Muted data-tints appear only on small glyphs and chart series.
4. **Typography does the work.** Editorial hierarchy, naked numbers, quiet meta text.
   Chips, badges and containers are the exception, not the default.
5. **Two voices:** a grotesk that runs the app, a serif that speaks at human moments.
6. **Motion is earned.** Everything animates once, with purpose, and respects
   Reduce Motion. Only an at-risk alert is allowed to breathe.
7. **Moments vs. tools.** Working screens are flat and calm. Emotional moments
   (onboarding, analyzing, reveal, paywall) get atmosphere. The contrast IS the drama.

---

## 1 · FOUNDATIONS

### 1.1 Color tokens

> **THE COLOR LAW (read this before the table).** Sandy gold `#C6A87C` is **the brand
> color — Valence's identity**. It appears on every screen. But "primary" must not be
> misread: in mechanics, **ink carries structure** (button fills, active segments,
> selected calendar cells) and **gold carries identity** (selection rings + washes,
> highlights, charts, streak, moments). Gold is mid-tone — filled large it goes pale
> and cheap; used as jewelry it is the most premium thing in the app. Coherence rule
> for everything else: **ink = structure · gold = identity · status = state · data
> tints = data. No fifth role, no other colors.**

Both themes ship day one via `AppTheme` (token pairs; no `ColorScheme.fromSeed`
guessing — every semantic token below is explicit). Implementation: a `ValenceTokens`
`ThemeExtension` in `lib/theme/tokens.dart`, plus mapping into `ColorScheme` for
Material widgets. The dark-mode indigo `primary` is DELETED.

| Token | Light ("Day") | Dark ("Night") | Use |
|---|---|---|---|
| `canvas` | `#F4F1E9` | `#14120D` | Scaffold background |
| `surface` | `#FDFCF8` | `#1C1913` | Cards, sheets, tab bar |
| `surfaceSubtle` | `#ECE8DD` | `#262219` | Input fills, inactive segments, skeleton base |
| `ink` | `#1A1814` | `#F1EDE3` | Primary text; primary pill fill |
| `inkSecondary` | `#6E675C` | `#A79F90` | Secondary text, sublines |
| `inkTertiary` | `#A39B8D` | `#6F6858` | Hints, meta, disabled |
| `onInk` | `#F7F4EC` | `#14120D` | Text/icon on primary pill |
| `gold` | `#C6A87C` | `#C6A87C` | Brand accent: fills @ tint alphas, rings, charts |
| `goldDeep` | `#8C6A2E` | `#D4B98F` | Gold TEXT/ICONS (legibility variant; light darkened v2.3 for 4.5:1) |
| `hairline` | `#E3DED2` | `#2B261D` | Separators, allowed rings only |
| `good` | `#4E9160` | `#6FAE7E` | Status: on track |
| `watch` | `#C4922F` | `#D8A64C` | Status: slipping |
| `alert` | `#D0654B` | `#E27E62` | Status: at risk (also destructive) |
| `scrim` | ink @ 40% | black @ 55% | Behind sheets |

**Data tints** (small glyphs, icon circles, chart series, identity avatars ONLY —
never containers, never text): `gold #C6A87C · sage #9BB08C · steel #8FA7BC ·
clay #C08D7C · lilac #A79ABF · teal #7CB0A5`.
Fixed assignments: protein=sage · carbs=gold · fat=clay · water=steel · sleep=lilac ·
weight/streak-flame=gold · identity avatars = name-hashed from all six.

Alpha conventions: tint fill = color @ 12% (light) / 16% (dark) · selected wash =
gold @ 8% · pressed overlay = ink @ 4%. Always `withValues(alpha:)`.

### 1.2 Typography

Families (google_fonts): **Inter Tight** (display/UI grotesk) · **Inter** (body/small)
· **Fraunces** (display serif — "the Voice").

| Style | Family | Size/Height | Weight | Tracking | Use |
|---|---|---|---|---|---|
| `serifDisplay` | Fraunces | 32 / 1.15 | 600 | -0.5 | Onboarding questions, hero greetings, reveal headline |
| `serifTitle` | Fraunces | 24 / 1.2 | 600 | -0.3 | Moment-screen statements |
| `display` | Inter Tight | 40 / 1.0 | 800 | -1.2 | Hero numbers (calories) |
| `title1` | Inter Tight | 26 / 1.15 | 800 | -0.8 | Screen titles |
| `title2` | Inter Tight | 20 / 1.2 | 700 | -0.4 | Section heads ("Recovery") |
| `headline` | Inter Tight | 17 / 1.25 | 700 | -0.2 | Row/card titles |
| `stat` | Inter Tight | 22–28 | 800 | -0.5 | Metric numbers (tabular) |
| `body` | Inter | 15 / 1.45 | 500 | 0 | Paragraphs |
| `subhead` | Inter | 13 / 1.4 | 500 | 0 | Sublines, secondary info |
| `caption` | Inter | 12 / 1.3 | 500 | 0 | Meta, timestamps, units |
| `label` | Inter | 11 / 1.2 | 700 | +0.8, UPPERCASE | Settings-style group headers ONLY |

Rules: serif never below 24px and never for data/rows/buttons. Max weight w800 (no
w900 — calm). ALL numbers that can change use `FontFeature.tabularFigures()`.
Uppercase+tracking exists ONLY in `label`. Section heads are big bold title-case
(`title2`) with an optional quiet `TextAction` on the right — the old sprinkled
tracked-uppercase micro-labels are RETIRED.

### 1.3 Spacing & layout
4pt base. Screen margin **20**. Card padding 18 (standard) / 20 (hero). Card gap 12.
Section gap 28. List row: vertical padding 14, min height 64, separator inset to text
start (≈64). Pinned CTA: bottom safe-area + 16. Scroll bottom padding 32 + tab bar.
`BouncingScrollPhysics` everywhere.

### 1.4 Shape
`card` 24 · `cardSmall` 18 · `sheetTop` 28 · `input` 14 · `pill` 999 · `codeBox` 12 ·
`squircle` 14 (thing-avatars) · people avatars = circles.

### 1.5 Materials & elevation
- **Card**: `surface` fill, **NO border**, ONE shadow: `ink @ 6%, blur 24, y 6`
  (light) / no shadow in dark — tone difference (`surface` vs `canvas`) does the work.
- **Hairlines allowed only for**: row separators inside grouped cards (`hairline`,
  inset), input focus ring (gold 1.5px), selected-option ring (gold 1.5px).
- **Glass capsule** (moment screens only): `BackdropFilter` blur 20 + white @ 55%
  (light) / `#1C1913` @ 45% (dark) + 1px white @ 25% hairline, radius 999.
- **Pressed**: scale 0.98 (120ms) + ink @ 4% overlay. Everything tappable gets it.
- RETIRED: two-layer shadows, colored/gold shadows, gradient card fills, gradient
  rings, glow borders, `alphaBlend` washes.

### 1.6 Iconography
Phosphor stays. Regular = default · Fill = active tab / small solid glyphs · Bold =
chevrons/arrows at 12–14. Sizes: 16 inline · 18 row-leading · 20 buttons · 24 header.
**Tinted icon circle** replaces emoji everywhere: 34–40px circle, data-tint @ 12–16%
fill, tint-colored glyph. **Raw emojis are banned in UI** (Android renders a different
emoji font — breaks the design on the primary launch platform).

### 1.7 Motion (disciplined)
Durations: micro 120 · standard 240 · entrance 420 · fill 550 · count-up 650 (ms).
Curve: `Curves.easeOutCubic`; sheets use default spring.
**The five allowed animations:** ① one-time staggered entrance (fade + 8px rise,
40ms/index, cap 8, never re-triggers on filter/search) ② count-up on dashboard hero
numbers ③ bar/ring fills ④ breathing dot ONLY on at-risk (2200ms, the app's single
looping animation) ⑤ shimmer skeletons. Nothing else moves on its own.
`MediaQuery.disableAnimations` → everything instant/fade.

### 1.8 Haptics
`mediumImpact` primary CTA submits + success confirmations (VCodeBoxes accepted,
plan reveal, workout finished) · `selectionClick` segments/pickers/dial ticks/calendar
· `lightImpact` toggles + row taps that mutate · `heavyImpact` error moments (rejected
invite code, failed validation) — one pulse, never repeated · none for pure navigation.
**Haptics acknowledge USER actions only.** Never fire from passive/stream-driven
changes (a roster status flipping to alert, list re-sorts, data refreshes) — ambient
buzzing is noise. Note: Flutter has no native iOS notification-haptic variants
(success/warning/error); the impacts above approximate them. A haptics plugin may be
added later only if a moment truly earns it.

### 1.9 Atmosphere
`skyGlow`: radial/vertical gold @ 12% → 0 from the top edge. **Allowed only on moment
screens** (§4-D): cover/onboarding, quiz analyzing, plan reveal, paywall, invite-code
success. Working screens sit on flat `canvas`. The cover carousel additionally uses a
dark cinematic canvas (`#14120D`) in BOTH themes.

### 1.10 Accessibility
- **Dynamic Type**: respect system text scale via `MediaQuery.textScaler`, clamped
  app-wide to **0.85–1.3**. `display` / `stat` / `serifDisplay` styles use a reduced
  cap (**max 1.15**) so hero numbers and dense metric rows never collide. All "fixed"
  component heights (pills h52, status pills h24, rows h64) are MIN-heights — they
  grow with text, never clip it. Definition of done adds: verify the screen at max
  text scale.
- **Touch targets ≥ 44×44pt** for every interactive element (HIG). The visual can be
  smaller; the hit area may not — extend with padding + `HitTestBehavior.opaque`.
- **Contrast**: body-size reading text must hold ~4.5:1 on its surface — this is why
  gold TEXT is always `goldDeep` on light. `gold` and `inkTertiary` are never used
  for essential reading text.
- Reduce Motion covered in §1.7. Icon-only controls (VIconCircle, steppers, stars)
  get semantic labels for VoiceOver/TalkBack.

---

## 2 · COMPONENTS

Each ships as a shared widget in `lib/ui/` (prefix `V`). Spec = anatomy · both-theme
colors via tokens · states (default/pressed/disabled/loading where relevant).

**VPillButton.primary** — h52, r999, `ink` fill / `onInk` text (17 w700). Pressed:
scale+6% darken. Disabled: `surfaceSubtle` + `inkTertiary`. Loading: 20px spinner in
`onInk`. THE default action everywhere.
**VPillButton.hero** — primary + trailing 36px circle (`onInk` @ 14%) with 16px arrow.
Max ONE per journey (final commits: "Start tracking", "Enter Valence").
**VPillButton.secondary** — h52, r999, transparent, 1.5px `ink` @ 25% outline, `ink`
text w600.
**VPillButton.gold** — solid `gold` fill + `#1A1814` ink text, flat. RESERVED: at most
one warm hero moment per flow. Never paired with a primary on the same screen.
**VPillButton.destructive** — `alert` @ 12% fill + `alert` text; solid `alert` only
inside confirm sheets.
**VTextAction** — 15 w600 `goldDeep`. "See all", "Skip", "Setup →".
**VIconCircle** — 40px circle, `surface` + card shadow; icon 20 `ink`. Floating
back/menu/overflow chips (replaces AppBar icon rows).
**VMiniPill** — h32, r999, 1px `gold` @ 35% outline, `goldDeep` text 13 w700, optional
14px icon. Row-level actions: "Assign", "+ Invite", "+ New".

**VSegmented** — container `surfaceSubtle` r999 p3; active segment `ink` fill +
`onInk` text w600 (slides 240ms); inactive `inkSecondary`. Used for: Week/Month/Year,
roster filters, client-detail tabs, kg|lb · cm|ft toggles.

**VSearchBar** — h48 r16 `surface` + card shadow; magnifier 18 `inkTertiary`; hint
`inkTertiary`; trailing clear when text. Focus ring: gold 1.5.

**VGroupCard** — the grouped list container: `surface` r24, card shadow, px8/py6.
Optional **VListHeader** row inside: `title2` + count (`stat` 17 `inkSecondary`) +
trailing VMiniPill. Separators: `hairline` inset 64.

**VRow** — leading avatar (VAvatar) · title `headline` · subline `subhead
inkSecondary` · optional third line (quiet data, §VQuietStats) · trailing slot
(VStatusPill / chevron 14 `inkTertiary` / VMiniPill / VTextAction). Pressed tint.
Long-press → context sheet. **Swipe actions** (meals, templates — rows that are user
content): visual language locked NOW even though build timing is phase-2 — flat SOLID
semantic fills (delete = `alert`, edit = `surfaceSubtle` with `ink` glyph), `onInk`
20px glyphs, corners squared during the drag (native-iOS look), and a full destructive
swipe still confirms via sheet when the action is irreversible. Until built, the
context sheet is the baseline.

**VAvatar** — people: circle; things: squircle r14. Identity data-tint @ 16% fill +
tint-colored initials w800. Sizes 40 (row) / 56 (detail hero). No rings, no status
colors on avatars.

**VStatusPill** — h24 r999, status @ 12% fill, 6px solid dot + word 12 w600 in status
color. `alert` variant: dot breathes (§1.7-④). Buckets: Good=`good`, Watch=`watch`,
Alert=`alert`, New=gold, Setup renders as VTextAction "Setup →" instead of a pill.

**VStatColumn** — naked metric: 16px data-tint glyph · number `stat` `ink` · unit/label
`caption` `inkTertiary`. NO container, whitespace-separated. (Macros, meal result,
template stats.)
**VQuietStats** — one-line Text.rich: `label value · label value · label value`
(labels `subhead inkTertiary`, values 13 w700 `ink` tabular). Roster adherence line,
library stats line.
**VHeroMetric** — `caption` label · `display` count-up number + " / target"
`subhead inkTertiary` · h10 r999 bar (`surfaceSubtle` track, `gold` fill 550ms; over
target → `alert`).

**VField** — h52 r14 `surfaceSubtle` fill, no border; label as `caption` above or
inline-left (auth); focus gold ring 1.5; error `alert` ring + caption.
**VCodeBoxes** — invite-code entry: 7 boxes 40×56 r12 `surface` + `hairline`, active
box gold ring, char 20 w800 tabular, auto-advance + paste; success flashes gold @ 12%.
**VRulerDial** — THE numeric input (age/height/weight/target — identical everywhere):
horizontal tick ruler (`inkTertiary` ticks, `gold` center indicator), live `display`
number beneath, VSegmented unit toggle above, `selectionClick` per unit, snap on
release. One crafted dial, zero novelty variants (coherence > novelty — locked lesson).
**VOptionCard** — quiz select: min-h64 r18 `surface` card, leading 38px tinted icon
circle, label `headline`. Selected: gold 1.5 ring + gold @ 8% wash (the ONLY selected
signal). Single-selects auto-advance after 200ms.

**VSheet** — r28 top, `canvas` fill, 36×4 grabber (`inkTertiary` @ 40%), title
`headline`, pinned CTA + safe area. ALL confirms, editors, pickers and destructive
prompts are sheets — `AlertDialog` is retired app-wide. (Rare blocking alerts:
Cupertino-style dialog.) **Sheets containing text fields or expandable content**:
`isScrollControlled: true`, maxHeight 0.92×screen, body in a scroll view, bottom
padding = keyboard `viewInsets` — no fixed Columns (encodes the b727bbb overflow
lesson as law).
**VToast** — floating capsule above tab bar: `ink` @ 92% fill, `onInk` 13 w600, r999,
fade+rise 240ms, 2.4s. Replaces stock SnackBar visuals.

**VChart** — line: `gold` 2.5px stroke, `surface`-filled dots with gold ring, area
gold @ 18% → 0, dashed `hairline` grid, `caption` axes; series colors from data tints
(weight=teal). Range VSegmented above.
**VHealthBar** — roster pulse: h8 r999 stacked segments (`good`/`watch`/`alert` solid,
3px gaps, 550ms fill, NO glow) + legend dots.
**VProgressSegments** — onboarding top bar: h4 segments r999; done+active `gold`,
rest `surfaceSubtle`.

**VTabBar** — iOS-style: translucent `surface` (blur) + top `hairline`; active icon
Fill + label in `goldDeep`/`gold`, inactive `inkTertiary`. No Material indicator.
**VHeader** — in-body editorial header (no AppBar): `title1` (or `serifDisplay` for
greeting screens) + optional `subhead` + VIconCircle back (pushed screens) + trailing
VIconCircle(s). 
**VEmpty** — 72px gold @ 10% flat circle + 32px `goldDeep` glyph, `title2`, `body`
`inkSecondary`, one VPillButton. No gradients, no glow, no borders.
**VSkeleton** — shimmer blocks mirroring the real layout, `surfaceSubtle` base,
1400ms sweep.
**VCallout** — coach-note style: `surface` card, 3px gold r999 accent bar inside-left,
`label`-free; author `caption goldDeep`, body `body` italic.

---

## 3 · IMPLEMENTATION MAP

- `lib/theme/tokens.dart` — `ValenceTokens` ThemeExtension (every §1.1 token, light +
  dark constructors). `lib/theme/app_theme.dart` — builds both `ThemeData`s from
  tokens; maps into `ColorScheme` (`primary=ink`, `secondary=gold`,
  `surface=canvas`, `error=alert`, containers = tint conventions); text theme from
  §1.2; Cupertino page transitions; retires the ElevatedButton gold/onPrimary theme.
- `lib/ui/` — the V-components (§2), one file per component family.
- Fonts via google_fonts: `interTight`, `inter`, `fraunces`.
- `AppColors` stays temporarily as legacy alias during migration; screens must stop
  referencing it as they migrate (tokens only). Status mapping updates to §1.1 hues.
- Old signature components (gradient-ring avatar, gold-glow badge, premium two-layer
  card, status accent strip, container-chip) are DELETED as their screens migrate.

---

## 4 · SCREEN ARCHETYPES

**A · Dashboard** (client home, coach roster): VHeader (greeting = serif) → hero
metric/pulse → sections (`title2` + VTextAction) → VGroupCards/rows. Flat canvas.
**B · List screen** (library, meals-of-day): VHeader → VSearchBar → VGroupCard with
VListHeader + VRows. Primary "new" action = VMiniPill in the list header (never FAB).
**C · Question screen** (intake quiz): VProgressSegments + VIconCircle back + Skip
VTextAction → `serifDisplay` question + `subhead` "why we ask" → VOptionCards or
VRulerDial → pinned VPillButton.primary. Single-selects auto-advance.
**D · Moment screen** (cover, analyzing, reveal, paywall, code-success): atmosphere
allowed, `serifDisplay`/`serifTitle` statement, ≤3 elements on screen, glass capsules
allowed. Everything else in the app is NOT a moment.
**E · Form sheet** (editors, confirms, pickers): VSheet + VFields/steppers + pinned CTA.
**F · Settings** (both roles): `label` group headers (the only uppercase) →
VGroupCards → rows with 30px tinted icon circles, values `subhead`, chevrons /
Cupertino switches. Destructive rows `alert`-colored, confirms via VSheet.

---

## 5 · PER-SCREEN SPECS

Layout/IA of every screen is PRESERVED (Yassine's rule); each list below maps the
existing sections to the new components. Screens keep their current logic untouched.

### Pre-app arc — the three acts (cover=cinema · quiz=warm · auth=quiet)

**5.1 `get_started.dart` — Cover (Moment, dark in both themes).** 2–3 universal
slides, art direction = **product-as-hero** (decided: no photography): dark canvas +
skyGlow + `serifDisplay` statement + the REAL faithful product-mock cards (reuse
`onboarding_carousel.dart` mocks, restyled to this system) floating with a subtle
±4px bob; optional glass feature capsules. Ends in the role split: two VOptionCards
("I'm a coach" / "I'm a client") + VPillButton.primary continue + "Log in"
VTextAction. Language pill top-right stays.
**5.2 Role carousels** (`client/coach_onboarding_screen.dart`): same cinema language;
mock cards rebuilt from the new components; dots; finish → intake.
**5.3 Intake quizzes** (`client_intake_screen.dart`, `coach_intake_screen.dart`):
Archetype C throughout. Numbers = VRulerDial + unit VSegmented (existing kg/lb·cm/ft
logic). Analyzing = Moment (skyGlow + one gold ring fill + one quiet line — the
scan-line/brackets/shimmer pile is retired). Plan reveal = Moment: `serifTitle`
greeting, count-up calories `display`, three VStatColumns, honest timeline line,
VPillButton.hero "Start tracking".
**5.4 Auth** (`login/signup/link_coach`): quietest surfaces. `title1` + `subhead`,
VFields, VPillButton.primary, VTextActions, tiny legal `caption`. Invite code =
**VCodeBoxes** (the join-your-coach ceremony); success = brief Moment flash.
**5.5 `splash_screen.dart`**: logo on `canvas`. Nothing else.

### Client side

**5.6 `client_home_screen.dart` — LAYOUT LOCKED** (his explicit spec: big calories +
bar → macros under → habit cards → meal cards). Mapping: greeting header →
`serifDisplay` "Hi, {name}" + date `caption` + streak as quiet gold flame+number (no
glow pill) + note VIconCircle · calendar strip → 7 quiet cells, selected = `ink` fill
+ `onInk` text, today = gold dot · coach note → VCallout · nutrition → VHeroMetric
(count-up) + 3 **VStatColumns** with mini fill bars (containers retired) · Log meal →
VPillButton.primary full-width · meals → VRows in a VGroupCard (photo squircle 44 when
present, kcal `stat` right, macros as VQuietStats line, confidence = 6px tint dot +
caption; edit/delete via sheet, swipe later) · water/weight/sleep → three `surface`
cards, tinted icon circles (steel/gold/lilac), naked numbers, round `surfaceSubtle`
steppers (44pt) / gold-ring star taps · custom habits → VGroupCard rows, gold check
circles, count as `caption` (no glow pill) · daily win → VTextAction row.
**5.7 `client_workouts_screen.dart`**: header + day strip (same calendar cells) →
hero: workout title `title1` + one gold progress ring/bar → exercise cards →
VGroupCards: set rows tap-to-complete (gold check circle, reps/weight quiet fields),
"finish workout" VPillButton.primary. Rest day → VEmpty.
**5.8 `client_progress_screen.dart`**: VHeader → VChart cards (weight=teal series,
calories=gold) with VSegmented ranges → metric summary as VStatColumns.
(`progress_charts_section.dart` is shared — coach analytics tab inherits.)
**5.9 `log_meal_bottom_sheet.dart`** (3 phases, VSheet): input = camera hero card +
quiet option rows · analyzing = Moment (skyGlow, photo dimmed, ONE gold sweep + one
rotating quiet line) · result = photo squircle, name `headline`, one `subhead`
sentence, 3 VStatColumns (kcal/protein/carbs+fat pattern per current data), "what the
AI saw" as hairline table rows (`subhead` left, value right), confidence as tint
dot+word, Adjust = secondary pill · Log = primary pill.
**5.10 `client_settings_screen.dart`** + **5.14 coach settings** + `settings_ui.dart`:
Archetype F rebuild of the shared primitives (SettingsGroup→VGroupCard,
IconBox→tinted circle, GoldButton→VPillButton, confirms→VSheet, Cupertino switches).
Delete-account stays low-prominence `alert` text row.

### Coach side

**5.11 `clients_screen.dart` — Roster (structure stays: header → pulse → search →
filters → list).** Header: logo chip + `serifDisplay` greeting · **Roster Pulse KEPT,
restyled**: `surface` card (no gold wash/gradient), "N clients" `title2`, VHealthBar,
"N need you →" VTextAction in `alert`, legend dots quiet · VSearchBar · filters →
VSegmented (All/Alert/Watch/Good, + New/Setup chips only when non-empty) · list →
VGroupCard + VListHeader (count + VMiniPill "+ Invite") · rows: VAvatar identity
circle · name `headline` · subline (Setup/New/quiet-for-N-days/consistency — colored
ONLY when the bucket demands) · VQuietStats adherence line (Food · Habits · Training)
· trailing VStatusPill (alert dot breathes; Setup = "Setup →" VTextAction). 5-bucket
truth model + sort unchanged.
**5.12 `client_details_screen.dart`** (3 tabs stay): hero = VAvatar 56 + name `title1`
+ VStatusPill + quiet streak; tabs → VSegmented · Today tab: nutrition mirrors §5.6
components read-only; workout card = VGroupCard with per-set quiet rows + progress
bar; check-in VCallout; note editor = VField + save state · History: existing charts →
VChart · Plan: macro targets card (VStatColumns + VMiniPill "Edit"), habits manager →
VSheet, swap/remove workout → VSheet with VOptionCard-style template picks. All
dialogs → VSheets (macro editor keeps its own StatefulWidget controllers).
**5.13 `coach_workout_library_screen.dart`**: Archetype B. VListHeader gets VMiniPill
"+ New" — **the FAB is deleted**. Rows: squircle initial avatar, name, VQuietStats
(exercises · sets · reps), trailing VMiniPill "Assign". Delete confirm → VSheet.
**5.15 `template_editor_screen.dart`**: full-screen editor on `canvas`, exercise cards
= VGroupCards with quiet steppers, save = pinned VPillButton.primary.
`AssignWorkoutSheet` → VSheet + VSegmented (Once/Weekly) + weekday VOptionCard grid +
summary line.
**5.16 `upgrade_screen.dart` — Paywall (Moment).** skyGlow, `serifTitle` value
statement, tier cards = VOptionCards (selected = gold ring + wash; "current"/"popular"
as `caption` tags), feature bullets as hairline rows, VPillButton.primary CTA, restore
VTextAction.

### Shared

**5.17 `language_picker.dart`** → VSheet + rows + gold check. **5.18
`delete_account.dart`** → destructive VSheet flow. **5.19 Toasts/errors** app-wide →
VToast. **5.20 Tab shells** (`*_persistant_tabs.dart`) → VTabBar styling.

---

## 6 · HARD RULES (violating any of these = the change is wrong)

1. **Color budget per screen**: canvas + ink + gold + at most ONE status family in
   content. (Status-driven lists exempt — but status lives only in pills/dots/one
   subline, said once per row.)
2. Cards have **no borders**. Hairlines only as §1.5 allows.
3. **No colored shadows, no glows.** Single exception: the at-risk breathing dot.
4. **Gold never fills large areas** (cards, backgrounds, hero surfaces). Gold text on
   light uses `goldDeep`. Solid gold = VPillButton.gold under its reserve rule only.
5. **No raw emojis.** Phosphor glyphs in tinted circles.
6. **No FAB. No Material AlertDialog. No gradient card fills. No two-layer shadows.
   No gradient rings.**
7. Uppercase+tracking only in `label` (settings group headers).
8. Serif only ≥24px, only display moments — never rows, data, buttons.
9. **One signature detail per screen maximum** (hero pill circle, code boxes, breathing
   dot…). If a screen has two, cut one.
10. Numbers that change = tabular figures. Big numbers count up once, on dashboards only.
11. Atmosphere (skyGlow/glass/dark canvas) only on Moment screens (§4-D).
12. Every string localized (6 langs); new code uses Directional geometry (RTL).
13. Reskin ≠ refactor: logic, streams, services untouched; controllers owned by their
    sheets; stream-caching preserved.
14. `withValues(alpha:)` always; `flutter analyze` = 0 before handoff.
15. Screens ship one at a time; Yassine phone-tests before the next begins.
16. Every interactive element has a ≥44pt hit area, and every screen is verified at
    max clamped text scale (§1.10) before handoff.
17. Haptics fire only from user actions — never from stream/data-driven state changes.

---

## 7 · MIGRATION PLAN & PROGRESS TRACKER

**Process per unit of work** (one screen or one foundation step): fresh Claude session
→ "Read design.md; do <unit> per §…" → build → `flutter analyze` = 0 → Yassine
phone-tests → iterate in the same session until he approves → git commit → **tick the
box here and log his verdict in one line**. This checklist is the redesign's changelog
— every session reads it, so progress survives context loss. Never start the next
screen before the current one is approved.

**Phase 1 — Foundation (no screens touched)**
- [x] `lib/theme/tokens.dart` — `ValenceTokens` light+dark (§1.1) + VRadius/VSpace/VDuration/VMotion
- [x] `app_theme.dart` rebuilt from tokens; fonts Inter Tight / Inter / Fraunces (§1.2, §3)
- [x] V-core in `lib/ui/`: VPillButton, VTextAction, VIconCircle, VMiniPill,
      VSegmented, VSearchBar, VGroupCard, VRow, VAvatar, VStatusPill, VStatColumn,
      VQuietStats, VHeroMetric, VField, VSheet, VToast, VHeader, VEmpty, VSkeleton
      (+ VPressable, VOptionCard, VSkyGlow, VCodeBoxes built alongside their screens;
      tokens.legibleTint() + theme-aware VSkyGlow added v2.3)
- NOTE: the theme swap shifts EVERY screen's tone immediately; unmigrated screens will
  look off until their turn. Expected — do not "fix" them ad hoc.

**Phase 2 — Pilot (gates everything)**
- [ ] `client_progress_screen` + VChart (§5.8) — Yassine's on-device verdict: ______
- [ ] Serif (Fraunces) verdict on device: keep / drop — decision: ______

**Phase 3 — Pre-app arc** — done out of order at Yassine's call (Phase 2 pilot deferred)
- [x] Cover / get_started (§5.1 → pivoted, see v2.3) · [x] Role carousels (§5.2 → lean intro, v2.3) · [ ] Client intake (§5.3)
- [ ] Coach intake (§5.3) · [x] Auth + VCodeBoxes (§5.4) · [ ] Splash (§5.5)
- Verdicts: get_started + role intro — Yassine happy on device (2026-07-12). Auth
  (login/signup/link_coach) — built 2026-07-12, pending on-device test.

**Phase 4 — Client side (home LAST — layout-locked and beloved; earn it)**
- [ ] Workouts (§5.7) · [ ] Meal sheet 3 phases (§5.9) · [ ] Settings (§5.10)
- [ ] **Home (§5.6) — only after everything above is approved**

**Phase 5 — Coach side**
- [ ] Roster (§5.11) · [ ] Client details (§5.12) · [ ] Library (§5.13)
- [ ] Template editor (§5.15) · [ ] Coach settings (§5.10/F) · [ ] Paywall (§5.16)

**Phase 6 — Sweep**
- [ ] Language picker (§5.17) · [ ] Delete-account flow (§5.18) · [ ] Toasts app-wide
      (§5.19) · [ ] Tab bars (§5.20)

**Phase 7 — Cleanup**
- [ ] Retire `AppColors` legacy aliases (tokens only) · [ ] Delete retired signature
      components (gradient rings, glow pills, two-layer cards) · [ ] Full app pass:
      light/dark/RTL/max-text-scale on every screen

## 8 · DECISION RECORD (why it is this way)

- Purely-iOS direction, sandy gold kept, "nothing cheap" — Yassine, batch 0.
- Warm cream canvas, borderless cards, naked data, pill controls, editorial type —
  batch 1 (progress/chat/meal-AI references).
- Ink-as-anchor (gold can't carry structure at mid-tone) — batch 1 analysis, confirmed
  by Yassine in Q&A. Primary CTA = ink pill; dark mode anchor = warm-white pill.
- Serif display voice (Fraunces trial, commit-or-drop on device) — batch 2 + Q&A.
- Pre-app three acts; universal cover → role split; product-as-hero cover art (no
  photography) — batch 2/3 + Q&A.
- Ruler dial: ONE unified component (round-10 "cringe" lesson: coherence > novelty).
- Both themes day one via AppTheme; light is the design-lead — Q&A.
- Disciplined motion; Roster Pulse kept restyled; atmosphere reserved for moments — Q&A.
- Client home layout locked; roster structure locked; per-screen IA preserved
  app-wide — Yassine, batch 3.
- Emoji ban (Android emoji font mismatch), status hues warmed, uppercase-label diet —
  batch 2/3 analysis.
- v2.3 (Yassine live-review pivots, 2026-07-12): foundation (tokens/theme/V-core) built,
  then the pre-app arc reskinned OUT of §7 phase order at Yassine's call (Phase 2 pilot
  deferred). **Cover (§5.1) pivoted** — the dark cinematic product-carousel was rejected on
  device; get_started is now a calm, THEME-RESPONSIVE welcome (serif greeting + universal
  subtitle) → role split (VOptionCards) → continue. No forced-dark, no product-mock slides.
  **Role intro (§5.2) pivoted** — the 3-slide product tour replaced by ONE scannable "how
  Valence works for you" screen (`RoleIntroScreen`, reusing the `ob*` copy as feature rows),
  personalize-first into the intake; `onboarding_carousel.dart` orphaned (retire in Phase 7).
  **Client role relabeled "Athlete"** on the picker (new `roleAthlete`; `roleClient`="Client"
  stays in coach-facing UI). **`goldDeep` (light) darkened** `#A8875A`→`#8C6A2E` to actually
  meet the §1.10 4.5:1 floor for gold text; added `tokens.legibleTint()` (gold→goldDeep glyphs
  on light) and theme-aware `VSkyGlow` (glow halved on light so cream doesn't muddy).
  **Auth (§5.4) reskinned** — themed fields + VCodeBoxes invite ceremony; snackbars → VToast.
  Intro CTAs made role-specific ("Build my plan" / "Set up my profile") to kill a duplicate
  "Get started". §5.1/§5.2 prose above is superseded by this entry where they conflict.
- v2.2 (LOCK): color law made explicit (gold = brand identity, ink = structure —
  Yassine confirmed gold is THE brand color; the law prevents misreading it as
  button-fill duty), §7 converted to a living progress tracker/changelog, CLAUDE.md
  created to point every session here. File locked.
- v2.1: external iOS-expert review adopted where correct — Dynamic Type clamps + 44pt
  targets + contrast floor (§1.10), success/error haptics + user-action-only haptic
  law (§1.8), swipe-action visual language locked early (§2 VRow), sheet keyboard rule
  (§2 VSheet). REJECTED from that review: haptics on passive status transitions
  (stream-driven buzzing = noise) and UIKit notification-haptic APIs (don't exist in
  Flutter's HapticFeedback — impacts approximate).
