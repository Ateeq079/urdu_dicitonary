// Models for the Free Dictionary API (https://freedictionaryapi.com).
//
// Response shape:
// { "word": "...", "entries": [ { language, partOfSpeech, pronunciations,
//   forms, senses: [ { definition, examples, synonyms, antonyms,
//   translations: [ { language, word } ], subsenses } ], synonyms, antonyms } ] }

class WordResult {
  final String word;
  final List<DictEntry> entries;

  WordResult({required this.word, required this.entries});

  bool get isEmpty => entries.isEmpty;

  factory WordResult.fromJson(Map<String, dynamic> json) {
    final list = (json['entries'] as List?) ?? const [];
    return WordResult(
      word: (json['word'] as String?) ?? '',
      entries: list
          .whereType<Map<String, dynamic>>()
          .map(DictEntry.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  /// All Urdu translations found anywhere in this result (used for EN→UR).
  List<String> get urduTranslations {
    final out = <String>[];
    for (final e in entries) {
      for (final s in e.senses) {
        for (final t in s.translations) {
          if (t.langCode == 'ur' && !out.contains(t.word)) out.add(t.word);
        }
      }
    }
    return out;
  }

  /// First few English definitions (used for UR→EN summary).
  List<String> get definitions {
    final out = <String>[];
    for (final e in entries) {
      for (final s in e.senses) {
        if (s.definition.isNotEmpty && !out.contains(s.definition)) {
          out.add(s.definition);
        }
      }
    }
    return out;
  }
}

class DictEntry {
  final String langCode;
  final String langName;
  final String partOfSpeech;
  final String? pronunciation;
  final List<String> forms;
  final List<Sense> senses;
  final List<String> synonyms;
  final List<String> antonyms;

  DictEntry({
    required this.langCode,
    required this.langName,
    required this.partOfSpeech,
    required this.pronunciation,
    required this.forms,
    required this.senses,
    required this.synonyms,
    required this.antonyms,
  });

  factory DictEntry.fromJson(Map<String, dynamic> json) {
    final lang = (json['language'] as Map<String, dynamic>?) ?? const {};
    final prons = (json['pronunciations'] as List?) ?? const [];
    String? pron;
    for (final p in prons.whereType<Map<String, dynamic>>()) {
      final text = p['text'] as String?;
      if (text != null && text.isNotEmpty) {
        pron = text;
        break;
      }
    }
    return DictEntry(
      langCode: (lang['code'] as String?) ?? '',
      langName: (lang['name'] as String?) ?? '',
      partOfSpeech: (json['partOfSpeech'] as String?) ?? '',
      pronunciation: pron,
      forms: _formWords(json['forms']),
      senses: ((json['senses'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Sense.fromJson)
          .toList(),
      synonyms: _strList(json['synonyms']),
      antonyms: _strList(json['antonyms']),
    );
  }

  Map<String, dynamic> toJson() => {
        'language': {'code': langCode, 'name': langName},
        'partOfSpeech': partOfSpeech,
        'pronunciations':
            pronunciation == null ? [] : [
              {'text': pronunciation}
            ],
        'forms': forms.map((f) => {'word': f}).toList(),
        'senses': senses.map((s) => s.toJson()).toList(),
        'synonyms': synonyms,
        'antonyms': antonyms,
      };
}

class Sense {
  final String definition;
  final List<String> examples;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<Translation> translations;

  Sense({
    required this.definition,
    required this.examples,
    required this.synonyms,
    required this.antonyms,
    required this.translations,
  });

  factory Sense.fromJson(Map<String, dynamic> json) {
    return Sense(
      definition: (json['definition'] as String?) ?? '',
      examples: _strList(json['examples']),
      synonyms: _strList(json['synonyms']),
      antonyms: _strList(json['antonyms']),
      translations: ((json['translations'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Translation.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'definition': definition,
        'examples': examples,
        'synonyms': synonyms,
        'antonyms': antonyms,
        'translations': translations.map((t) => t.toJson()).toList(),
      };
}

class Translation {
  final String langCode;
  final String langName;
  final String word;

  Translation({
    required this.langCode,
    required this.langName,
    required this.word,
  });

  factory Translation.fromJson(Map<String, dynamic> json) {
    final lang = (json['language'] as Map<String, dynamic>?) ?? const {};
    return Translation(
      langCode: (lang['code'] as String?) ?? '',
      langName: (lang['name'] as String?) ?? '',
      word: (json['word'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'language': {'code': langCode, 'name': langName},
        'word': word,
      };
}

List<String> _strList(dynamic v) {
  if (v is List) {
    return v.whereType<String>().where((s) => s.isNotEmpty).toList();
  }
  return const [];
}

List<String> _formWords(dynamic v) {
  if (v is List) {
    return v
        .whereType<Map<String, dynamic>>()
        .map((m) => (m['word'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }
  return const [];
}
