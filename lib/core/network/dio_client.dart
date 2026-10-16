import 'package:dio/dio.dart';

import 'api_client.dart';

/// Backward-compatible wrapper around [ApiClient].
class DioClient {
  DioClient(this._api);

  final ApiClient _api;

  Dio get instance => _api.dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _api.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {Object? data}) {
    return _api.post<T>(path, data: data);
  }
}
