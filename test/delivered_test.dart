import 'package:ecp/ecp.dart';
import 'package:test/test.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('Delivered Activity Tests', () {
    final activeUsers = <TestUser>[];

    TestUser createUser(int userNumber) {
      final user = TestUser.fromEnv(userNumber: userNumber);
      activeUsers.add(user);
      return user;
    }

    tearDown(() async {
      for (final user in activeUsers) {
        await user.cleanup();
      }
      activeUsers.clear();
    });

    test('single message - inbox should be empty after Delivered', () async {
      final user1 = createUser(1);
      final user2 = createUser(2);

      final device1 = await user1.addDevice();
      final device2 = await user2.addDevice();

      // Device1 sends a message to Device2
      await device1.sendTextTo(user2, "Hello!");

      // Give the server time to process
      await Future.delayed(Duration(milliseconds: 100));

      // Device2 checks inbox - should have 1 message
      var messages = await device2.getMessages();
      expect(messages.length, 1);
      final activity = messages[0].activity;
      expect(activity, isA<Create>());
      expect((activity as Create).object, isA<Note>());
      expect((activity.object as Note).content, "Hello!");

      print('First check: ${messages.length} messages');

      // Wait for Delivered to be sent and processed by server
      await Future.delayed(Duration(milliseconds: 500));

      // Device2 checks inbox again - should be empty now (Delivered ack cleared it)
      messages = await device2.getMessages();
      print('Second check: ${messages.length} messages');
      expect(
        messages.isEmpty,
        isTrue,
        reason:
            'Inbox should be empty after Delivered acknowledgment is processed',
      );
    });

    test('two messages in sequence - each cleared after Delivered', () async {
      final user1 = createUser(1);
      final user2 = createUser(2);

      final device1 = await user1.addDevice();
      final device2 = await user2.addDevice();

      // Send first message
      await device1.sendTextTo(user2, "Message 1");
      await Future.delayed(Duration(milliseconds: 100));

      // Check inbox - should have message 1
      var messages = await device2.getMessages();
      expect(messages.length, 1);
      MessageAssertions.expectNoteContent(messages, "Message 1");

      // Wait for Delivered to clear the inbox
      await Future.delayed(Duration(milliseconds: 500));
      messages = await device2.getMessages();
      expect(
        messages.isEmpty,
        isTrue,
        reason: 'Inbox should be cleared after first Delivered',
      );

      // Send second message
      await device1.sendTextTo(user2, "Message 2");
      await Future.delayed(Duration(milliseconds: 100));

      // Check inbox - should have only message 2
      messages = await device2.getMessages();
      expect(messages.length, 1);
      MessageAssertions.expectNoteContent(messages, "Message 2");

      // Wait for Delivered to clear the inbox
      await Future.delayed(Duration(milliseconds: 500));
      messages = await device2.getMessages();
      expect(
        messages.isEmpty,
        isTrue,
        reason: 'Inbox should be cleared after second Delivered',
      );
    });
  });
}
