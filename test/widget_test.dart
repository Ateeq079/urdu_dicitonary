// Basic smoke test for Lughat's fuzzy search + Levenshtein helper.
import 'package:flutter_test/flutter_test.dart';
import 'package:urdu_dictionary/models/seed_word.dart';
import 'package:urdu_dictionary/services/seed_repository.dart';

void main() {
  test('levenshtein distance basics', () {
    expect(levenshtein('kitab', 'kitab'), 0);
    expect(levenshtein('kitb', 'kitab'), 1);
    expect(levenshtein('', 'abc'), 3);
  });

  test('fuzzy correction maps a misspelling to a headword', () {
    final repo = SeedRepository(const [
      SeedWord(
          urdu: 'کتاب', roman: 'kitab', english: 'book', category: 'education'),
    ]);
    final corrected = repo.fuzzyCorrect('kitb');
    expect(corrected?.english, 'book');
  });
}
