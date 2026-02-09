import 'dart:convert';
import 'dart:typed_data';
import 'package:ecp/src/parts/storage.dart';
import 'package:ecp/src/parts/activity_sender.dart';
import 'package:ecp/src/types/typedefs.dart';
import 'package:ecp/src/types/person.dart';
import 'package:ecp/src/types/activities.dart';
import 'package:ecp/src/types/encrypted_message.dart';
import 'package:ecp/src/types/ordered_collection.dart';
import 'package:ecp/src/types/server_activities.dart' as remote;
import 'package:ecp/src/parts/sessions.dart';
import 'package:http/http.dart' as http;
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class MessageHandler {
  final Storage storage;
  final http.Client client;
  final RemoteSessionManager sessions;
  final Person me;
  final Uri did;
  final ActivitySender activitySender;
  Map<Uri, int>? _otherDevices;

  MessageHandler({
    required this.storage,
    required this.client,
    required this.me,
    required this.did,
    required this.activitySender,
    required this.sessions,
  }) {}

  Future<Map<Uri, int>> getOtherDevices() async {
    if (_otherDevices == null) {
      _otherDevices = await sessions.refreshKeys(person: this.me);
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
    Map<Uri, EncryptedMessageEntry>? reUsedMessages,
    bool isRetry = false,
  }) async {
    final note = EncryptedMessage(
      context: [
        "https://www.w3.org/ns/activitystreams",
        {'sec': "our context"},
      ],
      typeField: 'EncryptedMessage',
      id: null,
      content: [],
      attributedTo: me.id,
      to: [person.id],
    );

    final createActivity = remote.Create(
      base: remote.RemoteActivityBase(id: null, actor: me.id, to: person.id),
      object: note,
    );

    final Map<Uri, int> devices;
    if (person.id == this.me.id) {
      if (isRetry) {
        _otherDevices = null;
      }
      devices = await this.getOtherDevices();
    } else {
      if (isRetry) {
        devices = await sessions.refreshKeys(person: person);
      } else {
        devices = await storage.userStore.getUser(person.id).then((user) async {
          return user ?? await sessions.requestAllKeys(person: person);
        });
      }
    }

    if (devices.isEmpty) return null;

    final Map<Uri, EncryptedMessageEntry> inCaseRetry = reUsedMessages ?? {};
    // Encrypt for each device
    for (final MapEntry(key: did, value: localDid) in devices.entries) {
      if (!inCaseRetry.containsKey(did)) {
        // 2. Perform your async work outside the map setter
        final sessionCipher = sessions.buildSessionCipher(
          SignalProtocolAddress(person.id.toString(), localDid),
        );

        final cipherText = await sessionCipher.encrypt(
          Uint8List.fromList(utf8.encode(jsonEncode(message))),
        );

        // 3. Assign the resolved value to the map
        inCaseRetry[did] = EncryptedMessageEntry(
          to: did,
          from: this.did,
          content: cipherText,
        );
      }
      final entry = inCaseRetry[did]!;
      note.content.add(entry);
    }

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
      // TODO maybe check status instead of message?
      if (!isRetry && e.message.contains('device_list_mismatch')) {
        return await _dispatchEncryptedMessage(
          person: person,
          message: message,
          isRetry: true,
          reUsedMessages: inCaseRetry,
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

  /// Parse a single activity and decrypt if needed
  Future<ActivityWithMetaData> _parseActivity(Map<String, dynamic> json) async {
    final activity = remote.ServerActivity.fromJson(json);
    final senderId = activity.base.actor;

    if (activity is remote.Create) {
      assert(
        activity.object.id != null,
        "Received EncryptedMessages must have ids",
      );
      // Find and decrypt the message for this device
      for (final m in activity.object.content) {
        if (m.to != did) {
          continue;
        }

        final type = m.content.getType();
        final senderDid = m.from;
        var localSenderDid = await this.storage.userStore.getDevice(senderDid);

        // If we don't have the sender's DID mapping yet, save it
        if (localSenderDid == null) {
          localSenderDid = await this.storage.userStore.saveDevice(
            senderId,
            senderDid,
          );
        }

        final address = SignalProtocolAddress(
          senderId.toString(),
          localSenderDid,
        );
        final sessionCipher = sessions.buildSessionCipher(address);

        // Decrypt based on message type
        final Uint8List decrypted;
        if (type == CiphertextMessage.prekeyType) {
          decrypted = await sessionCipher.decrypt(
            m.content as PreKeySignalMessage,
          );
        } else if (type == CiphertextMessage.whisperType) {
          decrypted = await sessionCipher.decryptFromSignal(
            m.content as SignalMessage,
          );
        } else {
          throw Exception("Unexpected ciphertext type: $type");
        }

        final jsonActivity = jsonDecode(utf8.decode(decrypted));

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
          activity: StableActivity.fromJson(jsonActivity),
          actor: activity.object.attributedTo,
          id: activity.object.id!,
        );
      }
      throw Exception("Device $did not found in recipient list");
    } else if (activity is remote.Delivered) {
      // Convert server Delivered to stable Delivered
      return (
        activity: Delivered.fromServerDelivered(activity, senderId),
        id: activity.base.id!,
        actor: activity.base.actor,
      );
    }
    throw Exception("Activity type not supported: ${activity.runtimeType}");
  }
}
