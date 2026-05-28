import 'dart:convert';
import 'dart:async';
import 'package:ecp/ecp.dart';
import 'package:http/http.dart' as http;

/// How long cached capabilities are considered fresh (7 days)
const _capabilitiesCacheDuration = Duration(days: 7);

Future<Capabilities> _getCapabilities(
  Uri url,
  http.Client client,
  Storage storage,
) async {
  final result = await storage.capabilitiesStore.getCapabilities();
  final capabilities = result?.capabilities;
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
    throw EcpCapabilitiesException(
      'Failed to fetch capabilities (HTTP ${response.statusCode})',
    );
  } on EcpCapabilitiesException {
    rethrow;
  } catch (e) {
    // Network error - use stale cache if available
    if (capabilities != null) {
      return Capabilities.fromJson(capabilities);
    }
    throw EcpCapabilitiesException(
      'Failed to fetch capabilities and no cached version available',
      cause: e,
    );
  }
}

class EcpClient {
  late final ActivitySender _activitySender;
  // late final MessageHandler _messageHandler;
  late final ActorDiscovery _actorDiscovery;
  late final RemoteSessionManager _remoteSessionManager;
  // late final MessageStreamController messageStreamController;

  final http.Client client;
  final Storage storage;
  final EcpCore core;
  final Person me;
  final String did;
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
    void Function(Object error)? onDeliveredAckError,
  }) {
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
      storage: storage,
      core: core,
      activitySender: _activitySender,
      actorDiscovery: _actorDiscovery,
      requestAuthenticator: requestAuthenticator,
    );
    // _messageHandler = MessageHandler(
    //   core: core,
    //   client: client,
    //   me: me,
    //   did: did,
    //   activitySender: _activitySender,
    //   requestAuthenticator: requestAuthenticator,
    //   sessions: _remoteSessionManager,
    //   onDeliveredAckError: onDeliveredAckError,
    // );
    // messageStreamController = MessageStreamController(
    //   client: this,
    //   messageHandler: _messageHandler,
    // );
  }

  static Future<EcpClient> build({
    required Storage storage,
    required http.Client client,
    required Person me,
    required String did,
    TokenProvider? tokenProvider,
    RequestAuthenticator? requestAuthenticator,
    MlsGroupConfig? mlsConfig,
    void Function(Object error)? onDeliveredAckError,
    required EcpCore core,
  }) async {
    final baseUrl = Uri.parse(me.id.origin);
    final capabilities = await _getCapabilities(baseUrl, client, storage);

    return EcpClient._(
      storage: storage,
      core: core,
      client: client,
      me: me,
      did: did,
      tokenProvider: tokenProvider,
      requestAuthenticator: requestAuthenticator,
      capabilities: capabilities,
      onDeliveredAckError: onDeliveredAckError,
    );
  }

  /// Close the client and release resources
  Future<void> close() async {
    client.close();
    await core.close();
  }

  /// Get or generate current user's cryptographic keys
  // Future<IdentityBundle> getCurrentUserCredential({
  //   required int numKeyPackages,
  //   required List<int> credentialIdentity,
  // }) async {
  //   return core.initializeIdentity(
  //     numKeyPackages: numKeyPackages,
  //     credentialIdentity: Uint8List.fromList(credentialIdentity),
  //   );
  // }

  // // Messages
  // /// Send an encrypted message to a person
  // Future<Uri?> sendMessage({
  //   required StableActivity message,
  //   required Person person,
  // }) async {
  //   return _messageHandler.sendMessage(person: person, message: message);
  // }
  //
  // /// Get messages from inbox
  // Future<List<ActivityWithMetaData>> getMessages() async {
  //   final response = await _messageHandler.getInbox();
  //   return _messageHandler.parseActivities(response.body);
  // }

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

  RemoteSessionManager get session => _remoteSessionManager;

  // Future<DeviceRefreshResult> ensureKeysFor({required Person person}) {
  //   return _remoteSessionManager.refreshKeys(person: person);
  // }
}
