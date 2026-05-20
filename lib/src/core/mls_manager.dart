import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:openmls/openmls.dart';
import 'types/storage.dart';
import 'types/identity_bundle.dart';

class MlsManager {
  final Storage storage;
  final MlsGroupConfig mlsConfig;

  MlsManager({
    required this.storage,
    MlsGroupConfig? mlsConfig,
  }) : mlsConfig = mlsConfig ??
            MlsGroupConfig.defaultConfig(
              ciphersuite:
                  MlsCiphersuite.mls128DhkemX25519Aes128GcmSha256Ed25519,
            );

  Future<MlsEngine> createEngine() async {
    await Openmls.init();
    final config = await storage.mlsEngineConfigStore.getConfig();
    return MlsEngine.create(
      dbPath: config.dbPath,
      encryptionKey: config.encryptionKey,
    );
  }

  Uint8List deriveGroupId({required Uri a, required Uri b}) {
    final ids = [a.toString(), b.toString()]..sort();
    final data = utf8.encode('ecp-mls:${ids.join("|")}');
    final digest = sha256.convert(data);
    return Uint8List.fromList(digest.bytes);
  }

  Future<IdentityBundle> initializeIdentity({
    required Uint8List credentialIdentity,
    int numKeyPackages = 50,
  }) async {
    return IdentityBundle.fromUser(
      credentialIdentity: credentialIdentity,
      storage: storage,
      numKeyPackages: numKeyPackages,
    );
  }

  Future<void> createGroup(Uint8List groupId) async {
    final engine = await createEngine();
    final credential = (await storage.mlsCredentialStore.getCredential())!;
    try {
      await engine.createGroup(
        config: mlsConfig,
        signerBytes: credential.signerBytes,
        credentialIdentity: credential.credentialIdentity,
        signerPublicKey: credential.signerPublicKey,
        credentialBytes: credential.credentialBytes,
        groupId: groupId,
      );
    } finally {
      await engine.close();
    }
  }

  Future<AddMembersResult> addMembers(
    Uint8List groupId,
    List<Uint8List> keyPackages,
  ) async {
    final engine = await createEngine();
    final credential = (await storage.mlsCredentialStore.getCredential())!;
    try {
      return await engine.addMembers(
        groupIdBytes: groupId,
        signerBytes: credential.signerBytes,
        keyPackagesBytes: keyPackages,
      );
    } finally {
      await engine.close();
    }
  }

  Future<void> joinGroupFromWelcome(Uint8List welcomeBytes) async {
    final engine = await createEngine();
    final credential = (await storage.mlsCredentialStore.getCredential())!;
    try {
      await engine.joinGroupFromWelcome(
        config: mlsConfig,
        welcomeBytes: welcomeBytes,
        signerBytes: credential.signerBytes,
      );
    } finally {
      await engine.close();
    }
  }

  Future<CreateMessageResult> encryptMessage(
    Uint8List groupId,
    Uint8List message,
  ) async {
    final engine = await createEngine();
    final credential = (await storage.mlsCredentialStore.getCredential())!;
    try {
      return await engine.createMessage(
        groupIdBytes: groupId,
        signerBytes: credential.signerBytes,
        message: message,
      );
    } finally {
      await engine.close();
    }
  }

  Future<ProcessedMessageResult> decryptMessage(
    Uint8List groupId,
    Uint8List ciphertext,
  ) async {
    final engine = await createEngine();
    try {
      final processed = await engine.processMessage(
        groupIdBytes: groupId,
        messageBytes: ciphertext,
      );
      if (processed.messageType == ProcessedMessageType.stagedCommit) {
        await engine.mergePendingCommit(groupIdBytes: groupId);
      }
      return processed;
    } finally {
      await engine.close();
    }
  }
}
