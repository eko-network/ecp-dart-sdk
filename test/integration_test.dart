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
    test('login and logout, Capabilities', () async {
      await auth1.login(email: email1, password: password1, url: baseUrl);
      expect(auth1.isAuthenticated, isTrue);
      client1 = EcpClient(
        storage: storage1,
        did: auth1.info!.did,
        me: auth1.info!.actor,
        client: auth1.client,
      );
      final capabilities = await client1.getCapabilites();
      expect(capabilities.protocol, "eko-chat");
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

    test('message stream - basic send and receive', () async {
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

      // Client 1 sends a message
      final testContent = "Test message ${_uuid.v4()}";
      await client1.sendMessage(
        person: client2.me,
        message: Create(
          base: ActivityBase(id: _uuid.v4obj()),
          object: Note(
            base: ObjectBase(id: _uuid.v4obj()),
            content: testContent,
          ),
        ),
      );

      // Client 2 receives the message
      final messages = await client2.getMessages();
      expect(messages.isNotEmpty, isTrue);
      final found = messages.any(
        (m) => ((m.activity as Create).object as Note).content == testContent,
      );
      expect(found, isTrue);

      // Cleanup
      await auth1.logout();
      await auth2.logout();
    });

    test('message stream - with pause', () async {
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

      // Client 1 sends first message
      final testContent1 = "Message before pause ${_uuid.v4()}";
      await client1.sendMessage(
        person: client2.me,
        message: Create(
          base: ActivityBase(id: _uuid.v4obj()),
          object: Note(
            base: ObjectBase(id: _uuid.v4obj()),
            content: testContent1,
          ),
        ),
      );

      // Verify message 1 can be received
      var messages = await client2.getMessages();
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
      await client1.sendMessage(
        person: client2.me,
        message: Create(
          base: ActivityBase(id: _uuid.v4obj()),
          object: Note(
            base: ObjectBase(id: _uuid.v4obj()),
            content: testContent2,
          ),
        ),
      );

      // Resume - now check for messages
      isPaused = false;
      messages = await client2.getMessages();
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
      await client1.sendMessage(
        person: client2.me,
        message: Create(
          base: ActivityBase(id: _uuid.v4obj()),
          object: Note(
            base: ObjectBase(id: _uuid.v4obj()),
            content: testContent3,
          ),
        ),
      );

      // Get messages again
      messages = await client2.getMessages();
      found = messages.any(
        (m) => ((m.activity as Create).object as Note).content == testContent3,
      );
      expect(found, isTrue);

      // Cleanup
      await auth1.logout();
      await auth2.logout();
    });

    test('message stream - fails if falls back to polling', () async {
      // Login client 1
      await auth1.login(email: email1, password: password1, url: baseUrl);
      expect(auth1.isAuthenticated, isTrue);
      client1 = EcpClient(
        storage: storage1,
        did: auth1.info!.did,
        me: auth1.info!.actor,
        client: auth1.client,
        tokenGetter: () async {
          return await auth1.getValidAccessToken();
        },
      );

      // Login client 2
      await auth2.login(email: email2, password: password2, url: baseUrl);
      expect(auth2.isAuthenticated, isTrue);
      client2 = EcpClient(
        storage: storage2,
        did: auth2.info!.did,
        me: auth2.info!.actor,
        client: auth2.client,
        tokenGetter: () async {
          return await auth2.getValidAccessToken();
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

      var messageReceived = false;

      // Monitor if polling is being used by checking the internal state
      // We'll send a message and verify it's received via WebSocket
      final streamSubscription = streamController.getMessagesStream().listen((
        messages,
      ) {
        messageReceived = true;
      });

      // Give WebSocket time to connect
      await Future.delayed(Duration(seconds: 2));

      // Check if WebSocket is active
      final hasWebSocket = streamController.isUsingWebSocket;

      // Send a test message
      final testContent = "WebSocket test message ${_uuid.v4()}";
      await client1.sendMessage(
        person: client2.me,
        message: Create(
          base: ActivityBase(id: _uuid.v4obj()),
          object: Note(
            base: ObjectBase(id: _uuid.v4obj()),
            content: testContent,
          ),
        ),
      );

      // Wait for message to arrive
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

      // Cleanup
      await streamSubscription.cancel();
      streamController.dispose();
      await auth1.logout();
      await auth2.logout();
    });
  });
}
