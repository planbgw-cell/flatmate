import 'package:dio/dio.dart';

import '../auth/token_refresher.dart';
import '../auth/token_storage.dart';

/// Injects `Authorization: Bearer <access>`; on 401 refreshes the token
/// once and replays the request.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._tokens,
    required this._refresher,
    required this._dio,
  });

  static const _retriedKey = 'auth_retried';

  /// Credential endpoints never carry or refresh a JWT.
  static const _publicAuthPaths = [
    '/auth/login',
    '/auth/signup',
    '/auth/refresh',
    '/auth/token',
  ];

  final TokenStorage _tokens;
  final TokenRefresher _refresher;
  final Dio _dio;

  bool _isPublicAuth(RequestOptions o) =>
      _publicAuthPaths.any((p) => o.path.endsWith(p));

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublicAuth(options) && _tokens.hasSession) {
      if (!_tokens.isAccessTokenFresh) {
        await _refresher.refresh();
      }
      final token = _tokens.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final sent = request.headers['Authorization']?.toString();
    final canRetry = err.response?.statusCode == 401 &&
        sent != null &&
        request.extra[_retriedKey] != true &&
        !_isPublicAuth(request);
    if (!canRetry) return handler.next(err);

    final refreshed = await _refresher.refresh(
      staleAccessToken: sent.replaceFirst('Bearer ', ''),
    );
    final token = _tokens.accessToken;
    if (!refreshed || token == null) return handler.next(err);

    request
      ..headers['Authorization'] = 'Bearer $token'
      ..extra[_retriedKey] = true;
    try {
      handler.resolve(await _dio.fetch<dynamic>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
