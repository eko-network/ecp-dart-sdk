import 'dart:io';
import 'package:ecp/auth.dart';
import 'package:ecp/ecp.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'mock_auth_storage.dart';
import 'mock_token_storage.dart';

void main() {
  group('Integration Tests', () {
    late EcpClient client1;
    late EcpClient client2;
    late MockTokenStorage storage1;
    late MockTokenStorage storage2;
    late String email1;
    late String email2;
    late AuthStorage authStore1;
    late AuthStorage authStore2;
    late String password1;
    late String password2;
    late Auth auth1;
    late Auth auth2;
    final baseUrl = Uri.parse('http://localhost:3000');
    final _uuid = Uuid();

    setUp(() {
      storage1 = MockTokenStorage();
      storage2 = MockTokenStorage();
      authStore1 = InMemoryAuthStorage();
      authStore2 = InMemoryAuthStorage();
      auth1 = Auth(
        authStore1,
        ecpStorage: storage1,
        deviceName: 'test-device-1',
      );
      auth2 = Auth(
        authStore2,
        ecpStorage: storage2,
        deviceName: 'test-device-2',
      );
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
      await auth1.login(email: email1, password: password1, url: baseUrl);
      expect(auth1.isAuthenticated, isTrue);
      client1 = EcpClient(
        storage: storage1,
        did: auth1.info!.did,
        me: auth1.info!.actor,
        client: auth1.client,
      );
      print("logged in as ${client1.me.toJson()}");
      await auth1.logout();
      expect(auth1.isAuthenticated, isFalse);
    });
    test('login and logout, refresh', () async {
      await auth1.login(email: email1, password: password1, url: baseUrl);
      expect(auth1.isAuthenticated, isTrue);
      client1 = EcpClient(
        storage: storage1,
        did: auth1.info!.did,
        me: auth1.info!.actor,
        client: auth1.client,
      );
      await auth1.refreshTokens();
      await auth1.refreshTokens();
      await auth1.refreshTokens();
      expect(auth1.isAuthenticated, isTrue);
      print("logged in as ${client1.me.toJson()}");
      await auth1.logout();
      expect(auth1.isAuthenticated, isFalse);
    });
    test('login and logout, webfinger, actor', () async {
      await auth1.login(email: email1, password: password1, url: baseUrl);
      expect(auth1.isAuthenticated, isTrue);
      client1 = EcpClient(
        storage: storage1,
        did: auth1.info!.did,
        me: auth1.info!.actor,
        client: auth1.client,
      );

      final id = await client1.webFinger(client1.me.preferredUsername);

      expect(id, client1.me.id);

      final person = await client1.getActorWithWebfinger(
        client1.me.preferredUsername,
      );

      expect(person.preferredUsername, client1.me.preferredUsername);

      print("logged in as ${client1.me.toJson()}");
      await auth1.logout();
      expect(auth1.isAuthenticated, isFalse);
    });

    test('login and logout with two clients, exchanging a message', () async {
      // Login client 1
      await auth1.login(email: email1, password: password1, url: baseUrl);
      expect(auth1.isAuthenticated, isTrue);
      client1 = EcpClient(
        storage: storage1,
        did: auth1.info!.did,
        me: auth1.info!.actor,
        client: auth1.client,
      );

      // Login client 2
      await auth2.login(email: email2, password: password2, url: baseUrl);
      expect(auth2.isAuthenticated, isTrue);
      client2 = EcpClient(
        storage: storage2,
        did: auth2.info!.did,
        me: auth2.info!.actor,
        client: auth2.client,
      );

      await client1.sendMessage(
        person: client2.me,
        message: Create(
          base: ActivityBase(id: _uuid.v4obj()),
          object: Note(
            base: ObjectBase(id: _uuid.v4obj()),
            content: "Hello!",
          ),
        ),
      );
      final messages = await client2.getMessages();
      expect(
        ((messages.first.activity as Create).object as Note).content,
        "Hello!",
      );

      await client1.sendMessage(
        person: client2.me,
        message: Create(
          base: ActivityBase(id: _uuid.v4obj()),
          object: Note(
            base: ObjectBase(id: _uuid.v4obj()),
            content: "Hello2",
          ),
        ),
      );
      final messages2 = await client2.getMessages();
      expect(
        ((messages2.first.activity as Create).object as Note).content,
        "Hello2",
      );
      await client2.sendMessage(
        person: client1.me,
        message: Create(
          base: ActivityBase(id: _uuid.v4obj()),
          object: Note(
            base: ObjectBase(id: _uuid.v4obj()),
            content: "reply",
          ),
        ),
      );
      final messages_reply = await client1.getMessages();
      expect(
        ((messages_reply.first.activity as Create).object as Note).content,
        "reply",
      );
      // Logout client 1
      await auth1.logout();
      expect(auth1.isAuthenticated, isFalse);

      // Logout client 2
      await auth2.logout();
      expect(auth2.isAuthenticated, isFalse);
    });
  });
}
