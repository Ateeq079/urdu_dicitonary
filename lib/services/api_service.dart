import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/word_result.dart';
import 'storage_service.dart';

/// Result wrapper distinguishing the three outcomes a lookup can have.
enum LookupStatus { found, notFound, offline }

class LookupResult {
  final LookupStatus status;
  final WordResult? data;
  final bool fromCache;

  const LookupResult(this.status, {this.data, this.fromCache = false});
}

/// Client for the Free Dictionary API with a local response cache so that
/// previously looked-up words keep working offline.
class ApiService {
  ApiService(this._storage);

  final StorageService _storage;

  static const _base = 'https://freedictionaryapi.com/api/v1/entries';
  static const _cachePrefix = 'cache:';

  String _cacheKey(String lang, String word) =>
      '$_cachePrefix$lang:${word.toLowerCase()}';

  WordResult? _readCache(String lang, String word) {
    final raw = _storage.getString(_cacheKey(lang, word));
    if (raw == null) return null;
    try {
      return WordResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Look up [word] in [lang] ('en' or 'ur'). Tries the network; on failure
  /// falls back to cache. Caches successful, non-empty responses.
  Future<LookupResult> lookup(String lang, String word) async {
    final trimmed = word.trim();
    if (trimmed.isEmpty) {
      return const LookupResult(LookupStatus.notFound);
    }

    final uri = Uri.parse(
      '$_base/$lang/${Uri.encodeComponent(trimmed)}?translations=true',
    );

    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) {
        final json = jsonDecode(utf8.decode(resp.bodyBytes))
            as Map<String, dynamic>;
        final result = WordResult.fromJson(json);
        if (result.isEmpty) {
          // Genuine "no such word" — but maybe an older cache has it.
          final cached = _readCache(lang, trimmed);
          if (cached != null && !cached.isEmpty) {
            return LookupResult(LookupStatus.found,
                data: cached, fromCache: true);
          }
          return const LookupResult(LookupStatus.notFound);
        }
        await _storage.setString(_cacheKey(lang, trimmed), jsonEncode(json));
        return LookupResult(LookupStatus.found, data: result);
      }
      // Non-200: fall through to cache.
      final cached = _readCache(lang, trimmed);
      if (cached != null && !cached.isEmpty) {
        return LookupResult(LookupStatus.found, data: cached, fromCache: true);
      }
      return const LookupResult(LookupStatus.notFound);
    } on TimeoutException {
      return _offlineOrCache(lang, trimmed);
    } catch (_) {
      return _offlineOrCache(lang, trimmed);
    }
  }

  LookupResult _offlineOrCache(String lang, String word) {
    final cached = _readCache(lang, word);
    if (cached != null && !cached.isEmpty) {
      return LookupResult(LookupStatus.found, data: cached, fromCache: true);
    }
    return const LookupResult(LookupStatus.offline);
  }
}
