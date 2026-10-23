import 'package:shared_preferences/shared_preferences.dart';

/// 최근 검색어 (device-wide, newest first).
class SearchHistoryRepository {
  SearchHistoryRepository(this._prefs);

  final SharedPreferences _prefs;

  static const storageKey = 'search.recent';
  static const maxTerms = 10;

  List<String> getRecentSearches() {
    final terms = _prefs.getStringList(storageKey) ?? const [];
    return terms.take(maxTerms).toList();
  }

  /// Trims [term]; an existing copy moves to the front. Blank terms are
  /// ignored.
  Future<List<String>> addSearchTerm(String term) async {
    final value = term.trim();
    if (value.isEmpty) return getRecentSearches();
    final next = [
      value,
      ...getRecentSearches().where((e) => e != value),
    ].take(maxTerms).toList();
    await _prefs.setStringList(storageKey, next);
    return next;
  }

  Future<List<String>> removeSearchTerm(String term) async {
    final next = getRecentSearches().where((e) => e != term).toList();
    await _prefs.setStringList(storageKey, next);
    return next;
  }

  Future<void> clearAllSearchTerms() => _prefs.remove(storageKey);
}
