import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/word_ref.dart';
import '../services/storage_service.dart';

/// Manages recent search history (up to 30 entries).
class RecentsState extends ChangeNotifier {
  RecentsState(this._storage) {
    _load();
  }

  final StorageService _storage;
  static const _kRecents = 'recents';
  static const _maxRecents = 30;

  List<WordRef> _recents = [];
  List<WordRef> get recents => List.unmodifiable(_recents);

  void _load() {
    _recents = _storage
        .getStringList(_kRecents)
        .map((s) => WordRef.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  void addRecent(WordRef ref) {
    _recents.removeWhere((r) => r.key == ref.key);
    _recents.insert(0, ref);
    if (_recents.length > _maxRecents) {
      _recents = _recents.sublist(0, _maxRecents);
    }
    _storage.setStringList(
        _kRecents, _recents.map((r) => jsonEncode(r.toJson())).toList());
    notifyListeners();
  }

  void clearRecents() {
    _recents = [];
    _storage.remove(_kRecents);
    notifyListeners();
  }
}
