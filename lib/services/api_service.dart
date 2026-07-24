import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/word_result.dart';
import 'database_service.dart';
import 'storage_service.dart';
import 'wiktionary_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Result types
// ─────────────────────────────────────────────────────────────────────────────

/// The three possible outcomes of a word lookup.
enum LookupStatus {
  /// Fresh network response — data is current.
  found,

  /// Network not available but a cached copy exists; [LookupResult.cachedAt]
  /// is set to when the cache was written.
  staleCache,

  /// Word not found (404 or empty response after exhausting cache).
  notFound,

  /// Completely offline AND word is not in cache.
  offline,
}

class LookupResult {
  final LookupStatus status;
  final WordResult? data;

  /// True when the data was served from local cache.
  final bool fromCache;

  /// When the cache entry was written (null if [fromCache] is false).
  final DateTime? cachedAt;

  const LookupResult(
    this.status, {
    this.data,
    this.fromCache = false,
    this.cachedAt,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// ApiService
// ─────────────────────────────────────────────────────────────────────────────

/// Client for the Free Dictionary API with a local response cache so that
/// previously looked-up words keep working offline.
///
/// Three-state result model:
///   fresh      — successful network call; cache updated.
///   staleCache — network unavailable; serving last cached result with timestamp.
///   notFound   — word genuinely not in dictionary (and not in cache).
///   offline    — network unavailable and word not in cache.
class ApiService {
  ApiService(this._storage);

  final StorageService _storage;

  static const _base = 'https://freedictionaryapi.com/api/v1/entries';
  static const _cachePrefix = 'cache:';
  static const _cacheTimestampPrefix = 'cache_ts:';
  static const _kPendingQueue = 'pending_queue';

  // ── Cache helpers ─────────────────────────────────────────────────────────

  String _cacheKey(String lang, String word) =>
      '$_cachePrefix$lang:${word.toLowerCase()}';

  String _tsKey(String lang, String word) =>
      '$_cacheTimestampPrefix$lang:${word.toLowerCase()}';

  WordResult? _readCache(String lang, String word) {
    final raw = _storage.getString(_cacheKey(lang, word));
    if (raw == null) return null;
    try {
      return WordResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  DateTime? _readCacheTimestamp(String lang, String word) {
    final ts = _storage.getString(_tsKey(lang, word));
    if (ts == null) return null;
    return DateTime.tryParse(ts);
  }

  Future<void> _writeCache(
    String lang,
    String word,
    Map<String, dynamic> json,
  ) async {
    await _storage.setString(_cacheKey(lang, word), jsonEncode(json));
    await _storage.setString(
      _tsKey(lang, word),
      DateTime.now().toIso8601String(),
    );
  }

  // ── Pending queue (offline retry) ─────────────────────────────────────────

  List<String> _pendingQueue() => _storage.getStringList(_kPendingQueue);

  Future<void> addToPendingQueue(String lang, String word) async {
    final key = '$lang:${word.trim().toLowerCase()}';
    final queue = _pendingQueue();
    if (!queue.contains(key)) {
      await _storage.setStringList(_kPendingQueue, [...queue, key]);
    }
  }

  /// Called by ConnectivityService when network is restored.
  Future<void> retryPending() async {
    final queue = List<String>.from(_pendingQueue());
    if (queue.isEmpty) return;
    final retried = <String>[];
    for (final entry in queue) {
      final parts = entry.split(':');
      if (parts.length < 2) continue;
      final lang = parts[0];
      final word = parts.sublist(1).join(':');
      final result = await lookup(lang, word);
      if (result.status == LookupStatus.found && !result.fromCache) {
        retried.add(entry);
      }
    }
    final remaining = queue.where((e) => !retried.contains(e)).toList();
    await _storage.setStringList(_kPendingQueue, remaining);
  }

  // ── Lookup ────────────────────────────────────────────────────────────────

  /// Look up [word] in [lang] ('en' or 'ur').
  ///
  /// - English words → Free Dictionary API (freedictionaryapi.com)
  /// - Urdu words    → English Wiktionary (en.wiktionary.org, ~5k Urdu entries)
  ///
  /// Returns a [LookupResult] with one of the four [LookupStatus] values.
  Future<LookupResult> lookup(String lang, String word) async {
    final trimmed = word.trim();
    if (trimmed.isEmpty) return const LookupResult(LookupStatus.notFound);

    // Check cache first — both English and Urdu use the same cache layer.
    final cached = _readCache(lang, trimmed);

    if (lang == 'ur') {
      return _lookupUrdu(trimmed, cached);
    } else {
      return _lookupEnglish(trimmed, cached);
    }
  }

  // ── English via freedictionaryapi.com ────────────────────────────────────

  Future<LookupResult> _lookupEnglish(
      String word, WordResult? cached) async {
    final uri = Uri.parse(
      '$_base/en/${Uri.encodeComponent(word)}?translations=true',
    );
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) {
        final json =
            jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        final result = WordResult.fromJson(json);
        if (result.isEmpty) {
          if (cached != null && !cached.isEmpty) {
            return LookupResult(LookupStatus.staleCache,
                data: cached,
                fromCache: true,
                cachedAt: _readCacheTimestamp('en', word));
          }
          return const LookupResult(LookupStatus.notFound);
        }
        await _writeCache('en', word, json);
        return LookupResult(LookupStatus.found, data: result);
      }
      return _staleCacheOrOffline('en', word);
    } on TimeoutException {
      return _staleCacheOrOffline('en', word);
    } catch (_) {
      return _staleCacheOrOffline('en', word);
    }
  }

  // ── Urdu via English Wiktionary ───────────────────────────────────────────

  Future<LookupResult> _lookupUrdu(String word, WordResult? cached) async {
    try {
      // 1. Try local SQLite database first (Instant & Offline)
      final localResult = await DatabaseService.lookupUrdu(word);
      if (localResult != null) {
        return LookupResult(LookupStatus.found, data: localResult);
      }

      // 2. Fallback to English Wiktionary API
      final entry = await WiktionaryService.fetchUrdu(word);
      if (entry != null) {
        final result = WordResult(word: word, entries: [entry]);
        await _writeCache('ur', word, result.toJson());
        return LookupResult(LookupStatus.found, data: result);
      }

      // 3. Try Cache
      if (cached != null && !cached.isEmpty) {
        return LookupResult(LookupStatus.staleCache,
            data: cached,
            fromCache: true,
            cachedAt: _readCacheTimestamp('ur', word));
      }
      return const LookupResult(LookupStatus.notFound);
    } on TimeoutException {
      return _staleCacheOrOffline('ur', word);
    } catch (_) {
      return _staleCacheOrOffline('ur', word);
    }
  }

  LookupResult _staleCacheOrOffline(String lang, String word) {
    final cached = _readCache(lang, word);
    if (cached != null && !cached.isEmpty) {
      return LookupResult(
        LookupStatus.staleCache,
        data: cached,
        fromCache: true,
        cachedAt: _readCacheTimestamp(lang, word),
      );
    }
    return const LookupResult(LookupStatus.offline);
  }
}
