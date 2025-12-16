import 'dart:io';
import 'package:ecp/ecp.dart';
import 'package:test/test.dart';

import 'mock_token_storage.dart';

void main() {
  group('Integration Tests', () {
    late ECPClient client1;
    late ECPClient client2;
    late MockTokenStorage storage1;
    late MockTokenStorage storage2;
    late String email1;
    late String email2;
    late String password1;
    late String password2;
    final baseUrl = Uri.parse('http://localhost:3000');

    setUp(() {
      storage1 = MockTokenStorage();
      client1 = ECPClient(storage: storage1, deviceName: 'test-device-1');
      storage2 = MockTokenStorage();
      client2 = ECPClient(storage: storage2, deviceName: 'test-device-2');
      email1 =
          Platform.environment['USER1_EMAIL'] ??
          (throw StateError('Environment variable USER1_EMAIL not set.'));
      password1 =
          Platform.environment['USER1_PASSWORD'] ??
          (throw StateError('Environment variable USER2_PASSWORD not set.'));
      email2 =
          Platform.environment['USER2_EMAIL'] ??
          (throw StateError('Environment variable USER1_EMAIL not set.'));
      password2 =
          Platform.environment['USER2_PASSWORD'] ??
          (throw StateError('Environment variable USER2_PASSWORD not set.'));
    });
    test('login and logout', () async {
      await client1.login(email: email1, password: password1, url: baseUrl);
      expect(client1.isAuthenticated, isTrue);
      print("logged in as ${client1.me.toJson()}");
      await client1.logout();
      expect(client1.isAuthenticated, isFalse);
    });

    test('login and logout with two clients, exchanging a message', () async {
      // Login client 1
      await client1.login(email: email1, password: password1, url: baseUrl);
      expect(client1.isAuthenticated, isTrue);

      // Login client 2
      await client2.login(email: email2, password: password2, url: baseUrl);
      expect(client2.isAuthenticated, isTrue);

      await client1.sendMessage(person: client2.me, message: "Hello!");
      final messages = await client2.getMessages();
      expect(messages.first.content, "Hello!");

      // Logout client 1
      await client1.logout();
      expect(client1.isAuthenticated, isFalse);

      // Logout client 2
      await client2.logout();
      expect(client2.isAuthenticated, isFalse);
    });
  });
}
