import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/word_ref.dart';
import '../services/storage_service.dart';

/// Manages the user's saved favorite words.
class FavoritesState extends ChangeNotifier {
  FavoritesState(this._storage) {
    _load();
  }

  final StorageService _storage;
  static const _kFavorites = 'favorites';

  List<WordRef> _favorites = [];
  List<WordRef> get favorites => List.unmodifiable(_favorites);

  void _load() {
    _favorites = _storage
        .getStringList(_kFavorites)
        .map((s) => WordRef.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  bool isFavorite(WordRef ref) => _favorites.any((f) => f.key == ref.key);

  void toggleFavorite(WordRef ref) {
    if (isFavorite(ref)) {
      _favorites.removeWhere((f) => f.key == ref.key);
    } else {
      _favorites.insert(0, ref);
    }
    _persist();
    notifyListeners();
  }

  void removeFavorite(WordRef ref) {
    _favorites.removeWhere((f) => f.key == ref.key);
    _persist();
    notifyListeners();
  }

  void _persist() => _storage.setStringList(
      _kFavorites, _favorites.map((f) => jsonEncode(f.toJson())).toList());
}
