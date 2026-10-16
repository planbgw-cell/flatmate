import 'package:shared_preferences/shared_preferences.dart';

/// Hive/Isar 도입 전 SharedPreferences 기반 로컬 저장소.
class LocalStorage {
  LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  Future<void> writeString(String key, String value) =>
      _prefs.setString(key, value);

  String? readString(String key) => _prefs.getString(key);

  Future<void> remove(String key) => _prefs.remove(key);
}
