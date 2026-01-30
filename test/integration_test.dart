import 'package:ecp/ecp.dart';
import 'package:test/test.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('Integration Tests', () {
    final activeUsers = <TestUser>[];

    // Helper to create and track users for cleanup
    TestUser createUser(int userNumber) {
      final user = TestUser.fromEnv(userNumber: userNumber);
      activeUsers.add(user);
      return user;
    }

    setUp(() {});

    tearDown(() async {
      for (final user in activeUsers) {
        await user.cleanup();
      }
      activeUsers.clear();
    });

    test('login and logout', () async {
      final user1 = createUser(1);
      final device1 = await user1.addDevice();

      expect(device1.auth.isAuthenticated, isTrue);
      print("logged in as ${device1.client.me.toJson()}");

      await device1.cleanup();
      expect(device1.auth.isAuthenticated, isFalse);
    });

    test('login and logout, Capabilities', () async {
      final user1 = createUser(1);
      final device1 = await user1.addDevice();

      expect(device1.client.capabilities.protocol, "eko-chat");
      print("logged in as ${device1.client.me.toJson()}");
    });

    test('login and logout, refresh', () async {
      final user1 = createUser(1);
      final device1 = await user1.addDevice();

      await device1.auth.refreshTokens();
      await device1.auth.refreshTokens();
      await device1.auth.refreshTokens();
      expect(device1.auth.isAuthenticated, isTrue);
      print("logged in as ${device1.client.me.toJson()}");
    });

    test('login and logout, webfinger, actor', () async {
      final user1 = createUser(1);
      final device1 = await user1.addDevice();

      final id = await device1.client.webFinger(
        device1.client.me.preferredUsername,
      );

      expect(id, device1.client.me.id);

      final person = await device1.client.getActorWithWebfinger(
        device1.client.me.preferredUsername,
      );

      expect(person.preferredUsername, device1.client.me.preferredUsername);

      print("logged in as ${device1.client.me.toJson()}");
    });

    test('two users exchange messages', () async {
      final user1 = createUser(1);
      final user2 = createUser(2);

      final device1 = await user1.addDevice();
      final device2 = await user2.addDevice();

      await device1.sendTextTo(user2, "Hello!");
      await device2.expectMessage("Hello!");

      await device1.sendTextTo(user2, "Hello2");
      await device2.expectMessage("Hello2");

      await device2.sendTextTo(user1, "reply");
      await device1.expectMessage("reply");
    });

    test('user sends message to self (multi-device)', () async {
      final user1 = createUser(1);

      final device1 = await user1.addDevice();
      final device2 = await user1.addDevice();

      await device1.sendTextTo(user1, "Hello!");
      await device2.expectMessage("Hello!");

      await device1.sendTextTo(user1, "Hello2");
      await device2.expectMessage("Hello2");

      await device2.sendTextTo(user1, "reply");
      await device1.expectMessage("reply");
    });

    test('message sync across devices', () async {
      final user1 = createUser(1);
      final user2 = createUser(2);

      final device1A = await user1.addDevice();
      final device1B = await user1.addDevice();
      final device2 = await user2.addDevice();

      const messageContent = "Sync Check";
      await device1A.sendTextTo(user2, messageContent);

      // Verify User 2 received it
      await device2.expectMessage(messageContent);

      // Verify User 1's other device received it
      final messages = await device1B.getMessages();
      MessageAssertions.expectNoteContent(messages, messageContent);

      // Verify it is addressed to User 2 on Device 1B
      final activity = messages[0].activity;
      expect(activity, isA<Create>());
      expect((activity as Create).base.to, device2.client.me.id);
    });
  });
}
