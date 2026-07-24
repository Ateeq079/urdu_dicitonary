/// Tracks a word's spaced-repetition review schedule (SM-2 lite).
class SpacedRepetitionEntry {
  final String urdu;
  final String roman;
  final String english;

  /// How many days until the next review.
  final int intervalDays;

  /// When this word is next due for review.
  final DateTime nextReview;

  /// How many times this word has been reviewed successfully.
  final int repetitions;

  const SpacedRepetitionEntry({
    required this.urdu,
    required this.roman,
    required this.english,
    required this.intervalDays,
    required this.nextReview,
    required this.repetitions,
  });

  bool get isDueToday {
    final today = _today();
    return nextReview.isBefore(today) ||
        nextReview.isAtSameMomentAs(today) ||
        _isSameDay(nextReview, today);
  }

  /// Mark as easy → double the interval (capped at 30 days).
  SpacedRepetitionEntry markEasy() {
    final next = intervalDays == 0 ? 1 : (intervalDays * 2).clamp(1, 30);
    return _copy(
      intervalDays: next,
      nextReview: _today().add(Duration(days: next)),
      repetitions: repetitions + 1,
    );
  }

  /// Mark as hard → reset to 1-day interval.
  SpacedRepetitionEntry markHard() {
    return _copy(
      intervalDays: 1,
      nextReview: _today().add(const Duration(days: 1)),
      repetitions: repetitions,
    );
  }

  SpacedRepetitionEntry _copy({
    int? intervalDays,
    DateTime? nextReview,
    int? repetitions,
  }) =>
      SpacedRepetitionEntry(
        urdu: urdu,
        roman: roman,
        english: english,
        intervalDays: intervalDays ?? this.intervalDays,
        nextReview: nextReview ?? this.nextReview,
        repetitions: repetitions ?? this.repetitions,
      );

  Map<String, dynamic> toJson() => {
        'urdu': urdu,
        'roman': roman,
        'english': english,
        'intervalDays': intervalDays,
        'nextReview': nextReview.toIso8601String(),
        'repetitions': repetitions,
      };

  factory SpacedRepetitionEntry.fromJson(Map<String, dynamic> j) =>
      SpacedRepetitionEntry(
        urdu: (j['urdu'] as String?) ?? '',
        roman: (j['roman'] as String?) ?? '',
        english: (j['english'] as String?) ?? '',
        intervalDays: (j['intervalDays'] as int?) ?? 1,
        nextReview: DateTime.tryParse((j['nextReview'] as String?) ?? '') ??
            DateTime.now(),
        repetitions: (j['repetitions'] as int?) ?? 0,
      );

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
