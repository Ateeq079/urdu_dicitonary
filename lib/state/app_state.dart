import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/seed_word.dart';
import '../services/seed_repository.dart';
import '../services/storage_service.dart';

/// A saved/searched item. [lang] is the language to look the word up in.
class WordRef {
  final String word;
  final String lang; // 'en' or 'ur'
  final String gloss;

  const WordRef({required this.word, required this.lang, this.gloss = ''});

  Map<String, dynamic> toJson() =>
      {'word': word, 'lang': lang, 'gloss': gloss};

  factory WordRef.fromJson(Map<String, dynamic> j) => WordRef(
        word: (j['word'] as String?) ?? '',
        lang: (j['lang'] as String?) ?? 'en',
        gloss: (j['gloss'] as String?) ?? '',
      );

  String get key => '$lang:${word.toLowerCase()}';
}

class AppState extends ChangeNotifier {
  AppState(this._storage, this._seed) {
    _load();
  }

  final StorageService _storage;
  final SeedRepository _seed;

  static const _kFavorites = 'favorites';
  static const _kRecents = 'recents';
  static const _kLearned = 'learned';

  List<WordRef> _favorites = [];
  List<WordRef> _recents = [];
  Set<String> _learned = {}; // seed urdu words marked learned

  List<WordRef> get favorites => List.unmodifiable(_favorites);
  List<WordRef> get recents => List.unmodifiable(_recents);

  SeedRepository get seed => _seed;

  void _load() {
    _favorites = _storage
        .getStringList(_kFavorites)
        .map((s) => WordRef.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    _recents = _storage
        .getStringList(_kRecents)
        .map((s) => WordRef.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    _learned = _storage.getStringList(_kLearned).toSet();
  }

  // ---- Favorites ----
  bool isFavorite(WordRef ref) => _favorites.any((f) => f.key == ref.key);

  void toggleFavorite(WordRef ref) {
    if (isFavorite(ref)) {
      _favorites.removeWhere((f) => f.key == ref.key);
    } else {
      _favorites.insert(0, ref);
    }
    _persistFavorites();
    notifyListeners();
  }

  void removeFavorite(WordRef ref) {
    _favorites.removeWhere((f) => f.key == ref.key);
    _persistFavorites();
    notifyListeners();
  }

  void _persistFavorites() => _storage.setStringList(
      _kFavorites, _favorites.map((f) => jsonEncode(f.toJson())).toList());

  // ---- Recent searches ----
  void addRecent(WordRef ref) {
    _recents.removeWhere((r) => r.key == ref.key);
    _recents.insert(0, ref);
    if (_recents.length > 30) _recents = _recents.sublist(0, 30);
    _storage.setStringList(
        _kRecents, _recents.map((r) => jsonEncode(r.toJson())).toList());
    notifyListeners();
  }

  void clearRecents() {
    _recents = [];
    _storage.remove(_kRecents);
    notifyListeners();
  }

  // ---- Word of the Day (deterministic per calendar day) ----
  SeedWord get wordOfDay {
    final words = _seed.words;
    if (words.isEmpty) {
      return const SeedWord(
          urdu: '', roman: '', english: '', category: 'daily');
    }
    return words[_daySeed() % words.length];
  }

  // ---- Daily Challenge (5 words per day) ----
  List<SeedWord> get challengeWords {
    final words = _seed.words;
    if (words.isEmpty) return const [];
    final start = (_daySeed() * 5) % words.length;
    return List.generate(5, (i) => words[(start + i) % words.length]);
  }

  bool isLearned(SeedWord w) => _learned.contains(w.urdu);

  void toggleLearned(SeedWord w) {
    if (_learned.contains(w.urdu)) {
      _learned.remove(w.urdu);
    } else {
      _learned.add(w.urdu);
    }
    _storage.setStringList(_kLearned, _learned.toList());
    notifyListeners();
  }

  int get learnedTotal => _learned.length;

  int get challengeLearnedToday =>
      challengeWords.where((w) => _learned.contains(w.urdu)).length;

  /// Days since epoch — changes once per calendar day in local time.
  int _daySeed() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return midnight.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }
}
