import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:flatmate_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  ProviderContainer makeContainer(TokenStorage tokens) {
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokens),
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('signup → login persists the JWT in secure storage', () async {
    final tokens = TokenStorage();
    final container = makeContainer(tokens);
    expect(await container.read(authProvider.future), isNull);

    final user = await container.read(authProvider.notifier).signup(
          email: 'new@example.com',
          password: 'Flatmate123!',
          nickname: '새이웃',
        );

    expect(user.nickname, '새이웃');
    expect(tokens.hasSession, isTrue);
    expect(container.read(currentUserIdProvider), user.id);

    final reloaded = TokenStorage();
    await reloaded.load();
    expect(reloaded.accessToken, tokens.accessToken);
    expect(reloaded.userId, user.id);
  });

  test('clearing the session (401 / logout) signs the user out', () async {
    final tokens = TokenStorage();
    final container = makeContainer(tokens);
    await container.read(authProvider.future);
    await container
        .read(authProvider.notifier)
        .login(email: 'a@example.com', password: 'whatever1');
    expect(container.read(authProvider).value, isNotNull);

    await tokens.clear();
    expect(container.read(authProvider).value, isNull);
  });
}
