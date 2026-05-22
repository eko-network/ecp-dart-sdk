import 'dart:convert';
import 'dart:typed_data';
import 'package:ecp/ecp.dart';
import 'package:ecp/src/client/activity_sender.dart';
import 'package:ecp/src/client/types/typedefs.dart';
import 'package:ecp/src/client/types/person.dart';
import 'package:ecp/src/client/types/ordered_collection.dart';
import 'package:ecp/src/client/types/server_activities.dart' as remote;
import 'package:ecp/src/client/auth/request_authenticator.dart';
import 'package:ecp/src/client/sessions.dart';
import 'package:http/http.dart' as http;

class MessageHandler {
  final Storage storage;
  final http.Client client;
  final RemoteSessionManager sessions;
  final Person me;
  final Uri did;
  final ActivitySender activitySender;
  final RequestAuthenticator? requestAuthenticator;
  final EcpCore core;
  Map<Uri, int>? _otherDevices;

  MessageHandler({
    required this.core,
    required this.client,
    required this.me,
    required this.did,
    required this.activitySender,
    required this.sessions,
    this.requestAuthenticator,
  }) : storage = core.storage;

  Future<Map<Uri, int>> getOtherDevices() async {
    if (_otherDevices == null) {
      final refresh = await sessions.refreshKeys(person: this.me);
      _otherDevices = refresh.activeDevices;
      _otherDevices!.remove(this.did);
    }
    return _otherDevices!;
  }

  Future<Uri?> sendMessage({
    required StableActivity message,
    required Person person,
    bool isRetry = false,
  }) async {
    if (message is Delivered) {
      throw ArgumentError('Cannot manually send Delivered activities');
    }

    Future<Uri?>? selfDispatch;
    Future<Uri?>? targetDispatch;

    if ((await getOtherDevices()).isNotEmpty) {
      selfDispatch = _dispatchEncryptedMessage(
        person: this.me,
        message: message,
      );
    }

    if (person.id != this.me.id) {
      targetDispatch = _dispatchEncryptedMessage(
        person: person,
        message: message,
      );
    }

    final activeTasks = [
      selfDispatch,
      targetDispatch,
    ].whereType<Future<Uri?>>();
    await Future.wait(activeTasks);
    return targetDispatch;
  }

  Future<Uri?> _dispatchEncryptedMessage({
    required StableActivity message,
    required Person person,
    bool isRetry = false,
  }) async {
    final Map<Uri, int> devices;
    if (person.id == this.me.id) {
      if (isRetry) {
        _otherDevices = null;
      }
      devices = await this.getOtherDevices();
    } else {
      if (isRetry) {
        final refresh = await sessions.refreshKeys(person: person);
        devices = refresh.activeDevices;
      } else {
        final storedDevices = await storage.userStore.getUser(person.id);
        if (storedDevices == null) {
          final refresh = await sessions.requestAllKeys(person: person);
          devices = refresh.activeDevices;
        } else {
          devices = storedDevices;
        }
      }
    }

    if (devices.isEmpty) return null;

    // Fetch any key packages we need to add new devices to the group
    // For now, we assume we only add key packages if it's the first time or a retry with new devices
    final myKeyPackages = await storage.mlsKeyPackageStore.getKeyPackages();
    final Map<Uri, List<Uint8List>> deviceKeyPackages = {};
    for (final did in devices.keys) {
      // In a real scenario, we'd only pass key packages for devices NOT already in the MLS group.
      // For this simplified version, we pass them if we have them.
      deviceKeyPackages[did] = myKeyPackages;
    }

    final note = await core.formatMessage(
      message: message,
      senderId: me.id,
      senderDid: did,
      recipientId: person.id,
      deviceKeyPackages: deviceKeyPackages,
    );

    // If we used our key packages, clear them
    if (myKeyPackages.isNotEmpty) {
      await storage.mlsKeyPackageStore.saveKeyPackages([]);
    }

    final createActivity = remote.Create(
      base: remote.RemoteActivityBase(id: null, actor: me.id, to: person.id),
      object: note,
    );

    try {
      final body = jsonDecode(
        (await activitySender.sendActivity(createActivity)).body,
      );
      final maybeId = body['id'];
      if (maybeId == null) {
        return null;
      } else {
        return Uri.parse(maybeId as String);
      }
    } on http.ClientException catch (e) {
      if (!isRetry && e.message.contains('device_list_mismatch')) {
        return await _dispatchEncryptedMessage(
          person: person,
          message: message,
          isRetry: true,
        );
      }
      rethrow;
    }
  }

