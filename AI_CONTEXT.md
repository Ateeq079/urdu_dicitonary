# Lughat - AI Context & Architecture Report

## App Overview
**Lughat** is an offline-aware, offline-first Urdu ⇄ English dictionary app built with Flutter. It supports searching for words in both Urdu and English, maintaining a daily word of the day, tracking recent searches, managing a list of favorite words, and a daily challenge feature.

## Technology Stack
- **Framework**: Flutter / Dart
- **State Management**: `provider` (`ChangeNotifierProvider`)
- **Local Storage**: `shared_preferences` (wrapped in `StorageService`)
- **Networking**: `http` (used for fetching definitions)
- **UI Design**: Material 3 (custom theming)

## Core Architecture
The app follows a typical layered architecture, separating state, services, UI, and data models.

### State Management (`lib/state/app_state.dart`)
- `AppState` extends `ChangeNotifier` and is injected at the root of the app via `MultiProvider`.
- It handles synchronous state for UI consumption:
  - **Favorites**: List of saved `WordRef` items.
  - **Recents**: Up to 30 most recent searches.
  - **Learned Words**: Tracks which `SeedWord` items have been marked as learned.
  - **Word of the Day / Daily Challenge**: Deterministically generated daily based on the current calendar day's epoch.
- Data is persisted reactively to `StorageService` upon modification.

### Services Layer (`lib/services/`)
- **`ApiService`**: Communicates with the `freedictionaryapi.com` API. It wraps lookups with an offline-first caching mechanism using `StorageService`. If a word lookup fails due to a timeout or no connection, it attempts to load a previously successful result from the cache.
- **`StorageService`**: A simple abstraction over `shared_preferences` that handles reading/writing strings and string lists.
- **`SeedRepository`**: Loads offline dictionary data (like the base vocabulary) from `assets/data/seed_words.json`.

### Models Layer (`lib/models/`)
- **`SeedWord`**: Represents offline vocabulary words used for the Word of the Day and Daily Challenge. Contains fields like `urdu`, `roman`, `english`, and `category`.
- **`WordResult`**: Represents the structured response from the Free Dictionary API, including phonetics, definitions, parts of speech, synonyms, etc.
- **`WordRef`**: A lightweight reference model containing the word string and language ('en' or 'ur'), used extensively in recents and favorites lists.

### UI & Navigation (`lib/screens/`)
- **`RootShell`**: The main scaffolding containing a `NavigationBar` to switch between core tabs (Home, Search, Lists/Categories, Favorites).
- **`HomeScreen`**: Features the Word of the Day, Daily Challenge summary, offline translator shortcut, and recent searches.
- **`SearchScreen`**: Handles the primary search input.
- **`WordDetailScreen`**: Displays deep dictionary definitions, fetched via `ApiService`.
- **`ChallengeScreen` / `CategoriesScreen`**: Drives engagement features for offline learning.

## Theming & UI (`lib/theme.dart`)
- The app utilizes Flutter's Material 3 design system.
- Employs a premium, modern design aesthetic, specifically using a vibrant teal seed color (`Color(0xFF0F7A6A)`).
- Custom UI components often use increased border radii (e.g., `BorderRadius.circular(24)`), zero elevations, subtle border outlines, and soft linear gradients instead of flat, solid colors to achieve a clean, pill-like modern look.
- Uses `Directionality(textDirection: TextDirection.rtl)` globally in custom widgets (like `UrduText`) when rendering Urdu string data.

## Offline/Cache Strategy
The core value proposition relies heavily on its offline resilience.
1. `ApiService` fetches from `freedictionaryapi.com`.
2. A successful response is JSON-encoded and saved to `shared_preferences` with a cache key.
3. If an API request fails (e.g., `TimeoutException` or `SocketException`), `ApiService` falls back to its `_readCache` logic, returning a `LookupResult` with a `fromCache: true` flag. 

---
*Note for AI Assistants: When modifying components, ensure you maintain the `ChangeNotifier` state updates and do not break the offline-first mechanisms provided by `ApiService` and `StorageService`.*
