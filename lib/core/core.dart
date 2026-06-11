import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:ecp/ecp.dart';

class EcpCore {
  final Storage storage;
  final MlsEngineConfig engineConfig;
  MlsGroupConfig? _mlsConfig;
  MlsEngine? _engine;
  final Person identity;

  EcpCore({
    required this.storage,
    required this.identity,
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
    try {
      _engine = await _getEngine();
    } catch (e) {
      if (e.toString().contains('Encryption key verification failed')) {
        _engine = null;
        if (await File(engineConfig.dbPath).exists()) {
          await File(engineConfig.dbPath).delete();
        }
        await storage.mlsEngineConfigStore.clearConfig();
      }
      rethrow;
    }
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
    final credentialIdentity = utf8.encode(identity.id.toString());
    final storedRecord = await storage.mlsCredentialStore.getCredential();
    final MlsCredentialRecord record;
    if (storedRecord != null) {
      record = storedRecord;
    } else {
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
      record = MlsCredentialRecord(
        credentialIdentity: credentialIdentity,
        credentialBytes: credentialBytes,
        signerBytes: signerBytes,
        signerPublicKey: signerPublicKey,
      );
      await storage.mlsCredentialStore.saveCredential(record);
    }
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

  Future<List<Person>> getMembers(Uint8List groupId) async {
    final members = await engine.groupMembers(groupIdBytes: groupId);
    final people = members.map(
      (m) => Person.fromId(
        Uri.parse(
          utf8.decode(
            MlsCredential.deserialize(bytes: m.credential).identity(),
          ),
        ),
      ),
    );
    final List<Person> upeople = [];
    final Set<Uri> added = {};
    for (final p in people) {
      if (added.add(p.id)) {
        upeople.add(p);
      }
    }

    return upeople;
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

  Future<JoinGroupResult> joinFromWelcome(Uint8List welcomeBytes) async {
    final credential = (await storage.mlsCredentialStore.getCredential())!;
    return await engine.joinGroupFromWelcome(
      config: await mlsConfig,
      welcomeBytes: welcomeBytes,
      signerBytes: credential.signerBytes,
    );
  }

  /// Decrypt a [PrivateMessage] MLS ciphertext.
  Future<(Activity, Uint8List)?> decryptPrivateMessage({
    required Uint8List ciphertext,
  }) async {
    final groupId = mlsMessageExtractGroupId(messageBytes: ciphertext);
    final processed = await engine.processMessage(
      groupIdBytes: groupId,
      messageBytes: ciphertext,
    );

    switch (processed.messageType) {
      case ProcessedMessageType.stagedCommit:
        await engine.mergePendingCommit(groupIdBytes: groupId);
        return null;
      case ProcessedMessageType.proposal:
        // I don't know if this requires action or not
        return null;
      case ProcessedMessageType.application:
        final applicationMessage = processed.applicationMessage;
        if (applicationMessage == null) {
          return null;
        }
        return (
          Activity.fromJson(
            jsonDecode(utf8.decode(applicationMessage)) as Map<String, dynamic>,
          ),
          groupId,
        );
    }
  }

  Future<WireActivity> encryptActivity(Activity activity, groupId) async {
    final credential = (await storage.mlsCredentialStore.getCredential())!;
    final content = await engine.createMessage(
      groupIdBytes: groupId,
      signerBytes: credential.signerBytes,
      message: utf8.encode(jsonEncode(activity.toJson())),
    );
    final recipinants = (await getMembers(groupId).then(
      (ps) => ps.map((p) => p.id),
    )).toList()..removeWhere((u) => u == identity.id);
    final message = PrivateMessage(
      actor: identity.id,
      to: recipinants,
      content: content.ciphertext,
    );
    return WireCreate(to: recipinants, object: message, actor: identity.id);
  }
}
