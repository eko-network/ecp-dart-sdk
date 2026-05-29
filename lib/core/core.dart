import 'dart:typed_data';
import 'package:ecp/ecp.dart';

class EcpCore {
  final Storage storage;
  final MlsEngineConfig engineConfig;
  MlsGroupConfig? _mlsConfig;
  MlsEngine? _engine;
  final Uint8List credentialIdentity;

  EcpCore({
    required this.storage,
    required this.credentialIdentity,
    required this.engineConfig,
    MlsGroupConfig? mlsConfig,
  }) : _mlsConfig = mlsConfig;

  Future<MlsGroupConfig> get mlsConfig async {
    if (_mlsConfig != null) return _mlsConfig!;
    _mlsConfig = MlsGroupConfig.defaultConfig(
      ciphersuite: MlsCiphersuite.mls128DhkemX25519Aes128GcmSha256Ed25519,
    );
    return _mlsConfig!;
  }

  Future<MlsEngine> _getEngine() async {
    if (_engine != null) return _engine!;
    await Openmls.init();
    final config = engineConfig;
    return await MlsEngine.create(
      dbPath: config.dbPath,
      encryptionKey: config.encryptionKey,
    );
  }

  Future<void> open() async {
    _engine = await _getEngine();
  }

  Future<void> close() async {
    await _engine?.close();
    _engine = null;
  }

  MlsEngine get engine {
    assert(_engine != null, "open() must be called first for direct access");
    return _engine!;
  }

  Future<(MlsCredentialRecord, List<KeyPackageResult>)> createIdentity({
    int numKeyPackages = 50,
  }) async {
    final signer = MlsSignatureKeyPair.generate(
      ciphersuite: MlsCiphersuite.mls128DhkemX25519Aes128GcmSha256Ed25519,
    );
    final credential = MlsCredential.basic(identity: credentialIdentity);
    final credentialBytes = credential.serialize();
    final signerBytes = serializeSigner(
      ciphersuite: MlsCiphersuite.mls128DhkemX25519Aes128GcmSha256Ed25519,
      privateKey: signer.privateKey(),
      publicKey: signer.publicKey(),
    );
    final signerPublicKey = signer.publicKey();
    final record = MlsCredentialRecord(
      credentialIdentity: credentialIdentity,
      credentialBytes: credentialBytes,
      signerBytes: signerBytes,
      signerPublicKey: signerPublicKey,
    );

    final keyPackages = <KeyPackageResult>[];
    for (var i = 0; i < numKeyPackages; i++) {
      final keyPackage = await engine.createKeyPackage(
        ciphersuite: MlsCiphersuite.mls128DhkemX25519Aes128GcmSha256Ed25519,
        signerBytes: record.signerBytes,
        credentialIdentity: record.credentialIdentity,
        signerPublicKey: record.signerPublicKey,
        credentialBytes: record.credentialBytes,
      );
      keyPackages.add(keyPackage);
    }
    return (record, keyPackages);
  }

  Future<CreateGroupResult> createGroup(Uint8List? groupId) async {
    final credential = (await storage.mlsCredentialStore.getCredential())!;
    final result = await engine.createGroup(
      config: await mlsConfig,
      signerBytes: credential.signerBytes,
      credentialIdentity: credential.credentialIdentity,
      signerPublicKey: credential.signerPublicKey,
      credentialBytes: credential.credentialBytes,
      groupId: groupId,
    );
    return result;
  }

  Future<AddMembersResult> addMembers(
    Uint8List groupId,
    List<Uint8List> keyPackages,
  ) async {
    final credential = (await storage.mlsCredentialStore.getCredential())!;
    return await engine.addMembers(
      groupIdBytes: groupId,
      signerBytes: credential.signerBytes,
      keyPackagesBytes: keyPackages,
    );
  }

  Future<void> joinGroupFromWelcome(Uint8List welcomeBytes) async {
    final credential = (await storage.mlsCredentialStore.getCredential())!;
    await engine.joinGroupFromWelcome(
      config: await mlsConfig,
      welcomeBytes: welcomeBytes,
      signerBytes: credential.signerBytes,
    );
  }

