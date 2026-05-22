import 'dart:convert';
import 'dart:typed_data';

import 'package:ecp/core.dart';
import 'package:ecp/src/client/notifications.dart';
import 'package:ecp/src/client/activity_sender.dart';
import 'package:ecp/src/client/types/person.dart';
import 'package:ecp/src/client/types/capabilities.dart';
import 'package:ecp/src/client/stream.dart';
import 'package:ecp/src/client/messages.dart';
import 'package:ecp/src/client/discovery.dart';
import 'package:ecp/src/client/sessions.dart';
import 'package:ecp/src/client/auth/request_authenticator.dart';
import 'package:ecp/src/client/auth/token_provider.dart';
import 'package:http/http.dart' as http;

import 'package:ecp/src/client/types/typedefs.dart';

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
  late final RemoteSessionManager _remoteSessionManager;
  late final MessageStreamController messageStreamController;

  final http.Client client;
  final Storage storage;
  final EcpCore core;
  final Person me;
  final Uri did;
  final TokenProvider? tokenProvider;
  final RequestAuthenticator? requestAuthenticator;
  final Capabilities capabilities;
  EcpClient._({
    required this.storage,
    required this.core,
    required this.client,
    required this.me,
    required this.did,
    required this.capabilities,
    this.tokenProvider,
    this.requestAuthenticator,
  }) {
    _notificationHandler = this.capabilities.webPush == null
        ? null
        : NotificationHandler(
            this.client,
            this.capabilities.webPush!,
            requestAuthenticator: requestAuthenticator,
          );
    _activitySender = ActivitySender(
      client: client,
      me: me,
      did: did,
      requestAuthenticator: requestAuthenticator,
    );
    _actorDiscovery = ActorDiscovery(
      client: client,
      baseUrl: Uri.parse(me.id.origin),
      requestAuthenticator: requestAuthenticator,
    );
    _remoteSessionManager = RemoteSessionManager(
      core: core,
      activitySender: _activitySender,
      actorDiscovery: _actorDiscovery,
      requestAuthenticator: requestAuthenticator,
    );
    _messageHandler = MessageHandler(
      core: core,
      client: client,
      me: me,
      did: did,
      activitySender: _activitySender,
      requestAuthenticator: requestAuthenticator,
      sessions: _remoteSessionManager,
    );
    messageStreamController = MessageStreamController(
      client: this,
      messageHandler: _messageHandler,
    );
  }

  static Future<EcpClient> build({
    required storage,
    required http.Client client,
    required Person me,
    required Uri did,
    TokenProvider? tokenProvider,
    RequestAuthenticator? requestAuthenticator,
    MlsGroupConfig? mlsConfig,
  }) async {
    final baseUrl = Uri.parse(me.id.origin);
    final capabilities = await _getCapabilities(baseUrl, client, storage);
    final core = EcpCore(storage: storage, mlsConfig: mlsConfig);
    // Optionally open the core for better performance
    await core.open();
    return EcpClient._(
      storage: storage,
      core: core,
      client: client,
      me: me,
      did: did,
      tokenProvider: tokenProvider,
      requestAuthenticator: requestAuthenticator,
      capabilities: capabilities,
    );
  }

  /// Close the client and release resources
  Future<void> close() async {
    client.close();
    await core.close();
  }

  NotificationHandler get notifications {
    assert(_notificationHandler != null, "Notification Config must be passed");
    return _notificationHandler!;
  }

  /// Get the authentication token for WebSocket connections
  Future<String?> getAuthToken() async {
    if (tokenProvider != null) {
      return await tokenProvider!.getAccessToken();
    }
    return null;
  }

  /// Get or generate current user's cryptographic keys
  Future<IdentityBundle> getCurrentUserCredential({
    required int numKeyPackages,
    required List<int> credentialIdentity,
  }) async {
    return core.initializeIdentity(
      numKeyPackages: numKeyPackages,
      credentialIdentity: Uint8List.fromList(credentialIdentity),
    );
  }

  // Messages
  /// Send an encrypted message to a person
  Future<Uri?> sendMessage({
    required StableActivity message,
    required Person person,
  }) async {
    return _messageHandler.sendMessage(person: person, message: message);
  }

  /// Get messages from inbox
  Future<List<ActivityWithMetaData>> getMessages() async {
    final response = await _messageHandler.getInbox();
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
}
