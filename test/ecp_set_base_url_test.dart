import 'package:ecp/ecp.dart';
import 'package:test/test.dart';

import 'mock_token_storage.dart';

void main() {
  group('ECPClient.setBaseUrl', () {
    late MockTokenStorage storage;
    late ECPClient client;

    setUp(() {
      storage = MockTokenStorage();
      client = ECPClient(
        storage: storage,
        baseUrl: Uri.parse('http://initial.com'),
        deviceName: 'test_device',
      );
    });

    test('should update baseUrl when not authenticated', () {
      client.setBaseUrl(Uri.parse('http://new.com'));
      expect(client.baseUrl, 'http://new.com');
      expect(client.authManager.baseUrl, 'http://new.com');
    });

    test('should throw StateError when authenticated', () async {
      client.authManager.currentTokens = TokenPair(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(client.isAuthenticated, isTrue);
      expect(
        () => client.setBaseUrl(Uri.parse('http://another.com')),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Cannot change base URL while a user is logged in'),
          ),
        ),
      );
    });
  });
}
