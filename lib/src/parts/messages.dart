import 'dart:convert';
import 'dart:typed_data';
import 'package:ecp/src/parts/storage.dart';
import 'package:ecp/src/types/activity_with_recipients.dart';
import 'package:ecp/src/types/person.dart';
import 'package:ecp/src/types/activities.dart';
import 'package:ecp/src/types/encrypted_message.dart';
import 'package:ecp/src/types/server_activities.dart' as remote;
import 'package:ecp/src/parts/sessions.dart';
import 'package:http/http.dart' as http;
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class MessageHandler {
  final Storage storage;
  final http.Client client;
  final Person me;
  final int did;
  late final SessionManager _sessionManager;

  MessageHandler({
    required this.storage,
    required this.client,
    required this.me,
    required this.did,
  }) {
    _sessionManager = SessionManager(storage: storage);
  }

  /// Send an encrypted message to a person
  Future<void> sendMessage({
    required Person person,
    required StableActivity message,
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
      base: remote.RemoteActivityBase(id: null, actor: me.id),
      object: note,
    );

    // Get or request keys for recipient devices
    final List<int> devices =
        await storage.userStore.getUser(person.id) ??
        await _sessionManager.requestKeys(person: person, client: client);

    // Encrypt for each device
    for (final deviceId in devices) {
      final sessionCipher = _sessionManager.buildSessionCipher(
        SignalProtocolAddress(person.id.toString(), deviceId),
      );

      final cipherText = await sessionCipher.encrypt(
        Uint8List.fromList(utf8.encode(jsonEncode(message))),
      );

      note.content.add(
        EncryptedMessageEntry(to: deviceId, from: did, content: cipherText),
      );
    }

    final response = await client.post(
      me.outbox,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(createActivity.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception(
        "Problem sending message to server: ${response.body}\n"
        "message:\n${createActivity.toJson()}",
      );
    }
  }

  /// Parse activities from JSON (list or single)
  Future<List<ActivityWithRecipients>> parseActivities(dynamic json) async {
    if (json is String) {
      json = jsonDecode(json);
    }
    if (json is List) {
      final futures = json.map((v) => _parseActivity(v));
      return Future.wait(futures);
    }
    if (json is Map<String, dynamic>) {
      return _parseActivity(json).then((v) => [v]);
    }
    throw Exception(
      "Expected List<Map<String, dynamic>> or Map<String, dynamic>, "
      "got ${json.runtimeType}",
    );
  }

  /// Parse a single activity and decrypt if needed
  Future<ActivityWithRecipients> _parseActivity(
    Map<String, dynamic> json,
  ) async {
    final activity = remote.ServerActivity.fromJson(json);
    final senderId = activity.base.actor;

    if (activity is remote.Create) {
      // Find and decrypt the message for this device
      for (final m in activity.object.content) {
        if (m.to != did) {
          continue;
        }

        final type = m.content.getType();
        final senderDid = m.from;
        final address = SignalProtocolAddress(senderId.toString(), senderDid);
        final sessionCipher = _sessionManager.buildSessionCipher(address);

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
        return (
          activity: StableActivity.fromJson(jsonActivity),
          to: activity.object.to,
          from: activity.object.attributedTo,
        );
      }
      throw Exception("Device $did not found in recipient list");
    }
    throw Exception("Activity type not supported: ${activity.runtimeType}");
  }
}
