import 'package:dio/dio.dart';

import '../../app/config/app_config.dart';
import '../auth/token_refresher.dart';
import '../auth/token_storage.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

/// Dio singleton used by FastAPI repositories.
class ApiClient {
  ApiClient({
    required TokenStorage tokens,
    TokenRefresher? refresher,
    AppConfig? config,
    Dio? dio,
  })  : _config = config ?? AppConfig.resolve(),
        _dio = dio ?? Dio() {
    final tokenRefresher = refresher ??
        TokenRefresher(tokens: tokens, baseUrl: _config.apiBaseUrl);
    _dio.options = BaseOptions(
      baseUrl: _config.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: 5000),
      receiveTimeout: const Duration(milliseconds: 10000),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio.interceptors.add(
      AuthInterceptor(tokens: tokens, refresher: tokenRefresher, dio: _dio),
    );
    if (_config.isDev) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  final AppConfig _config;
  final Dio _dio;

  Dio get dio => _dio;
  AppConfig get config => _config;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _guard(
      () => _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _guard(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Options? options,
  }) {
    return _guard(() => _dio.put<T>(path, data: data, options: options));
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Options? options,
  }) {
    return _guard(() => _dio.delete<T>(path, data: data, options: options));
  }

  Future<Response<T>> _guard<T>(Future<Response<T>> Function() run) async {
    try {
      return await run();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
