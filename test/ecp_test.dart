import 'package:ecp/ecp.dart';
import 'package:test/test.dart';
import 'dart:io';

import 'mock_token_storage.dart';

void main() {
  group('ECPClient', () {
    late ECPClient client;
    late MockTokenStorage storage;
    final baseUrl = Uri.parse('http://localhost:3000');
    const deviceName = 'test-device';

    setUp(() {
      storage = MockTokenStorage();
      client = ECPClient(
        storage: storage,
        baseUrl: baseUrl,
        deviceName: deviceName,
      );
    });

    test('login success', () async {
      final username = Platform.environment['TEST_USER_EMAIL'];
      final password = Platform.environment['TEST_USER_PASSWORD'];
      if (username == null || password == null) {
        throw Exception(
          'TEST_USER_EMAIL and TEST_USER_PASSWORD must be set as environment variables',
        );
      }
      try {
        await client.login(email: username, password: password);
      } catch (e) {
        print('Login failed with exception: $e');
        rethrow;
      }
      expect(client.isAuthenticated, isTrue);
      expect(storage.getAccessToken(), isNotNull);
    });

    test('login failure', () async {
      expectLater(
        client.login(email: 'test@example.com', password: 'wrong_password'),
        throwsA(isA<AuthException>()),
      );
    });

    test('logout', () async {
      final username = Platform.environment['TEST_USER_EMAIL'];
      final password = Platform.environment['TEST_USER_PASSWORD'];
      if (username == null || password == null) {
        throw Exception(
          'TEST_USER_EMAIL and TEST_USER_PASSWORD must be set as environment variables',
        );
      }
      await client.login(email: username, password: password);
      await client.logout();
      expect(client.isAuthenticated, isFalse);
      expect(storage.getAccessToken(), completion(isNull));
    });

    test('token refresh', () async {
      final username = Platform.environment['TEST_USER_EMAIL'];
      final password = Platform.environment['TEST_USER_PASSWORD'];
      if (username == null || password == null) {
        throw Exception(
          'TEST_USER_EMAIL and TEST_USER_PASSWORD must be set as environment variables',
        );
      }
      await client.login(email: username, password: password);
      final initialToken = await storage.getAccessToken();

      // Wait a second to ensure the new token will have a different timestamp
      await Future.delayed(const Duration(seconds: 2));

      // Manually expire the token for testing purposes
      // This is a bit of a hack, but we need to get the auth manager into a state
      // where it has an expired token.
      client.authManager.currentTokens = TokenPair(
        accessToken: 'expired',
        refreshToken: client.authManager.currentTokens!.refreshToken,
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );

      // This should trigger a refresh
      final newAccessToken = await client.authManager.getValidAccessToken();
      expect(newAccessToken, isNot(initialToken));
      expect(newAccessToken, isNot('expired'));
    }, timeout: Timeout(Duration(seconds: 10)));
  });
}
