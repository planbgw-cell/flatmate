import 'package:dio/dio.dart';

import '../../app/config/app_config.dart';

/// FastAPI 서버 연동용 Dio HTTP 클라이언트.
class DioClient {
  DioClient({AppConfig? config, Dio? dio})
      : _config = config ?? AppConfig.resolve(),
        _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: _config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: _config.isDev,
        responseBody: _config.isDev,
      ),
    );
  }

  final AppConfig _config;
  final Dio _dio;

  Dio get instance => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {Object? data}) {
    return _dio.post<T>(path, data: data);
  }
}
