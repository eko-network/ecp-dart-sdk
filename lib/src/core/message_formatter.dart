import 'dart:convert';
import 'dart:typed_data';
import 'package:openmls/openmls.dart';
import 'mls_manager.dart';
import 'types/storage.dart';
import 'types/activities.dart';
import 'types/encrypted_message.dart';

class MessageFormatter {
  final Storage storage;
  final MlsManager mlsManager;

  MessageFormatter({required this.storage, MlsManager? mlsManager})
      : mlsManager = mlsManager ?? MlsManager(storage: storage);

  Future<EncryptedMessage> formatMessage({
    required StableActivity message,
    required Uri senderId,
    required Uri senderDid,
    required Uri recipientId,
    required Map<Uri, List<Uint8List>> deviceKeyPackages,
    Map<Uri, EncryptedMessageEntry>? reUsedMessages,
  }) async {
    final note = EncryptedMessage(
      context: [
        "https://www.w3.org/ns/activitystreams",
        {'sec': "our context"},
      ],
      typeField: 'EncryptedMessage',
      id: null,
      content: [],
      attributedTo: senderId,
      to: [recipientId],
    );

    final Map<Uri, EncryptedMessageEntry> entries = reUsedMessages ?? {};
    final groupId = mlsManager.deriveGroupId(a: senderId, b: recipientId);

    for (final did in deviceKeyPackages.keys) {
      if (!entries.containsKey(did)) {
        final keyPackages = deviceKeyPackages[did]!;
        final engine = await mlsManager.createEngine();
        final credential = (await storage.mlsCredentialStore.getCredential())!;

        if (keyPackages.isNotEmpty) {
          try {
            await engine.createGroup(
              config: mlsManager.mlsConfig,
              signerBytes: credential.signerBytes,
              credentialIdentity: credential.credentialIdentity,
              signerPublicKey: credential.signerPublicKey,
              credentialBytes: credential.credentialBytes,
              groupId: groupId,
            );
          } catch (error) {
            // Group likely already exists.
          }
          final addResult = await engine.addMembers(
            groupIdBytes: groupId,
            signerBytes: credential.signerBytes,
            keyPackagesBytes: keyPackages,
          );
          final groupMessage = await engine.createMessage(
            groupIdBytes: groupId,
            signerBytes: credential.signerBytes,
            message: Uint8List.fromList(utf8.encode(jsonEncode(message))),
          );
          await engine.close();

          entries[did] = EncryptedMessageEntry(
            to: did,
            from: senderDid,
            content: [
              addResult.commit,
              addResult.welcome,
              groupMessage.ciphertext,
            ],
          );
        } else {
          final groupMessage = await engine.createMessage(
            groupIdBytes: groupId,
            signerBytes: credential.signerBytes,
            message: Uint8List.fromList(utf8.encode(jsonEncode(message))),
          );
          await engine.close();

          entries[did] = EncryptedMessageEntry(
            to: did,
            from: senderDid,
            content: [groupMessage.ciphertext],
          );
        }
      }
      note.content.add(entries[did]!);
    }
    return note;
  }

  Future<StableActivity> parseMessage({
    required EncryptedMessage envelope,
    required Uri myDid,
    required Uri senderId,
    required Uri recipientId, // My ID
  }) async {
    // Find and decrypt the message for this device
    for (final m in envelope.content) {
      if (m.to != myDid) continue;

      final engine = await mlsManager.createEngine();
      final groupId = mlsManager.deriveGroupId(a: senderId, b: recipientId);
      Uint8List? applicationMessage;

      for (final messageBytes in m.content) {
        try {
          final processed = await engine.processMessage(
            groupIdBytes: groupId,
            messageBytes: messageBytes,
          );
          if (processed.messageType == ProcessedMessageType.stagedCommit) {
            await engine.mergePendingCommit(groupIdBytes: groupId);
          }
          if (processed.messageType == ProcessedMessageType.application) {
            applicationMessage = processed.applicationMessage;
          }
          continue;
        } catch (error) {
          // fall through to try welcome processing
        }
        final credential = (await storage.mlsCredentialStore.getCredential())!;
        await engine.joinGroupFromWelcome(
          config: mlsManager.mlsConfig,
          welcomeBytes: messageBytes,
          signerBytes: credential.signerBytes,
        );
      }
      await engine.close();

      if (applicationMessage == null) {
        throw Exception('No application message in MLS payload');
      }
      return StableActivity.fromJson(jsonDecode(utf8.decode(applicationMessage)));
    }
    throw Exception("Device $myDid not found in recipient list");
  }
}
