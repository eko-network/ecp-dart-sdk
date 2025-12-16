import 'dart:convert';
import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class KeyBundle {
  final int did; // UUID
  final Uint8List identityKey;
  final int registrationId;

  final int preKeyId;
  final Uint8List preKey;

  final int signedPreKeyId;
  final Uint8List signedPreKey;
  final Uint8List signedPreKeySignature;

  KeyBundle({
    required this.did,
    required this.identityKey,
    required this.registrationId,
    required this.preKeyId,
    required this.preKey,
    required this.signedPreKeyId,
    required this.signedPreKey,
    required this.signedPreKeySignature,
  });

  factory KeyBundle.fromJson(Map<String, dynamic> json) {
    return KeyBundle(
      did: json['did'],
      identityKey: base64Decode(json['identityKey']),
      registrationId: json['registrationId'],
      preKeyId: json['preKeyId'],
      preKey: base64Decode(json['preKey']),
      signedPreKeyId: json['signedPreKeyId'],
      signedPreKey: base64Decode(json['signedPreKey']),
      signedPreKeySignature: base64Decode(json['signedPreKeySignature']),
    );
  }

  Map<String, dynamic> toJson() => {
    'did': did,
    'identityKey': base64Encode(identityKey),
    'registrationId': registrationId,
    'preKeyId': preKeyId,
    'preKey': base64Encode(preKey),
    'signedPreKeyId': signedPreKeyId,
    'signedPreKey': base64Encode(signedPreKey),
    'signedPreKeySignature': base64Encode(signedPreKeySignature),
  };

  PreKeyBundle toPreKeyBundle() {
    return PreKeyBundle(
      registrationId,
      did,
      preKeyId,
      Curve.decodePoint(preKey, 0),
      signedPreKeyId,
      Curve.decodePoint(signedPreKey, 0),
      signedPreKeySignature,
      IdentityKey.fromBytes(identityKey, 0),
    );
  }
}
