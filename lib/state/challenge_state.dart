import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/seed_word.dart';
import '../models/spaced_repetition_entry.dart';
import '../services/seed_repository.dart';
import '../services/storage_service.dart';

/// Manages the daily challenge and the spaced-repetition review queue.
class ChallengeState extends ChangeNotifier {
  ChallengeState(this._storage, this._seed) {
    _load();
  }

  final StorageService _storage;
  final SeedRepository _seed;

  static const _kLearned = 'learned';
  static const _kReviewQueue = 'review_queue';

  Set<String> _learned = {};
  List<SpacedRepetitionEntry> _reviewQueue = [];

  // ── Daily Challenge ──────────────────────────────────────────────────────

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

  // ── Spaced Repetition Review Queue ───────────────────────────────────────

  List<SpacedRepetitionEntry> get reviewQueue =>
      List.unmodifiable(_reviewQueue);

  List<SpacedRepetitionEntry> get dueToday =>
      _reviewQueue.where((e) => e.isDueToday).toList();

  /// Add a [SeedWord] to the review queue (idempotent — skips if already in queue).
  void addToReview(SeedWord word) {
    final alreadyQueued = _reviewQueue.any((e) => e.urdu == word.urdu);
    if (alreadyQueued) return;
    _reviewQueue.add(SpacedRepetitionEntry(
      urdu: word.urdu,
      roman: word.roman,
      english: word.english,
      intervalDays: 1,
      nextReview: DateTime.now().add(const Duration(days: 1)),
      repetitions: 0,
    ));
    _persistQueue();
    notifyListeners();
  }

  /// Mark a review entry as easy, advancing its interval.
  void markEasy(SpacedRepetitionEntry entry) {
    _updateEntry(entry, entry.markEasy());
  }

  /// Mark a review entry as hard, resetting its interval to 1 day.
  void markHard(SpacedRepetitionEntry entry) {
    _updateEntry(entry, entry.markHard());
  }

  void _updateEntry(SpacedRepetitionEntry old, SpacedRepetitionEntry updated) {
    final idx = _reviewQueue.indexWhere((e) => e.urdu == old.urdu);
    if (idx == -1) return;
    _reviewQueue[idx] = updated;
    _persistQueue();
    notifyListeners();
  }

  void removeFromReview(SpacedRepetitionEntry entry) {
    _reviewQueue.removeWhere((e) => e.urdu == entry.urdu);
    _persistQueue();
    notifyListeners();
  }

  // ── Persistence ──────────────────────────────────────────────────────────

  void _load() {
    _learned = _storage.getStringList(_kLearned).toSet();
    _reviewQueue = _storage
        .getStringList(_kReviewQueue)
        .map((s) {
          try {
            return SpacedRepetitionEntry.fromJson(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<SpacedRepetitionEntry>()
        .toList();
  }

  void _persistQueue() {
    _storage.setStringList(
      _kReviewQueue,
      _reviewQueue.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  int _daySeed() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return midnight.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }
}
