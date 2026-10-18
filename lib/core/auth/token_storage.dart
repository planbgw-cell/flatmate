import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Access/refresh JWT pair persisted in the platform keystore
/// (Android Keystore / iOS Keychain).
///
/// Values are cached in memory after [load] so interceptors can read them
/// synchronously on every request.
class TokenStorage extends ChangeNotifier {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'auth_access_token';
  static const _refreshKey = 'auth_refresh_token';
  static const _userIdKey = 'auth_user_id';
  static const _accessExpiresKey = 'auth_expires_at';
  static const _refreshExpiresKey = 'auth_refresh_expires_at';

  /// Refresh slightly early so in-flight requests don't race the expiry.
  static const _expirySkew = Duration(seconds: 30);

  final FlutterSecureStorage _storage;

  String? _accessToken;
  String? _refreshToken;
  String? _userId;
  DateTime? _accessExpiresAt;
  DateTime? _refreshExpiresAt;
  bool _sessionExpired = false;

  String? get accessToken => hasSession ? _accessToken : null;
  String? get refreshToken => hasSession ? _refreshToken : null;
  String? get userId => hasSession ? _userId : null;

  /// Signed in: the refresh token (or, without one, the access token) is
  /// still within its lifetime.
  bool get hasSession {
    if (_accessToken == null || _accessToken!.isEmpty) return false;
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      return _isBefore(_refreshExpiresAt);
    }
    return _isBefore(_accessExpiresAt);
  }

  /// Access token usable as-is (not expired by the local clock).
  bool get isAccessTokenFresh =>
      _accessToken != null &&
      _isBefore(_accessExpiresAt?.subtract(_expirySkew));

  /// `true` after the session was dropped because refresh failed (not logout).
  bool get sessionExpired => _sessionExpired;

  bool _isBefore(DateTime? expiry) =>
      expiry == null || DateTime.now().isBefore(expiry);

  Future<void> load() async {
    try {
      _accessToken = await _storage.read(key: _accessKey);
      _refreshToken = await _storage.read(key: _refreshKey);
      _userId = await _storage.read(key: _userIdKey);
      _accessExpiresAt = _parse(await _storage.read(key: _accessExpiresKey));
      _refreshExpiresAt = _parse(await _storage.read(key: _refreshExpiresKey));
    } catch (_) {
      // Corrupted keystore entries (e.g. after reinstall) — start signed out.
      await clear(notify: false);
    }
    if (!hasSession && _accessToken != null) {
      await clear(notify: false);
    }
  }

  Future<void> save({
    required String accessToken,
    required String userId,
    required Duration expiresIn,
    String? refreshToken,
    Duration? refreshExpiresIn,
  }) async {
    final now = DateTime.now();
    _accessToken = accessToken;
    _userId = userId;
    _accessExpiresAt = now.add(expiresIn);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _refreshToken = refreshToken;
      _refreshExpiresAt =
          refreshExpiresIn == null ? null : now.add(refreshExpiresIn);
    }
    _sessionExpired = false;
    await _write(_accessKey, _accessToken);
    await _write(_refreshKey, _refreshToken);
    await _write(_userIdKey, _userId);
    await _write(_accessExpiresKey, _accessExpiresAt?.toIso8601String());
    await _write(_refreshExpiresKey, _refreshExpiresAt?.toIso8601String());
    notifyListeners();
  }

  /// [expired] marks a forced sign-out (refresh failed) so the router can
  /// send the user to the login screen.
  Future<void> clear({bool notify = true, bool expired = false}) async {
    final hadSession = _accessToken != null;
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _accessExpiresAt = null;
    _refreshExpiresAt = null;
    _sessionExpired = expired && hadSession;
    try {
      for (final key in [
        _accessKey,
        _refreshKey,
        _userIdKey,
        _accessExpiresKey,
        _refreshExpiresKey,
      ]) {
        await _storage.delete(key: key);
      }
    } catch (_) {}
    if (notify && hadSession) notifyListeners();
  }

  /// Called once the login screen has surfaced the forced sign-out.
  void acknowledgeSessionExpired() => _sessionExpired = false;

  /// Simulates a server-side revoked/expired access token (QA only).
  @visibleForTesting
  void debugCorruptAccessToken() {
    _accessToken = 'expired.${_accessToken ?? ''}';
  }

  Future<void> _write(String key, String? value) async {
    if (value == null) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  static DateTime? _parse(String? raw) =>
      raw == null ? null : DateTime.tryParse(raw);
}
