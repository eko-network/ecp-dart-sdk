import 'dart:convert';

import 'package:ecp/src/parts/notifications.dart';
import 'package:ecp/src/parts/storage.dart';
import 'package:ecp/src/parts/activity_sender.dart';
import 'package:ecp/src/types/person.dart';
import 'package:ecp/src/types/capabilities.dart';
import 'package:ecp/src/types/current_user_keys.dart';
import 'package:ecp/src/types/activities.dart';
import 'package:ecp/src/parts/stream.dart';
import 'package:ecp/src/parts/messages.dart';
import 'package:ecp/src/parts/discovery.dart';
import 'package:ecp/src/parts/sessions.dart';
import 'package:http/http.dart' as http;

import 'package:ecp/src/types/typedefs.dart';

/// How long cached capabilities are considered fresh (7 days)
const _capabilitiesCacheDuration = Duration(days: 7);

Future<Capabilities> _getCapabilities(
  Uri url,
  http.Client client,
  Storage storage,
) async {
  final result = await storage.capabilitiesStore.getCapabilities();
  final capabilities = result?.capabilites;
  final timestamp = result?.timestamp;
  if (capabilities != null && timestamp != null) {
    // If cache exists and is fresh, use it
    final cacheAge = DateTime.now().difference(timestamp);
    if (cacheAge < _capabilitiesCacheDuration) {
      return Capabilities.fromJson(capabilities);
    }
  }

  // Cache is missing or stale, try to fetch fresh capabilities
  final capabilitiesUrl = url.replace(
    pathSegments: [...url.pathSegments, ".well-known", "ecp"],
  );

  try {
    final response = await client.get(capabilitiesUrl);
    if (response.statusCode == 200) {
      final capabilitiesJson =
          jsonDecode(response.body) as Map<String, dynamic>;
      // Cache the capabilities on successful fetch
      await storage.capabilitiesStore.saveCapabilities(capabilitiesJson);
      return Capabilities.fromJson(capabilitiesJson);
    }
  } catch (e) {
    // Network error - use stale cache if available
    if (capabilities != null) {
      return Capabilities.fromJson(capabilities);
    }
    rethrow;
  }

  // Non-200 response
  throw Exception(
    'Failed to fetch capabilities and no cached version available',
  );
}

class EcpClient {
  late final ActivitySender _activitySender;
  late final MessageHandler _messageHandler;
  late final ActorDiscovery _actorDiscovery;
  late final NotificationHandler? _notificationHandler;
  late final MessageStreamController messageStreamController;

  final http.Client client;
  final Storage storage;
  final Person me;
  final Uri did;
  final Future<String> Function()? tokenGetter;
  final Capabilities capabilities;
  EcpClient._({
    required this.storage,
    required this.client,
    required this.me,
    required this.did,
    required this.capabilities,
    this.tokenGetter,
  }) {
    _notificationHandler = this.capabilities.webPush == null
        ? null
        : NotificationHandler(this.client, this.capabilities.webPush!);
    _activitySender = ActivitySender(client: client, me: me, did: did);
    _messageHandler = MessageHandler(
      storage: storage,
      client: client,
      me: me,
      did: did,
      activitySender: _activitySender,
    );
    _actorDiscovery = ActorDiscovery(
      client: client,
      baseUrl: Uri.parse(me.id.origin),
    );
    messageStreamController = MessageStreamController(client: this);
  }

  static Future<EcpClient> build({
    required storage,
    required http.Client client,
    required Person me,
    required Uri did,
    Future<String> Function()? tokenGetter,
  }) async {
    final baseUrl = Uri.parse(me.id.origin);
    final capabilities = await _getCapabilities(baseUrl, client, storage);
    return EcpClient._(
      storage: storage,
      client: client,
      me: me,
      did: did,
      tokenGetter: tokenGetter,
      capabilities: capabilities,
    );
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
  // Future<Capabilities> getCapabilities() async {
  //   final baseUrl = Uri.parse(me.id.origin);
  //   return await _getCapabilities(baseUrl, client);
  // }
}
