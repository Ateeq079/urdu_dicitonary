/// A saved/searched word reference. [lang] is 'en' or 'ur'.
class WordRef {
  final String word;
  final String lang;
  final String gloss;

  const WordRef({required this.word, required this.lang, this.gloss = ''});

  Map<String, dynamic> toJson() => {'word': word, 'lang': lang, 'gloss': gloss};

  factory WordRef.fromJson(Map<String, dynamic> j) => WordRef(
    word: (j['word'] as String?) ?? '',
    lang: (j['lang'] as String?) ?? 'en',
    gloss: (j['gloss'] as String?) ?? '',
  );

  String get key => '$lang:${word.toLowerCase()}';
}
