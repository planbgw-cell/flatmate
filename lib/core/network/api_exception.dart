import 'package:dio/dio.dart';

/// Maps Dio / HTTP failures to user-facing Korean messages.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: '서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해 주세요.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          message: '네트워크 연결을 확인해 주세요.',
        );
      case DioExceptionType.cancel:
        return const ApiException(message: '요청이 취소되었습니다.');
      case DioExceptionType.badCertificate:
        return const ApiException(message: '보안 인증서에 문제가 있습니다.');
      case DioExceptionType.badResponse:
        return ApiException.fromStatusCode(
          error.response?.statusCode,
          detail: _extractDetail(error.response?.data),
        );
      case DioExceptionType.unknown:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          message: '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.',
        );
    }
  }

  factory ApiException.fromStatusCode(int? statusCode, {String? detail}) {
    final fallback = detail?.trim();
    return switch (statusCode) {
      400 => ApiException(
          message: fallback?.isNotEmpty == true
              ? fallback!
              : '잘못된 요청입니다. 입력 내용을 확인해 주세요.',
          statusCode: 400,
        ),
      401 => const ApiException(
          message: '로그인이 필요하거나 세션이 만료되었습니다.',
          statusCode: 401,
        ),
      403 => const ApiException(
          message: '이 작업을 수행할 권한이 없습니다.',
          statusCode: 403,
        ),
      404 => const ApiException(
          message: '요청한 정보를 찾을 수 없습니다.',
          statusCode: 404,
        ),
      409 => ApiException(
          message: fallback?.isNotEmpty == true
              ? fallback!
              : '이미 처리된 요청이거나 충돌이 발생했습니다.',
          statusCode: 409,
        ),
      422 => ApiException(
          message: fallback?.isNotEmpty == true
              ? fallback!
              : '입력값 검증에 실패했습니다.',
          statusCode: 422,
        ),
      500 || 502 || 503 => const ApiException(
          message: '서버에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해 주세요.',
          statusCode: 500,
        ),
      _ => ApiException(
          message: fallback?.isNotEmpty == true
              ? fallback!
              : '요청 처리 중 오류가 발생했습니다. (${statusCode ?? 'unknown'})',
          statusCode: statusCode,
        ),
    };
  }

  static String? _extractDetail(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) {
          return first['msg'].toString();
        }
        return first.toString();
      }
      final message = data['message'];
      if (message is String) return message;
    }
    return null;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
