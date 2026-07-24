# Lughat — Claude Instructions & Project Reference
> **Lughat 2.0 PRD is the active source of truth.** This file distills it into
> actionable rules for Claude. Read *every* section before modifying code.

---

## 1. Project Overview

**Lughat** is an offline-first Urdu ⇄ English dictionary built with Flutter.
Core features: bidirectional search, Word of the Day, Daily Challenge, Recent
Searches, and Favorites. The goal for **Lughat 2.0** is to evolve from a
functionally sound but visually generic app into a premium, retention-driving
daily-use tool — across three dimensions: **Visual**, **Logical**, and
**Experience**.

---

## 2. Technology Stack

| Area | Current | Target (2.0) |
|---|---|---|
| Framework | Flutter / Dart | ← same |
| State | `provider` — single `AppState` | `provider` — split into feature notifiers |
| Local Storage | `shared_preferences` (all data) | `shared_preferences` for flags/settings; `sqflite` or `Isar` for structured history/review |
| Networking | `http` | `http` + `connectivity_plus` for retry queueing |
| Theming | Single teal seed color, flat gradients | Full `ColorScheme.fromSeed` M3 token set, verified dark mode |
| Search | Exact/prefix match | Fuzzy match + Roman-Urdu transliteration lookup |

---

## 3. Build & Run Commands

```bash
flutter pub get      # Fetch dependencies
flutter run          # Run on connected device/emulator
flutter test         # Run all tests
flutter clean        # Clean build artifacts
```

---

## 4. Directory Structure

```
lib/
├── main.dart
├── theme.dart           # ALL color, shape, and typography tokens live here
├── models/              # SeedWord, WordResult, WordRef
├── services/            # ApiService, StorageService, SeedRepository
├── state/               # AppState (to be split into feature notifiers)
└── screens/             # RootShell, HomeScreen, SearchScreen, WordDetailScreen,
                         # ChallengeScreen, CategoriesScreen
assets/
└── data/seed_words.json # Offline vocabulary corpus
```

---

## 5. Architecture & Code Conventions

### 5.1 State Management (`lib/state/`)

**Current:** single `AppState extends ChangeNotifier` injected via
`MultiProvider` at the root. Manages Favorites, Recents, Learned Words, and
Word of the Day.

**Target (2.0):** split into focused notifiers to keep rebuild scope narrow:
- `FavoritesState`
- `RecentsState`
- `WordOfDayState`
- `ChallengeState` (will grow to include spaced-repetition review queue)

**Rules:**
- Always call `notifyListeners()` after mutating state.
- Always persist to `StorageService` (or future DB layer) immediately on
  mutation — do not defer persistence.
- Never call async work directly in `notifyListeners()` chains; schedule
  separately and notify after completion.

### 5.2 Services Layer (`lib/services/`)

| Service | Responsibility | 2.0 Change |
|---|---|---|
| `ApiService` | HTTP lookup + cache fallback | Upgrade to **three-state result** (see §6) |
| `StorageService` | `shared_preferences` wrapper | Keep for settings/flags only; structured data moves to DB |
| `SeedRepository` | Loads `seed_words.json` | Add fuzzy + transliteration search on top |

**Never** break the offline-first contract: a successful API response must
always be written to cache before returning to the caller.

### 5.3 Models Layer (`lib/models/`)

- **`SeedWord`** — offline vocab: `urdu`, `roman`, `english`, `category`.
- **`WordResult`** — API response: phonetics, definitions, parts of speech,
  synonyms, antonyms.
- **`WordRef`** — lightweight reference: `word` (String) + `lang` ('en'|'ur').
- **`LookupResult`** (2.0 addition) — wraps `WordResult` with a
  `ResultState` enum: `fresh | staleCache | unavailable`.

### 5.4 Offline / Cache Strategy

**Current (binary):** cache-or-fail.

**Target (three-state):**
1. `fresh` — successful network response, cache updated.
2. `staleCache` — network failed; returning last cached result. UI must show a
   subtle **"Offline — last updated [date]"** badge (not an error dialog).
3. `unavailable` — no network, not in cache or seed data. Offer a
   **"Save for later lookup"** action that queues the word for retry when
   connectivity returns (via `connectivity_plus` listener).

**Request queue:** lookups attempted offline are retried automatically when
connectivity is restored. Implement via `connectivity_plus` stream + a pending
queue persisted to `StorageService`.

---

## 6. UI & Theming Conventions (`lib/theme.dart`)

> **Rule:** All color, shape, and typography values must be defined in
> `lib/theme.dart`. Never hardcode them in widget files.

### 6.1 Color

- Use **`ColorScheme.fromSeed(seedColor: Color(0xFF0F7A6A))`** as the base.
- Map all UI surfaces to M3 color roles:
  `primary`, `primaryContainer`, `secondary`, `secondaryContainer`,
  `tertiary`, `surface`, `surfaceVariant`, `background`, `error`, etc.
- **No ad-hoc gradients** on general containers. Gradients are reserved for
  hero moments only: Word of the Day card, streak celebrations.
- Tonal elevation (surface tone shifts) communicates depth — do not use
  `BoxShadow` for elevation on cards.

### 6.2 Shape

| Component | Border Radius |
|---|---|
| Primary cards | 24dp |
| Chips / part-of-speech tags | 8–12dp |
| Dialogs | 28dp (M3 default) |
| Buttons | 12dp |

Do not apply 24dp radius universally — it flattens hierarchy.

### 6.3 Typography

