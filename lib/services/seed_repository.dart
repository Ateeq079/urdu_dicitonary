import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/seed_word.dart';

/// Loads and queries the bundled seed headword index.
class SeedRepository {
  SeedRepository(this.words);

  final List<SeedWord> words;

  static Future<SeedRepository> load() async {
    final raw = await rootBundle.loadString('assets/data/seed_words.json');
    final list = (jsonDecode(raw) as List)
        .whereType<Map<String, dynamic>>()
        .map(SeedWord.fromJson)
        .toList();
    return SeedRepository(list);
  }

  List<SeedWord> byCategory(String id) =>
      words.where((w) => w.category == id).toList();

  /// Instant suggestions: exact-ish matches first, then fuzzy corrections.
  List<SeedWord> suggest(String query, {int limit = 8}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final direct = words.where((w) => w.matches(q)).toList();
    if (direct.length >= limit) return direct.take(limit).toList();

    // Add fuzzy matches not already present.
    final seen = direct.toSet();
    final fuzzy = <_Scored>[];
    for (final w in words) {
      if (seen.contains(w)) continue;
      final score = _bestDistance(q, w);
      if (score <= _threshold(q)) fuzzy.add(_Scored(w, score));
    }
    fuzzy.sort((a, b) => a.score.compareTo(b.score));
    return [...direct, ...fuzzy.map((s) => s.word)].take(limit).toList();
  }

  /// Closest single headword for a possibly-misspelled query, or null.
  SeedWord? fuzzyCorrect(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return null;
    _Scored? best;
    for (final w in words) {
      if (w.matches(q)) return w; // exact-ish, no correction needed
      final d = _bestDistance(q, w);
      if (best == null || d < best.score) best = _Scored(w, d);
    }
    if (best != null && best.score <= _threshold(q)) return best.word;
    return null;
  }

  int _threshold(String q) => q.runes.length <= 4 ? 1 : 2;

  int _bestDistance(String q, SeedWord w) {
    final candidates = [
      w.urdu,
      w.roman.toLowerCase(),
      w.english.toLowerCase(),
    ];
    var best = 1 << 30;
    for (final c in candidates) {
      final d = levenshtein(q, c);
      if (d < best) best = d;
    }
    return best;
  }
}

class _Scored {
  final SeedWord word;
  final int score;
  _Scored(this.word, this.score);
}

/// Standard Levenshtein edit distance.
int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final ar = a.runes.toList();
  final br = b.runes.toList();
  var prev = List<int>.generate(br.length + 1, (i) => i);
  var curr = List<int>.filled(br.length + 1, 0);

  for (var i = 0; i < ar.length; i++) {
    curr[0] = i + 1;
    for (var j = 0; j < br.length; j++) {
      final cost = ar[i] == br[j] ? 0 : 1;
      curr[j + 1] = [
        curr[j] + 1,
        prev[j + 1] + 1,
        prev[j] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }
  return prev[br.length];
}
