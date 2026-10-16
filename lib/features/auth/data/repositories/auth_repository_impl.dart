import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;
  User? _cached;

  @override
  Future<User> login({required String email, required String password}) async {
    final model = await _remote.login(email: email, password: password);
    _cached = model.toEntity();
    return _cached!;
  }

  @override
  Future<void> logout() async {
    _cached = null;
  }

  @override
  Future<User?> currentUser() async => _cached;
}
