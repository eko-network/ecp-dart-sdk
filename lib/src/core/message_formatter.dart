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
  }) async {
    final groupId = mlsManager.deriveGroupId(a: senderId, b: recipientId);
    final engine = await mlsManager.createEngine();
    final credential = (await storage.mlsCredentialStore.getCredential())!;

    Uint8List? sharedCiphertext;
    final recipients = <EncryptedRecipient>[];

    // Identify devices that need to be added to the group
    final devicesToAdding = deviceKeyPackages.entries
        .where((e) => e.value.isNotEmpty)
        .toList();
    
    Uint8List? sharedCommit;
    Uint8List? sharedWelcome;

    if (devicesToAdding.isNotEmpty) {
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

      // Collect all key packages for a single commit
      final allKeyPackages = devicesToAdding.expand((e) => e.value).toList();
      final addResult = await engine.addMembers(
        groupIdBytes: groupId,
        signerBytes: credential.signerBytes,
        keyPackagesBytes: allKeyPackages,
      );
      sharedCommit = addResult.commit;
      sharedWelcome = addResult.welcome;
    }

    // Encrypt the application message once
    final groupMessage = await engine.createMessage(
      groupIdBytes: groupId,
      signerBytes: credential.signerBytes,
      message: Uint8List.fromList(utf8.encode(jsonEncode(message))),
    );
    sharedCiphertext = groupMessage.ciphertext;
    await engine.close();

    // Create recipient entries
    for (final did in deviceKeyPackages.keys) {
      final isNew = deviceKeyPackages[did]!.isNotEmpty;
      recipients.add(EncryptedRecipient(
        to: did,
        from: senderDid,
        welcome: isNew ? sharedWelcome : null,
        commit: isNew ? null : sharedCommit, // Existing members need the commit
      ));
    }

    return EncryptedMessage(
      context: [
        "https://www.w3.org/ns/activitystreams",
        {'sec': "our context"},
      ],
      typeField: 'EncryptedMessage',
      id: null,
      ciphertext: sharedCiphertext,
      recipients: recipients,
      attributedTo: senderId,
      to: [recipientId],
    );
  }

  Future<StableActivity> parseMessage({
    required EncryptedMessage envelope,
    required Uri myDid,
    required Uri senderId,
    required Uri recipientId, // My ID
  }) async {
    final recipientEntry = envelope.recipients.firstWhere(
      (r) => r.to == myDid,
      orElse: () => throw Exception("Device $myDid not found in recipient list"),
    );

    final engine = await mlsManager.createEngine();
    final groupId = mlsManager.deriveGroupId(a: senderId, b: recipientId);
    final credential = (await storage.mlsCredentialStore.getCredential())!;

    // 1. If there's a welcome, join the group first
    if (recipientEntry.welcome != null) {
      await engine.joinGroupFromWelcome(
        config: mlsManager.mlsConfig,
        welcomeBytes: recipientEntry.welcome!,
        signerBytes: credential.signerBytes,
      );
    }

    // 2. If there's a commit, process it to update state
    if (recipientEntry.commit != null) {
      final processed = await engine.processMessage(
        groupIdBytes: groupId,
        messageBytes: recipientEntry.commit!,
      );
      if (processed.messageType == ProcessedMessageType.stagedCommit) {
        await engine.mergePendingCommit(groupIdBytes: groupId);
      }
    }

    // 3. Process the application message
    if (envelope.ciphertext == null) {
      throw Exception('No application message in MLS envelope');
    }

    final processed = await engine.processMessage(
      groupIdBytes: groupId,
      messageBytes: envelope.ciphertext!,
    );
    
    await engine.close();

    if (processed.messageType != ProcessedMessageType.application) {
      throw Exception('Expected application message, got ${processed.messageType}');
    }

    return StableActivity.fromJson(
      jsonDecode(utf8.decode(processed.applicationMessage)),
    );
  }
}
