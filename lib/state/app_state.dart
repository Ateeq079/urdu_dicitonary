import 'package:flutter/foundation.dart';

import '../models/seed_word.dart';
import '../models/word_ref.dart';
import '../services/seed_repository.dart';
import '../services/storage_service.dart';
import 'challenge_state.dart';
import 'favorites_state.dart';
import 'recents_state.dart';
import 'word_of_day_state.dart';

// WordRef is defined in lib/models/word_ref.dart and re-exported here
// so all screens that import app_state.dart still resolve it.
export '../models/word_ref.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppState — thin facade composing focused notifiers
// ─────────────────────────────────────────────────────────────────────────────
//
// ARCHITECTURE NOTE:
// The actual state lives in FavoritesState, RecentsState, WordOfDayState, and
// ChallengeState (all provided separately via MultiProvider). AppState here is
// a backwards-compatible façade so existing `context.watch<AppState>()` callers
// don't need to be rewritten all at once. It delegates every call to the
// appropriate focused notifier and re-fires notifyListeners() when any of them
// change.
//
// New code should prefer reading the specific notifier directly, e.g.:
//   context.watch<FavoritesState>().favorites
// rather than going through AppState.

class AppState extends ChangeNotifier {
  AppState(
    StorageService storage,
    SeedRepository seed, {
    required FavoritesState favorites,
    required RecentsState recents,
    required WordOfDayState wordOfDay,
    required ChallengeState challenge,
  })  : _favorites = favorites,
        _recents = recents,
        _wordOfDay = wordOfDay,
        _challenge = challenge,
        _seed = seed {
    // Bubble sub-notifier changes up through AppState so any
    // context.watch<AppState>() rebuild still works.
    _favorites.addListener(notifyListeners);
    _recents.addListener(notifyListeners);
    _wordOfDay.addListener(notifyListeners);
    _challenge.addListener(notifyListeners);
  }

  final FavoritesState _favorites;
  final RecentsState _recents;
  final WordOfDayState _wordOfDay;
  final ChallengeState _challenge;
  final SeedRepository _seed;

  // ── Seed access ─────────────────────────────────────────────────────────
  SeedRepository get seed => _seed;

  // ── Favorites delegates ─────────────────────────────────────────────────
  List<WordRef> get favorites => _favorites.favorites;
  bool isFavorite(WordRef ref) => _favorites.isFavorite(ref);
  void toggleFavorite(WordRef ref) => _favorites.toggleFavorite(ref);
  void removeFavorite(WordRef ref) => _favorites.removeFavorite(ref);

  // ── Recents delegates ──────────────────────────────────────────────────
  List<WordRef> get recents => _recents.recents;
  void addRecent(WordRef ref) => _recents.addRecent(ref);
  void clearRecents() => _recents.clearRecents();

  // ── Word of the Day delegates ───────────────────────────────────────────
  SeedWord get wordOfDay => _wordOfDay.wordOfDay;

  // ── Challenge / spaced-repetition delegates ─────────────────────────────
  List<SeedWord> get challengeWords => _challenge.challengeWords;
  bool isLearned(SeedWord w) => _challenge.isLearned(w);
  void toggleLearned(SeedWord w) => _challenge.toggleLearned(w);
  int get learnedTotal => _challenge.learnedTotal;
  int get challengeLearnedToday => _challenge.challengeLearnedToday;

  @override
  void dispose() {
    _favorites.removeListener(notifyListeners);
    _recents.removeListener(notifyListeners);
    _wordOfDay.removeListener(notifyListeners);
    _challenge.removeListener(notifyListeners);
    super.dispose();
  }
}
