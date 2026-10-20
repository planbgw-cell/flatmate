import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../mappers/auth_mapper.dart';

/// FastAPI auth repository (`/auth/...`).
class DioAuthRepository implements AuthRepository {
  DioAuthRepository(this._api);

  final ApiClient _api;

  @override
  Future<AuthUser> signup({
    required String email,
    required String password,
    required String nickname,
    int? locationId,
  }) async {
    try {
      final response = await _api.post<dynamic>(
        '/auth/signup',
        data: {
          'email': email,
          'password': password,
          'nickname': nickname,
          'location_id': ?locationId,
        },
      );
      return authUserFromJson(_asMap(response.data));
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        throw const ApiException(message: '이미 가입된 이메일입니다.', statusCode: 409);
      }
      rethrow;
    }
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post<dynamic>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final session = authSessionFromJson(_asMap(response.data));
      if (session.accessToken.isEmpty) {
        throw const ApiException(message: '로그인 응답에 토큰이 없습니다.');
      }
      return session;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw const ApiException(
          message: '이메일 또는 비밀번호가 올바르지 않습니다.',
          statusCode: 401,
        );
      }
      rethrow;
    }
  }

  @override
  Future<AuthUser> getMe() async {
    final response = await _api.get<dynamic>('/auth/me');
    return authUserFromJson(_asMap(response.data));
  }

  @override
  Future<AuthUser> updateLocation(int locationId) async {
    final response = await _api.patch<dynamic>(
      '/auth/location',
      data: {'location_id': locationId},
    );
    return authUserFromJson(_asMap(response.data));
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException(message: '인증 응답 형식이 올바르지 않습니다.');
  }
}
