import 'dart:convert';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class CurrentUserKeys {
  final IdentityKeyPair identityKeyPair;
  final int registrationId;
  final List<PreKeyRecord> preKeys;
  final SignedPreKeyRecord signedPreKey;
  CurrentUserKeys({
    required this.identityKeyPair,
    required this.registrationId,
    required this.preKeys,
    required this.signedPreKey,
  });

  Map<String, dynamic> toJson() {
    final requestBody = <String, dynamic>{};
    requestBody['identityKey'] = base64.encode(
      identityKeyPair.getPublicKey().serialize(),
    );
    requestBody['registrationId'] = registrationId;
    requestBody['preKeys'] = preKeys
        .map(
          (p) => {
            'id': p.id,
            'key': base64.encode(p.getKeyPair().publicKey.serialize()),
          },
        )
        .toList();
    requestBody['signedPreKey'] = {
      'id': signedPreKey.id,
      'key': base64.encode(signedPreKey.getKeyPair().publicKey.serialize()),
      'signature': base64.encode(signedPreKey.signature),
    };
    return requestBody;
  }
}
