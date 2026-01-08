import 'dart:convert';

import 'package:ecp/src/parts/notifications.dart';
import 'package:ecp/src/parts/storage.dart';
import 'package:ecp/src/types/person.dart';
import 'package:ecp/src/types/capabilities.dart';
import 'package:ecp/src/types/current_user_keys.dart';
import 'package:ecp/src/types/activities.dart';
import 'package:ecp/src/parts/stream.dart';
import 'package:ecp/src/parts/messages.dart';
import 'package:ecp/src/parts/discovery.dart';
import 'package:ecp/src/parts/sessions.dart';
import 'package:http/http.dart' as http;

import 'package:ecp/src/types/activity_with_recipients.dart';

class EcpClientConfig {}

class EcpClient {
  late final MessageHandler _messageHandler;
  late final ActorDiscovery _actorDiscovery;
  late final NotificationHandler? _notificationHandler;
  late final MessageStreamController messageStreamController;

  final http.Client client;
  final Storage storage;
  final Person me;
  final int did;
  final Future<String> Function()? tokenGetter;
  final NotificationConfig? notificationConfig;
  EcpClient({
    required this.storage,
    required this.client,
    required this.me,
    required this.did,
    this.tokenGetter,
    this.notificationConfig,
  }) {
    _notificationHandler = notificationConfig == null
        ? null
        : NotificationHandler(this.notificationConfig!);
    _messageHandler = MessageHandler(
      storage: storage,
      client: client,
      me: me,
      did: did,
    );
    _actorDiscovery = ActorDiscovery(
      client: client,
      baseUrl: Uri.parse(me.id.origin),
    );
    messageStreamController = MessageStreamController(client: this);
  }

  static EcpClient? _instance;

  static EcpClient get instance {
    assert(
      _instance != null,
      'ECP has not been initialized. Please call ECP.initialize() before using it.',
    );
    return _instance!;
  }

  NotificationHandler get notifications {
    assert(_notificationHandler != null, "Notification Config must be passed");
    return _notificationHandler!;
  }

  /// Get the authentication token for WebSocket connections
  Future<String?> getAuthToken() async {
    if (tokenGetter != null) {
      return await tokenGetter!();
    }
    return null;
  }

  /// Get or generate current user's cryptographic keys
  Future<CurrentUserKeys> getCurrentUserKeys({required int numPreKeys}) async {
    return SessionManager(
      storage: storage,
    ).getCurrentUserKeys(numPreKeys: numPreKeys);
  }

  // Messages
  /// Send an encrypted message to a person
  Future<void> sendMessage({
    required Person person,
    required StableActivity message,
  }) async {
    return _messageHandler.sendMessage(person: person, message: message);
  }

  /// Get messages from inbox
  Future<List<ActivityWithRecipients>> getMessages() async {
    final response = await client.get(me.inbox);
    return _messageHandler.parseActivities(response.body);
  }

  // Discovery
  /// Get an actor by their WebFinger username (e.g., @user@example.com)
  Future<Person> getActorWithWebfinger(String username) async {
    return _actorDiscovery.getActorWithWebfinger(username);
  }

  /// Get an actor by their ID URI
  Future<Person> getActor(Uri id) async {
    return _actorDiscovery.getActor(id);
  }

  /// Resolve a WebFinger username to an actor URI
  Future<Uri> webFinger(String username) async {
    return _actorDiscovery.webFinger(username);
  }

  /// Get a server's capabilities
  Future<Capabilities> getCapabilities() async {
    final baseUrl = Uri.parse(me.id.origin);
    final response = await client.get(
      baseUrl.replace(
        pathSegments: [...baseUrl.pathSegments, ".well-known", "ecp"],
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch capabilities');
    }
    return Capabilities.fromJson(jsonDecode(response.body));
  }
}

EcpClient get ecp => EcpClient.instance;