  /// Parse activities from JSON (list, OrderedCollection, or single)
  Future<List<ActivityWithMetaData>> parseActivities(dynamic json) async {
    if (json is String) {
      json = jsonDecode(json);
    }

    // parse the OrderedCollection from inbox
    if (json is Map<String, dynamic> && json['type'] == 'OrderedCollection') {
      final collection = OrderedCollection.fromJson(json);
      final futures = collection.orderedItems.map((v) => _parseActivity(v));
      final results = await Future.wait(futures);
      return results.whereType<ActivityWithMetaData>().toList();
    }
    if (json is List) {
      final futures = json.map((v) => _parseActivity(v));
      final results = await Future.wait(futures);
      return results.whereType<ActivityWithMetaData>().toList();
    }
    if (json is Map<String, dynamic>) {
      final result = await _parseActivity(json);
      return [result];
    }
    throw Exception(
      "Expected OrderedCollection, List<Map<String, dynamic>>, or Map<String, dynamic>, "
      "got ${json.runtimeType}",
    );
  }

  Future<http.Response> getInbox() async {
    final headers = await requestAuthenticator?.call() ?? {};
    return client.get(me.inbox, headers: headers);
  }

  /// Parse a single activity and decrypt if needed
  Future<ActivityWithMetaData> _parseActivity(Map<String, dynamic> json) async {
    final activity = remote.ServerActivity.fromJson(json);
    final senderId = activity.base.actor;

    if (activity is remote.Create) {
      assert(
        activity.object.id != null,
        "Received EncryptedMessages must have ids",
      );

      // Core logic handles finding the right entry and decrypting
      final StableActivity decryptedActivity;
      try {
        decryptedActivity = await core.parseMessage(
          envelope: activity.object,
          myDid: did,
          senderId: senderId,
          recipientId: me.id,
        );
      } catch (e) {
        // If we can't decrypt, we might need to save the sender device anyway
        // or just fail. The original code did:
        // for (final m in activity.object.content) { if (m.to == did) { ... } }
        // and threw if not found.
        rethrow;
      }

      // Ensure sender device is tracked (Client/Core hybrid)
      final senderDid = activity.object.recipients.firstWhere((m) => m.to == did).from;
      var localSenderDid = await this.storage.userStore.getDevice(senderDid);
      if (localSenderDid == null) {
        await this.storage.userStore.saveDevice(senderId, senderDid);
      }

      // Send Delivered acknowledgment if the Create activity has an ID
      final createId = activity.base.id;
      if (createId != null) {
        final deliveredActivity = remote.Delivered(
          base: remote.RemoteActivityBase(
            id: null,
            actor: me.id,
            to: senderId,
          ),
          object: createId.toString(),
        );

        try {
          await activitySender.sendActivity(deliveredActivity);
        } catch (error) {
          print('Failed to send Delivered acknowledgment: $error');
        }
      }

      return (
        activity: decryptedActivity,
        actor: activity.object.attributedTo,
        id: activity.object.id!,
      );
    } else if (activity is remote.Delivered) {
      return (
        activity: Delivered.fromServerDelivered(activity, senderId),
        id: activity.base.id!,
        actor: activity.base.actor,
      );
    }
    throw Exception("Activity type not supported: ${activity.runtimeType}");
  }
}