  // Future<EncryptedMessage> formatMessage({
  //   required StableActivity message,
  //   required Uri senderId,
  //   required Uri senderDid,
  //   required Uri recipientId,
  //   required Map<Uri, List<Uint8List>> deviceKeyPackages,
  // }) async {
  //   return _withEngine((engine) async {
  //     final groupId = deriveGroupId(a: senderId, b: recipientId);
  //     final credential = (await storage.mlsCredentialStore.getCredential())!;
  //
  //     Uint8List? sharedCiphertext;
  //     final recipients = <EncryptedRecipient>[];
  //
  //     final devicesToAdding = deviceKeyPackages.entries
  //         .where((e) => e.value.isNotEmpty)
  //         .toList();
  //
  //     Uint8List? sharedCommit;
  //     Uint8List? sharedWelcome;
  //
  //     if (devicesToAdding.isNotEmpty) {
  //       try {
  //         await engine.createGroup(
  //           config: await mlsConfig,
  //           signerBytes: credential.signerBytes,
  //           credentialIdentity: credential.credentialIdentity,
  //           signerPublicKey: credential.signerPublicKey,
  //           credentialBytes: credential.credentialBytes,
  //           groupId: groupId,
  //         );
  //       } catch (error) {
  //         // Group likely already exists.
  //       }
  //
  //       final allKeyPackages = devicesToAdding.expand((e) => e.value).toList();
  //       final addResult = await engine.addMembers(
  //         groupIdBytes: groupId,
  //         signerBytes: credential.signerBytes,
  //         keyPackagesBytes: allKeyPackages,
  //       );
  //       sharedCommit = addResult.commit;
  //       sharedWelcome = addResult.welcome;
  //     }
  //
  //     // Encrypt the application message once
  //     final groupMessage = await engine.createMessage(
  //       groupIdBytes: groupId,
  //       signerBytes: credential.signerBytes,
  //       message: Uint8List.fromList(utf8.encode(jsonEncode(message))),
  //     );
  //     sharedCiphertext = groupMessage.ciphertext;
  //
  //     // Create recipient entries
  //     for (final did in deviceKeyPackages.keys) {
  //       final isNew = deviceKeyPackages[did]!.isNotEmpty;
  //       recipients.add(
  //         EncryptedRecipient(
  //           to: did,
  //           from: senderDid,
  //           welcome: isNew ? sharedWelcome : null,
  //           commit: isNew
  //               ? null
  //               : sharedCommit, // Existing members need the commit
  //         ),
  //       );
  //     }
  //
  //     return EncryptedMessage(
  //       context: [
  //         'https://www.w3.org/ns/activitystreams',
  //         <String, String>{'ecp': 'https://www.w3.org/ns/activitystreams'},
  //       ],
  //       type: 'EncryptedMessage',
  //       id: null,
  //       recipients: recipients,
  //       attributedTo: senderId,
  //       to: [recipientId],
  //     );
  //   });
  // }

  // Future<StableActivity> parseMessage({
  //   required EncryptedMessage envelope,
  //   required Uri myDid,
  //   required Uri senderId,
  //   required Uri recipientId, // My ID
  // }) async {
  //     final recipientEntry = envelope.recipients.firstWhere(
  //       (r) => r.to == myDid,
  //       orElse: () =>
  //           throw Exception("Device $myDid not found in recipient list"),
  //     );
  //
  //     final groupId = deriveGroupId(a: senderId, b: recipientId);
  //     final credential = (await storage.mlsCredentialStore.getCredential())!;
  //
  //     // 1. If there's a welcome, join the group first
  //     if (recipientEntry.welcome != null) {
  //       await engine.joinGroupFromWelcome(
  //         config: await mlsConfig,
  //         welcomeBytes: recipientEntry.welcome!,
  //         signerBytes: credential.signerBytes,
  //       );
  //     }
  //
  //     // 2. If there's a commit, process it to update state
  //     if (recipientEntry.commit != null) {
  //       final processed = await engine.processMessage(
  //         groupIdBytes: groupId,
  //         messageBytes: recipientEntry.commit!,
  //       );
  //       if (processed.messageType == ProcessedMessageType.stagedCommit) {
  //         await engine.mergePendingCommit(groupIdBytes: groupId);
  //       }
  //     }
  //
  //     // 3. Process the application message
  //     if (envelope.ciphertext == null) {
  //       throw Exception('No application message in MLS envelope');
  //     }
  //
  //     final processed = await engine.processMessage(
  //       groupIdBytes: groupId,
  //       messageBytes: envelope.ciphertext!,
  //     );
  //
  //     if (processed.messageType != ProcessedMessageType.application) {
  //       throw Exception(
  //         'Expected application message, got ${processed.messageType}',
  //       );
  //     }
  //
  //     if (processed.applicationMessage == null) {
  //       throw Exception('Application message is null');
  //     }
  //
  //     return StableActivity.fromJson(
  //       jsonDecode(utf8.decode(processed.applicationMessage!)),
  //     );
  //   });
  // }
  //
  // Future<CreateMessageResult> encryptMessage(
  //   Uint8List groupId,
  //   Uint8List message,
  // ) async {
  //   return _withEngine((engine) async {
  //     final credential = (await storage.mlsCredentialStore.getCredential())!;
  //     return await engine.createMessage(
  //       groupIdBytes: groupId,
  //       signerBytes: credential.signerBytes,
  //       message: message,
  //     );
  //   });
  // }
  //
  // Future<ProcessedMessageResult> decryptMessage(
  //   Uint8List groupId,
  //   Uint8List ciphertext,
  // ) async {
  //   return _withEngine((engine) async {
  //     final processed = await engine.processMessage(
  //       groupIdBytes: groupId,
  //       messageBytes: ciphertext,
  //     );
  //     if (processed.messageType == ProcessedMessageType.stagedCommit) {
  //       await engine.mergePendingCommit(groupIdBytes: groupId);
  //     }
  //     return processed;
  //   });
  // }
}