- Define a full **M3 type scale** in `theme.dart` (displayLarge → labelSmall).
- **Urdu headwords**: use a Nastaliq-compatible font at a larger point size with
  increased `height` (line-height multiplier ≥ 1.8) — Urdu script needs more
  vertical breathing room than Latin at the same pt size.
- **English gloss/definitions**: compact, high-legibility font (e.g., Inter or
  Roboto).
- Avoid mixing font sizes ad hoc in widgets; always reference `Theme.of(context).textTheme.*`.

### 6.4 Dark Mode

- Ship a first-class dark theme using M3 dark tonal palette.
- **Not** just inverted colors — use dark surface tones as specified in the M3
  dark color role documentation.
- Default to `ThemeMode.system`.

### 6.5 RTL / Mixed-Direction Text

- Use `Directionality(textDirection: TextDirection.rtl)` in all widgets that
  render Urdu (`UrduText` and equivalents).
- For **mixed-direction cards** (Urdu headword + English definition in the same
  card), each text span must set its own `textDirection` explicitly — do not
  rely on a single inherited `Directionality` wrapping heterogeneous content.
- Add semantic labels (`Semantics(label: ...)`) on Urdu text nodes for
  TalkBack/VoiceOver — RTL screen-reader handling is inconsistent and needs
  explicit labeling.

### 6.6 State Layers

All tappable `ListTile`, `Card`, or `InkWell` rows must include M3 state layers
(hover/press/focus overlays) per spec — use `InkWell` or `FilledButton` with
`overlayColor` from the color scheme, not custom opacity hacks.

### 6.7 Accessibility Baseline (WCAG 2.2 AA)

- **Contrast:** 4.5:1 minimum for all text/background combinations in both
  light and dark themes.
- **Touch targets:** 24×24px absolute minimum; 48×48px preferred for primary
  actions.
- Verify both constraints after any theming change.

---

## 7. Search Intelligence (Phase 2)

- **Instant local suggestions**: query `SeedRepository` and cache before any
  network call. Show local results immediately; update with network results
  when they arrive.
- **Fuzzy matching**: tolerate 1–2 character Levenshtein distance for both
  Urdu and English inputs.
- **Roman-Urdu transliteration**: a lookup table maps common Romanized Urdu
  spellings to Unicode Urdu (e.g., `"mohabbat"` → `"محبت"`). Start with the
  top ~200 most common patterns from the seed corpus; expand iteratively.
- **Diacritic tolerance**: strip or normalize Urdu diacritics (zer, zabar,
  pesh) before matching so users don't need to type them.

---

## 8. Retention Features (Phase 3)

### Word of the Day 2.0
- Audio pronunciation (TTS via `flutter_tts` or pre-recorded files — decision
  pending, see §9).
- Example sentence in both Urdu and English.
- One-tap "Save to Review List" action.

### Daily Challenge → Spaced Repetition
- Rotate previously "learned" words back into short daily quizzes at increasing
  intervals (SM-2 algorithm or a simple fixed-interval ladder).
- Store review schedule in the structured DB (not `shared_preferences`).

### First-Run Onboarding (FTUE)
- 2–3 screens covering: offline capability, bidirectional search, favorites.
- Gate onboarding behind a `shared_preferences` flag so it only shows once.

---

## 9. Open Decisions (Require Answer Before Implementation)

| # | Question | Impact |
|---|---|---|
| 1 | **Audio source**: TTS (`flutter_tts`) vs. pre-recorded corpus? | TTS is easier to ship; quality for Urdu is inconsistent. Pre-recorded is higher quality but adds scope/cost. |
| 2 | **Structured DB**: `sqflite` vs. `Isar`? | `Isar` is faster and Dart-native but less mature; `sqflite` is battle-tested. Affects migration path. |
| 3 | **Urdu font**: which Nastaliq font? Need a performant, licensable option (heavy fonts hurt load time). | Affects headword rendering quality and app bundle size. |
| 4 | **Transliteration scope**: start with top 200 patterns or full corpus? | Affects Phase 2 accuracy and timeline. |

---

## 10. Phased Roadmap

| Phase | Scope | Status |
|---|---|---|
| **1 — Foundation** | Full M3 token migration, dark mode, `AppState` split, three-state offline model | 🔲 Not started |
| **2 — Search Intelligence** | Fuzzy matching, Roman-Urdu transliteration, instant local suggestions | 🔲 Not started |
| **3 — Retention Loop** | Word of the Day 2.0 (audio + examples), spaced-repetition review, FTUE onboarding | 🔲 Not started |
| **4 — Polish & Accessibility** | Contrast/touch-target audit, RTL screen-reader verification, golden/widget tests, cold-cache performance pass | 🔲 Not started |

---

## 11. Critical Rules for Claude

1. **Never hardcode colors, radii, or font sizes** in widget files — always
   reference `lib/theme.dart` tokens or `Theme.of(context)`.
2. **Never break the offline-first contract** — successful API responses must
   be written to cache before returning to the caller.
3. **Always call `notifyListeners()`** after mutating any `ChangeNotifier`
   state, and always persist the change immediately.
4. **Always set `textDirection` explicitly** on mixed-direction text spans —
   never rely on a single inherited `Directionality` for Urdu+English content
   in the same card.
5. **Respect phase boundaries** — do not implement Phase 2/3 features while
   working on Phase 1. Flag cross-phase dependencies instead.
6. **Add accessibility semantics** on any new widget containing Urdu text.
7. When adding new packages, update `pubspec.yaml` and note the addition here
   in the Technology Stack table (§2).
