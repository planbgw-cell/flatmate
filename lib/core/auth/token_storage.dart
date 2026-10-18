import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT session persisted in the platform keystore (Android Keystore / iOS Keychain).
///
/// Values are cached in memory after [load] so [AuthInterceptor] can read them
/// synchronously on every request.
class TokenStorage extends ChangeNotifier {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_access_token';
  static const _userIdKey = 'auth_user_id';
  static const _expiresAtKey = 'auth_expires_at';

  final FlutterSecureStorage _storage;

  String? _accessToken;
  String? _userId;
  DateTime? _expiresAt;

  String? get accessToken => hasValidToken ? _accessToken : null;
  String? get userId => hasValidToken ? _userId : null;
  DateTime? get expiresAt => _expiresAt;

  bool get hasValidToken {
    final token = _accessToken;
    if (token == null || token.isEmpty) return false;
    final expiry = _expiresAt;
    return expiry == null || DateTime.now().isBefore(expiry);
  }

  Future<void> load() async {
    try {
      _accessToken = await _storage.read(key: _tokenKey);
      _userId = await _storage.read(key: _userIdKey);
      final rawExpiry = await _storage.read(key: _expiresAtKey);
      _expiresAt = rawExpiry == null ? null : DateTime.tryParse(rawExpiry);
    } catch (_) {
      // Corrupted keystore entries (e.g. after reinstall) — start signed out.
      await clear(notify: false);
    }
    if (!hasValidToken && _accessToken != null) {
      await clear(notify: false);
    }
  }

  Future<void> save({
    required String accessToken,
    required String userId,
    required Duration expiresIn,
  }) async {
    _accessToken = accessToken;
    _userId = userId;
    _expiresAt = DateTime.now().add(expiresIn);
    await _storage.write(key: _tokenKey, value: accessToken);
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(
      key: _expiresAtKey,
      value: _expiresAt!.toIso8601String(),
    );
    notifyListeners();
  }

  Future<void> clear({bool notify = true}) async {
    final hadSession = _accessToken != null;
    _accessToken = null;
    _userId = null;
    _expiresAt = null;
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _expiresAtKey);
    } catch (_) {}
    if (notify && hadSession) notifyListeners();
  }
}
