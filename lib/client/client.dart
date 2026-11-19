import 'dart:async';
import 'dart:convert';

import 'package:ecp/ecp.dart';
import 'package:http/http.dart' as http;

// How long cached capabilities are considered fresh (7 days)
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
  late final MessageHandler _messageHandler;
  late final GroupManager _groupManager;
  late final DeviceManager _deviceManager;

  final http.Client client;
  final EcpCore core;
  final Capabilities capabilities;
  final String did;

  /// May refresh the token, so it is awaited before every use.
  final FutureOr<String> Function()? tokenGetter;

  EcpClient._({
    required this.core,
    required this.client,
    required this.capabilities,
    required this.did,
    this.tokenGetter,
  }) {
    _activitySender = ActivitySender(client: client, did: did, core: core);
    _deviceManager = DeviceManager(core: core, activitySender: _activitySender);
    _groupManager = GroupManager(
      core: core,
      activitySender: _activitySender,
      devices: _deviceManager,
    );
    _messageHandler = MessageHandler(
      core: core,
      client: client,
      activitySender: _activitySender,
      groups: _groupManager,
    );
    _groupManager.catchUp = () => _messageHandler.getInbox().then((_) {});
  }

  static Future<EcpClient> build({
    required String did,
    required http.Client client,
    required EcpCore core,
    MlsGroupConfig? mlsConfig,
    FutureOr<String> Function()? tokenGetter,
  }) async {
    final baseUrl = Uri.parse(core.identity.id.origin);
    final capabilities = await _getCapabilities(baseUrl, client, core.storage);
    await core.open();

    return EcpClient._(
      did: did,
      core: core,
      client: client,
      capabilities: capabilities,
      tokenGetter: tokenGetter,
    );
  }

  /// Get the authentication token for WebSocket connections
  Future<String?> getAuthToken() async {
    if (tokenGetter != null) {
      return await tokenGetter!();
    }
    return null;
  }

  /// Close the client and release resources
  Future<void> close() async {
    client.close();
    await core.close();
  }

  Person get me => core.identity;

  /// Mints this device a token for its notification service, which reads the
  /// inbox and sends delivered acks while the app is not running. It replaces
  /// the device's last one, and is good for as long as the device is.
  Future<String> mintNotificationToken() async {
    final me = core.identity.id;
    final response = await client.post(
      me.replace(pathSegments: [...me.pathSegments, 'notificationToken']),
    );
    if (response.statusCode != 200) {
      throw EcpNetworkException(
        'Failed to mint a notification token (HTTP ${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['token']
        as String;
  }

  /// Fetch, decrypt, persist, and return newly received inbox messages.
  Future<List<StoredMessage>> getInbox() => _messageHandler.getInbox();

  /// Process a single [WireActivity] (e.g. from WebPush or a WebSocket).
  ///
  /// This will decrypt the message, handle any system logic (like group joins),
  /// and persist the result to the message store.
  Future<StoredMessage?> handleActivity(WireActivity activity) =>
      _messageHandler.handleActivity(activity);

  /// Process multiple activities from a JSON payload (e.g. from a WebSocket).
  ///
  /// This will parse the payload (which can be an OrderedCollection, a List,
  /// or a single Activity), and process each activity through the pipeline.
  Future<List<StoredMessage>> handleInbox(dynamic json) =>
      _messageHandler.handleInbox(json);

  GroupManager get groups => _groupManager;
  DeviceManager get devices => _deviceManager;
  MessageHandler get messages => _messageHandler;
}
