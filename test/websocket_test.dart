import 'package:ecp/auth.dart';
import 'package:ecp/ecp.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'helpers/test_helpers.dart';
import 'storage/mock_auth_storage.dart';
import 'storage/mock_token_storage.dart';

void main() {
  group('WebSocket Tests', () {
    final activeUsers = <TestUser>[];
    final _uuid = Uuid();

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

    test('message stream - basic send and receive', () async {
      final user1 = createUser(1);
      final user2 = createUser(2);

      final device1 = await user1.addDevice();
      final device2 = await user2.addDevice();

      // Client 1 sends a message
      final testContent = "Test message ${_uuid.v4()}";
      await device1.client.sendMessage(
        person: device2.client.me,
        message: MessageFactory.note(testContent, device2.client.me.id),
      );

      // Client 2 receives the message
      final messages = await device2.getMessages();
      expect(messages.isNotEmpty, isTrue);
      final found = messages.any(
        (m) => ((m.activity as Create).object as Note).content == testContent,
      );
      expect(found, isTrue);
    });

    test('message stream - with pause', () async {
      final user1 = createUser(1);
      final user2 = createUser(2);

      final device1 = await user1.addDevice();
      final device2 = await user2.addDevice();

      // Client 1 sends first message
      final testContent1 = "Message before pause ${_uuid.v4()}";
      await device1.client.sendMessage(
        person: device2.client.me,
        message: MessageFactory.note(testContent1, device2.client.me.id),
      );

      // Verify message 1 can be received
      var messages = await device2.getMessages();
      expect(messages.isNotEmpty, isTrue);
      var found = messages.any(
        (m) => ((m.activity as Create).object as Note).content == testContent1,
      );
      expect(found, isTrue);

      // Create a manual polling stream with pause capability
      var isPaused = false;
      final receivedAfterResume = <String>[];

      // Send message while "paused" (not polling)
      isPaused = true;
      final testContent2 = "Message during pause ${_uuid.v4()}";
      await device1.client.sendMessage(
        person: device2.client.me,
        message: MessageFactory.note(testContent2, device2.client.me.id),
      );

      // Resume - now check for messages
      isPaused = false;
      messages = await device2.getMessages();
      for (var msg in messages) {
        final note = (msg.activity as Create).object as Note;
        if (note.content != null) {
          receivedAfterResume.add(note.content!);
        }
      }

      // Verify message sent during pause was received after resume
      expect(receivedAfterResume.contains(testContent2), isTrue);

      // Send another message after resume
      final testContent3 = "Message after resume ${_uuid.v4()}";
      await device1.client.sendMessage(
        person: device2.client.me,
        message: MessageFactory.note(testContent3, device2.client.me.id),
      );

      // Get messages again
      messages = await device2.getMessages();
      found = messages.any(
        (m) => ((m.activity as Create).object as Note).content == testContent3,
      );
      expect(found, isTrue);
    });

    test('message stream - fails if falls back to polling', () async {
      final user1 = createUser(1);
      final user2 = createUser(2);

      final device1 = await user1.addDevice();

      final device2Storage = MockTokenStorage();
      final device2AuthStorage = InMemoryAuthStorage();
      final device2Auth = Auth(
        device2AuthStorage,
        ecpStorage: device2Storage,
        deviceName: TestConfig.deviceName(2),
      );

      await device2Auth.login(
        email: user2.email,
        password: user2.password,
        url: TestConfig.baseUrl,
      );

      final client2 = await EcpClient.build(
        storage: device2Storage,
        did: device2Auth.info!.did,
        me: device2Auth.info!.actor,
        client: device2Auth.client,
        tokenGetter: () async {
          return await device2Auth.getValidAccessToken();
        },
      );

      // Create stream controller for client 2
      final streamController = MessageStreamController(
        client: client2,
        config: MessageStreamConfig(
          preferWebSocket: true,
          pollingInterval: Duration(seconds: 1),
        ),
      );

      final streamSubscription = streamController.getMessagesStream().listen(
        (messages) {},
      );

      await Future.delayed(Duration(seconds: 2));

      final hasWebSocket = streamController.isUsingWebSocket;

      final testContent = "WebSocket test message ${_uuid.v4()}";
      await device1.client.sendMessage(
        person: client2.me,
        message: MessageFactory.note(testContent, client2.me.id),
      );

      await Future.delayed(Duration(seconds: 2));

      // Verify WebSocket connection is active (not polling)
      expect(
        hasWebSocket,
        isTrue,
        reason: 'Stream should be using WebSocket, not polling',
      );

      // Verify that polling timer is not active
      expect(
        streamController.isUsingPolling,
        isFalse,
        reason: 'Polling timer should not be active when using WebSocket',
      );

      await streamSubscription.cancel();
      streamController.dispose();
      await device2Auth.logout();
    });
  });
}
