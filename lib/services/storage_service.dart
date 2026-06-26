import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences for all local persistence.
class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  List<String> getStringList(String key) =>
      _prefs.getStringList(key) ?? const [];

  Future<void> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);
}
