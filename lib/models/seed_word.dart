/// A lightweight headword from the bundled seed index. Definitions are NOT
/// stored here — they are fetched on demand from the Free Dictionary API.
/// The seed only powers browsing, suggestions, fuzzy correction, word-of-day
/// and the daily challenge.
class SeedWord {
  final String urdu;
  final String roman;
  final String english;
  final String category;

  const SeedWord({
    required this.urdu,
    required this.roman,
    required this.english,
    required this.category,
  });

  factory SeedWord.fromJson(Map<String, dynamic> json) => SeedWord(
        urdu: (json['urdu'] as String?) ?? '',
        roman: (json['roman'] as String?) ?? '',
        english: (json['english'] as String?) ?? '',
        category: (json['category'] as String?) ?? 'daily',
      );

  /// Whether [q] (lowercased) loosely matches this headword.
  bool matches(String q) {
    return urdu.contains(q) ||
        roman.toLowerCase().contains(q) ||
        english.toLowerCase().contains(q);
  }
}

class WordCategory {
  final String id;
  final String title;
  final String emoji;

  const WordCategory(this.id, this.title, this.emoji);

  static const all = <WordCategory>[
    WordCategory('daily', 'Daily Use', '☕'),
    WordCategory('education', 'Education', '📚'),
    WordCategory('technology', 'Technology', '💻'),
    WordCategory('business', 'Business', '💼'),
    WordCategory('travel', 'Travel', '✈️'),
  ];

  static String titleFor(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.first).title;
}
