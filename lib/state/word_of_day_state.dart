import 'package:flutter/foundation.dart';

import '../models/seed_word.dart';
import '../services/seed_repository.dart';

/// Manages the Word of the Day (deterministic, changes at midnight).
class WordOfDayState extends ChangeNotifier {
  WordOfDayState(this._seed);

  final SeedRepository _seed;

  SeedWord get wordOfDay {
    final words = _seed.words;
    if (words.isEmpty) {
      return const SeedWord(urdu: '', roman: '', english: '', category: 'daily');
    }
    return words[_daySeed() % words.length];
  }

  /// Days since epoch — one unique value per calendar day in local time.
  int _daySeed() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return midnight.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }
}
