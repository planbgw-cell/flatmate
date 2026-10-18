import 'package:dio/dio.dart';

import 'token_storage.dart';

/// Exchanges the stored refresh token for a new access token
/// (`POST /auth/refresh`). Concurrent callers share one in-flight request.
class TokenRefresher {
  TokenRefresher({
    required this._tokens,
    required String baseUrl,
    Dio? dio,
  })  : // Bare client: must not pass through AuthInterceptor (no recursion).
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  final TokenStorage _tokens;
  final Dio _dio;
  Future<bool>? _inFlight;

  Dio get dio => _dio;

  /// Returns `true` when a fresh access token is stored.
  ///
  /// [staleAccessToken] is the token a failed request used; if another caller
  /// already rotated it, no new refresh is issued.
  Future<bool> refresh({String? staleAccessToken}) {
    final current = _tokens.accessToken;
    if (staleAccessToken != null &&
        current != null &&
        current != staleAccessToken &&
        _tokens.isAccessTokenFresh) {
      return Future.value(true);
    }
    return _inFlight ??= _refresh().whenComplete(() => _inFlight = null);
  }

  Future<bool> _refresh() async {
    final refreshToken = _tokens.refreshToken;
    if (refreshToken == null) {
      await _tokens.clear(expired: true);
      return false;
    }
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = res.data ?? const {};
      final access = data['access_token']?.toString();
      if (access == null || access.isEmpty) return false;
      final user = data['user'];
      await _tokens.save(
        accessToken: access,
        refreshToken: data['refresh_token']?.toString() ?? refreshToken,
        userId: (user is Map ? user['id']?.toString() : null) ??
            _tokens.userId ??
            '',
        expiresIn: Duration(
          seconds: (data['expires_in'] as num?)?.toInt() ?? 3600,
        ),
        refreshExpiresIn: (data['refresh_expires_in'] as num?) == null
            ? null
            : Duration(seconds: (data['refresh_expires_in'] as num).toInt()),
      );
      return true;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // Rejected refresh token → session is over. Network errors keep it.
      if (status == 401 || status == 403 || status == 422) {
        await _tokens.clear(expired: true);
      }
      return false;
    }
  }
}
