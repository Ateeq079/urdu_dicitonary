import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/word_result.dart';

/// Parses Urdu word entries from the English Wiktionary API.
///
/// Uses the MediaWiki `action=parse&prop=wikitext` endpoint which returns
/// structured wikitext for a word page. We extract the ==Urdu== section
/// and parse definitions, IPA, synonyms, and related terms from wikitext.
///
/// Coverage: ~5,000 Urdu headwords (significantly more than freedictionaryapi).
class WiktionaryService {
  static const _base = 'https://en.wiktionary.org/w/api.php';
  static const _userAgent =
      'LughatApp/2.0 (https://github.com/lughat; Urdu dictionary)';

  /// Fetch and parse the Urdu entry for [word] from English Wiktionary.
  /// Returns null if the word has no Urdu section.
  static Future<DictEntry?> fetchUrdu(String word) async {
    final url = Uri.parse(_base).replace(queryParameters: {
      'action': 'parse',
      'page': word.trim(),
      'prop': 'wikitext',
      'format': 'json',
    });

    try {
      final resp = await http.get(
        url,
        headers: {'User-Agent': _userAgent},
      ).timeout(const Duration(seconds: 20));

      if (resp.statusCode != 200) return null;

      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['error'] != null) return null;

      final wikitext =
          (json['parse']?['wikitext']?['*'] as String?) ?? '';
      if (wikitext.isEmpty) return null;

      return _parseUrduSection(word, wikitext);
    } catch (_) {
      return null;
    }
  }

  // ── Wikitext parser ───────────────────────────────────────────────────────

  /// Extracts the ==Urdu== section and parses it into a [DictEntry].
  static DictEntry? _parseUrduSection(String word, String wikitext) {
    // Find the ==Urdu== heading.
    final urduIdx = _findSection(wikitext, 'Urdu');
    if (urduIdx == -1) return null;

    // Slice from ==Urdu== to the next == level-2 heading (or end of text).
    final rest = wikitext.substring(urduIdx);
    final nextL2 = RegExp(r'\n==\w').firstMatch(rest.substring(2));
    final section = nextL2 != null
        ? rest.substring(0, nextL2.start + 2)
        : rest;

    // Extract part-of-speech (first ===Xyz=== heading in this section).
    final posMatch =
        RegExp(r'===([^=]+)===').firstMatch(section);
    final partOfSpeech =
        posMatch != null ? _cleanTemplate(posMatch.group(1)!) : '';

    // Extract IPA pronunciation.
    final ipaMatch =
        RegExp(r'\{\{ur-IPA\|([^}|]+)').firstMatch(section);
    String? pronunciation = ipaMatch?.group(1)?.trim();

    // Extract definitions (lines starting with # but not ##).
    final defs = <Sense>[];
    final defPattern = RegExp(r'^# (.+)$', multiLine: true);
    for (final m in defPattern.allMatches(section)) {
      final raw = m.group(1) ?? '';
      // Skip template-only lines (subcategories, usage labels, etc.).
      if (raw.trim().startsWith('{{') && !raw.contains('[[')) continue;
      final definition = _wikitextToPlain(raw);
      if (definition.isEmpty) continue;

      // Collect examples from lines starting with #: below this definition
      final start = m.start;
      final exPattern =
          RegExp(r'^#: \{\{quote[^}]*\}\}|^#: (.+)$', multiLine: true);
      final examples = <String>[];
      final subSection = section.substring(start);
      for (final ex in exPattern.allMatches(subSection)) {
        final exRaw = ex.group(1);
        if (exRaw == null) continue;
        final exText = _wikitextToPlain(exRaw);
        if (exText.isNotEmpty) examples.add(exText);
        if (examples.length >= 2) break;
      }

      defs.add(Sense(
        definition: definition,
        examples: examples,
        synonyms: const [],
        antonyms: const [],
        translations: const [],
      ));
      if (defs.length >= 6) break; // cap definitions
    }

    if (defs.isEmpty) return null;

    // Extract synonyms from col3/col2 template inside ====Synonyms====.
    final synsMatch =
        RegExp(r'====Synonyms====\s*\n\{\{col\d+\|ur\s*([\s\S]*?)\}\}')
            .firstMatch(section);
    final synonyms = <String>[];
    if (synsMatch != null) {
      final raw = synsMatch.group(1) ?? '';
      for (final m in RegExp(r'\|([^\|{}]+)').allMatches(raw)) {
        final tok = m.group(1)?.trim() ?? '';
        if (tok.isNotEmpty && !tok.startsWith('ur') && !tok.contains('=')) {
          synonyms.add(tok);
        }
        if (synonyms.length >= 6) break;
      }
    }

    return DictEntry(
      langCode: 'ur',
      langName: 'Urdu',
      partOfSpeech: partOfSpeech.toLowerCase(),
      pronunciation: pronunciation,
      forms: const [],
      senses: defs,
      synonyms: synonyms,
      antonyms: const [],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the index of `==[heading]==` in [text], or -1 if not found.
  static int _findSection(String text, String heading) {
    final patterns = [
      '==$heading==',
      '== $heading ==',
      '== $heading==',
      '==$heading ==',
    ];
    for (final p in patterns) {
      final idx = text.indexOf(p);
      if (idx != -1) return idx;
    }
    return -1;
  }

  /// Strips wikitext markup and returns plain text.
  static String _wikitextToPlain(String raw) {
    var s = raw;
    // [[link|display]] → display
    s = s.replaceAllMapped(
        RegExp(r'\[\[[^\]|]+\|([^\]]+)\]\]'), (m) => m.group(1)!);
    // [[link]] → link
    s = s.replaceAllMapped(RegExp(r'\[\[([^\]]+)\]\]'), (m) => m.group(1)!);
    // {{template|...}} → strip entirely
    // First remove nested templates.
    int prev;
    do {
      prev = s.length;
      s = s.replaceAll(RegExp(r'\{\{[^{}]*\}\}'), '');
    } while (s.length != prev);
    // Italics and bold
    s = s.replaceAll("'''", '').replaceAll("''", '');
    // HTML entities
    s = s
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');
    // Remove HTML tags
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    return s.trim();
  }

  static String _cleanTemplate(String s) =>
      s.replaceAll(RegExp(r'\{[^}]*\}'), '').trim();
}
