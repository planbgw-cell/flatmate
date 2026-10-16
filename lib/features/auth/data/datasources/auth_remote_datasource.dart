import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return UserModel.fromJson(response.data ?? const {});
  }
}

/// 서버 연동 전 로컬 개발용 스텁.
class AuthRemoteDataSourceStub implements AuthRemoteDataSource {
  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return UserModel(
      id: 'local-user',
      email: email,
      nickname: email.split('@').first,
    );
  }
}
