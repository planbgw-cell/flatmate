import '../../../../core/network/api_exception.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// In-memory auth for `USE_MOCK_API=true` (any registered email/password).
class MockAuthRepository implements AuthRepository {
  final Map<String, ({String password, AuthUser user})> _accounts = {};
  AuthUser? _current;

  @override
  Future<AuthUser> signup({
    required String email,
    required String password,
    required String nickname,
    int? locationId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (_accounts.containsKey(email)) {
      throw const ApiException(message: '이미 가입된 이메일입니다.', statusCode: 409);
    }
    final user = AuthUser(
      id: 'me',
      email: email,
      nickname: nickname,
      createdAt: DateTime.now(),
    );
    _accounts[email] = (password: password, user: user);
    return user;
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final account = _accounts[email];
    final user = account == null
        ? AuthUser(id: 'me', email: email, nickname: email.split('@').first)
        : account.password == password
            ? account.user
            : null;
    if (user == null) {
      throw const ApiException(
        message: '이메일 또는 비밀번호가 올바르지 않습니다.',
        statusCode: 401,
      );
    }
    _current = user;
    return AuthSession(
      accessToken: 'mock-token-${DateTime.now().millisecondsSinceEpoch}',
      expiresIn: const Duration(hours: 1),
      refreshToken: 'mock-refresh-${DateTime.now().millisecondsSinceEpoch}',
      refreshExpiresIn: const Duration(days: 14),
      user: user,
    );
  }

  @override
  Future<AuthUser> getMe() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _current ??
        const AuthUser(id: 'me', email: 'guest@flatmate.app', nickname: '게스트');
  }

  /// Mock catalog dongs have no server ids, so the 대표 동네 stays local.
  @override
  Future<AuthUser> updateLocation(int locationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return getMe();
  }
}
