import 'dart:convert';
import 'dart:typed_data';

import 'package:ecp/ecp.dart';
import 'package:ecp/src/client/types/typedefs.dart';
import 'package:http/http.dart' as http;

import '../storage/mock_token_storage.dart';
import 'message_helpers.dart';
import 'test_user.dart';

/// Represents a device belonging to a test user
class TestDevice {
  final TestUser user;
  final EcpClient client;
  final MockTokenStorage storage;
  final String deviceName;

  TestDevice._({
    required this.user,
    required this.client,
    required this.storage,
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

    final keys = await EcpCore(storage: storage).initializeIdentity(
      numKeyPackages: 10,
      credentialIdentity: Uint8List.fromList(utf8.encode(user.email)),
    );
    final loginResponse = await http.post(
      baseUrl.replace(
        pathSegments: [...baseUrl.pathSegments, 'auth', 'v1', 'login'],
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': user.email,
        'password': user.password,
        'deviceName': deviceName,
        ...keys.toJson(),
      }),
    );

    if (loginResponse.statusCode != 200) {
      throw Exception('Login failed: ${loginResponse.body}');
    }

    final loginData = jsonDecode(loginResponse.body) as Map<String, dynamic>;
    final person = Person.fromJson(loginData['actor']);
    final did = Uri.parse(loginData['did'] as String);
    final accessToken = loginData['accessToken'] as String;

    // Build ECP client
    final client = await EcpClient.build(
      storage: storage,
      did: did,
      me: person,
      client: http.Client(),
      tokenProvider: _StaticTokenProvider(accessToken),
      requestAuthenticator: () async => {
        'Authorization': 'Bearer $accessToken',
      },
    );

    return TestDevice._(
      user: user,
      client: client,
      storage: storage,
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
  Future<List<ActivityWithMetaData>> getMessages() {
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
    // TODO: add server logout once endpoint is auth-agnostic.
  }
}

class _StaticTokenProvider implements TokenProvider {
  final String accessToken;
  _StaticTokenProvider(this.accessToken);

  @override
  Future<String?> getAccessToken() async => accessToken;
}
