import 'dart:typed_data';
import 'package:ecp/src/core/types/storage.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:openmls/openmls.dart';
import '../utils/b64.dart';
import 'mls_credential_record.dart';

part '../../../generated/src/core/types/identity_bundle.g.dart';

@JsonSerializable()
class IdentityBundle {
  @Uint8ListConverter()
  final Uint8List credentialIdentity;
  @Uint8ListConverter()
  final Uint8List credential;
  @Uint8ListConverter()
  final Uint8List signer;
  @Uint8ListConverter()
  final Uint8List signerPublicKey;
  @Uint8ListConverter()
  final List<Uint8List> keyPackages;

  const IdentityBundle({
    required this.credentialIdentity,
    required this.credential,
    required this.signer,
    required this.signerPublicKey,
    required this.keyPackages,
  });

  factory IdentityBundle.fromJson(Map<String, dynamic> json) =>
      _$IdentityBundleFromJson(json);

  static Future<IdentityBundle> fromUser({
    required Uint8List credentialIdentity,
    required Storage storage,
    int numKeyPackages = 50,
  }) async {
    await Openmls.init();
    final existingCredential = await storage.mlsCredentialStore.getCredential();
    if (existingCredential == null) {
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
      await storage.mlsCredentialStore.saveCredential(record);
    }

    final credential = (await storage.mlsCredentialStore.getCredential())!;
    final engineConfig = await storage.mlsEngineConfigStore.getConfig();
    final engine = await MlsEngine.create(
      dbPath: engineConfig.dbPath,
      encryptionKey: engineConfig.encryptionKey,
    );

    final keyPackages = <Uint8List>[];
    for (var i = 0; i < numKeyPackages; i++) {
      final keyPackage = await engine.createKeyPackage(
        ciphersuite: MlsCiphersuite.mls128DhkemX25519Aes128GcmSha256Ed25519,
        signerBytes: credential.signerBytes,
        credentialIdentity: credential.credentialIdentity,
        signerPublicKey: credential.signerPublicKey,
        credentialBytes: credential.credentialBytes,
      );
      keyPackages.add(keyPackage.keyPackageBytes);
    }
    await storage.mlsKeyPackageStore.saveKeyPackages(keyPackages);
    await engine.close();

    return IdentityBundle(
      credentialIdentity: credential.credentialIdentity,
      credential: credential.credentialBytes,
      signer: credential.signerBytes,
      signerPublicKey: credential.signerPublicKey,
      keyPackages: keyPackages,
    );
  }

  Map<String, dynamic> toJson() => _$IdentityBundleToJson(this);
}
