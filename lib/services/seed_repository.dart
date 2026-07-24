import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/seed_word.dart';

/// Loads and queries the bundled seed headword index.
///
/// Search capabilities:
///   - Exact / prefix match on urdu, roman, english fields.
///   - Levenshtein fuzzy correction (tolerance 1–2 edits).
///   - Roman-Urdu transliteration input: typing "mohabbat" finds محبت.
///   - Urdu diacritic normalization: ignores zer/zabar/pesh in matching.
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

  // ── Transliteration map ────────────────────────────────────────────────────
  // Maps common Roman-Urdu spellings → Unicode Urdu.
  // Matching is done on the romanised query before the fuzzy pass so that
  // e.g. "mohabbat" returns محبت without requiring the user to type Urdu.

  static const Map<String, String> _translitMap = {
    'mohabbat': 'محبت',
    'ishq': 'عشق',
    'dil': 'دل',
    'raat': 'رات',
    'din': 'دن',
    'zindagi': 'زندگی',
    'khwab': 'خواب',
    'aansu': 'آنسو',
    'waqt': 'وقت',
    'umeed': 'امید',
    'dost': 'دوست',
    'dushman': 'دشمن',
    'khushi': 'خوشی',
    'gham': 'غم',
    'dard': 'درد',
    'sukoon': 'سکون',
    'roshan': 'روشن',
    'andhera': 'اندھیرا',
    'subah': 'صبح',
    'shaam': 'شام',
    'sitara': 'ستارہ',
    'chand': 'چاند',
    'aasman': 'آسمان',
    'zameen': 'زمین',
    'paani': 'پانی',
    'aag': 'آگ',
    'hawa': 'ہوا',
    'phool': 'پھول',
    'patta': 'پتہ',
    'darya': 'دریا',
    'khuda': 'خدا',
    'rabb': 'رب',
    'duaa': 'دعا',
    'ibadat': 'عبادت',
    'insaan': 'انسان',
    'bachcha': 'بچہ',
    'aurat': 'عورت',
    'mard': 'مرد',
    'bhai': 'بھائی',
    'behen': 'بہن',
    'maa': 'ماں',
    'baap': 'باپ',
    'ghar': 'گھر',
    'shehr': 'شہر',
    'mulk': 'ملک',
    'safar': 'سفر',
    'kitaab': 'کتاب',
    'qalam': 'قلم',
    'ilm': 'علم',
    'adab': 'ادب',
  };

  // ── Diacritic normalization ───────────────────────────────────────────────

  /// Strips Urdu diacritics (harakat) so matching tolerates their omission.
  static String _stripDiacritics(String s) {
    // Unicode ranges: Harakat / Quranic annotation marks (0x0610–0x061A, 0x064B–0x065F)
    return s.replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F]'), '');
  }

  // ── Public search API ────────────────────────────────────────────────────

  /// Instant suggestions: exact-ish matches first, then fuzzy corrections.
  List<SeedWord> suggest(String query, {int limit = 8}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    // 1. Try transliteration map first (Roman-Urdu input).
    final translitUrdu = _translitMap[q];

    final direct = words.where((w) {
      if (translitUrdu != null && w.urdu.contains(translitUrdu)) return true;
      return w.matches(_stripDiacritics(q));
    }).toList();

    if (direct.length >= limit) return direct.take(limit).toList();

    // 2. Fuzzy pass for corrections.
    final seen = direct.toSet();
    final fuzzy = <_Scored>[];
    for (final w in words) {
      if (seen.contains(w)) continue;
      final score = _bestDistance(q, w, translitUrdu);
      if (score <= _threshold(q)) fuzzy.add(_Scored(w, score));
    }
    fuzzy.sort((a, b) => a.score.compareTo(b.score));
    return [...direct, ...fuzzy.map((s) => s.word)].take(limit).toList();
  }

  /// Closest single headword for a possibly-misspelled query, or null.
  SeedWord? fuzzyCorrect(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return null;
    final translitUrdu = _translitMap[q];
    _Scored? best;
    for (final w in words) {
      if (w.matches(_stripDiacritics(q))) return w;
      final d = _bestDistance(q, w, translitUrdu);
      if (best == null || d < best.score) best = _Scored(w, d);
    }
    if (best != null && best.score <= _threshold(q)) return best.word;
    return null;
  }

  int _threshold(String q) => q.runes.length <= 4 ? 1 : 2;

  int _bestDistance(String q, SeedWord w, String? translitUrdu) {
    final candidates = [
      _stripDiacritics(w.urdu),
      w.roman.toLowerCase(),
      w.english.toLowerCase(),
    ];
    if (translitUrdu != null) candidates.add(translitUrdu);
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
