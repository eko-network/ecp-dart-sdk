import 'package:ecp/auth.dart';
import 'package:ecp/ecp.dart';
import 'package:ecp/src/types/typedefs.dart';

import '../storage/mock_auth_storage.dart';
import '../storage/mock_token_storage.dart';
import 'message_helpers.dart';
import 'test_user.dart';

/// Represents a device belonging to a test user
class TestDevice {
  final TestUser user;
  final EcpClient client;
  final Auth auth;
  final MockTokenStorage storage;
  final AuthStorage authStorage;
  final String deviceName;

  TestDevice._({
    required this.user,
    required this.client,
    required this.auth,
    required this.storage,
    required this.authStorage,
    required this.deviceName,
  });

  /// Create and authenticate a new device for a user
  static Future<TestDevice> create({
    required TestUser user,
    required String deviceName,
    required Uri baseUrl,
  }) async {
    // Create storage instances
    final storage = MockTokenStorage();
    final authStorage = InMemoryAuthStorage();

    // Create and authenticate
    final auth = Auth(authStorage, ecpStorage: storage, deviceName: deviceName);

    await auth.login(email: user.email, password: user.password, url: baseUrl);

    // Build ECP client
    final client = await EcpClient.build(
      storage: storage,
      did: auth.info!.did,
      me: auth.info!.actor,
      client: auth.client,
    );

    return TestDevice._(
      user: user,
      client: client,
      auth: auth,
      storage: storage,
      authStorage: authStorage,
      deviceName: deviceName,
    );
  }

  // Direct access to client methods (no unnecessary wrappers)

  /// Send a message using the underlying client
  Future<void> sendMessage({
    required Person person,
    required StableActivity message,
  }) {
    return client.sendMessage(person: person, message: message);
  }

  /// Get messages using the underlying client
  Future<List<ActivityWithRecipients>> getMessages() {
    return client.getMessages();
  }

  // Convenience methods

  /// Send a text message to a recipient user
  /// Uses the recipient's primary device as the target
  Future<void> sendTextTo(TestUser recipient, String content) async {
    await client.sendMessage(
      person: recipient.primaryDevice.client.me,
      message: MessageFactory.note(
        content,
        recipient.primaryDevice.client.me.id,
      ),
    );
  }

  /// Assert that a message with expected content was received
  Future<void> expectMessage(String content, {int index = 0}) async {
    final messages = await getMessages();
    MessageAssertions.expectNoteContent(messages, content, index: index);
  }

  /// Cleanup this device (logout)
  Future<void> cleanup() async {
    if (auth.isAuthenticated) {
      await auth.logout();
    }
  }
}
