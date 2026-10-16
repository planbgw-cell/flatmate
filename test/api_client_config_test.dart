import 'package:flutter_test/flutter_test.dart';
import 'package:flatmate_app/app/config/app_config.dart';
import 'package:flatmate_app/core/network/api_exception.dart';
import 'package:dio/dio.dart';

void main() {
  test('AppConfig defaults to mock API in development', () {
    final config = AppConfig.resolve();
    expect(config.apiBaseUrl, contains('/api/v1'));
    expect(config.useMockApi, isTrue);
  });

  test('ApiException maps status codes to friendly messages', () {
    expect(ApiException.fromStatusCode(401).message, contains('로그인'));
    expect(ApiException.fromStatusCode(404).message, contains('찾을 수 없습니다'));
    expect(ApiException.fromStatusCode(500).message, contains('서버'));

    final timeout = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/feeds'),
        type: DioExceptionType.connectionTimeout,
      ),
    );
    expect(timeout.message, contains('지연'));

    final offline = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/feeds'),
        type: DioExceptionType.connectionError,
      ),
    );
    expect(offline.message, contains('네트워크'));
  });
}
