import 'dart:typed_data';

class MlsCredentialRecord {
  final Uint8List credentialIdentity;
  final Uint8List credentialBytes;
  final Uint8List signerBytes;
  final Uint8List signerPublicKey;

  const MlsCredentialRecord({
    required this.credentialIdentity,
    required this.credentialBytes,
    required this.signerBytes,
    required this.signerPublicKey,
  });
}
