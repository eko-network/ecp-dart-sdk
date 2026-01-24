import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

part '../../generated/src/types/key_bundle.g.dart';

class Uint8ListConverter implements JsonConverter<Uint8List, String> {
  const Uint8ListConverter();

  @override
  Uint8List fromJson(String json) => base64Decode(json);

  @override
  String toJson(Uint8List object) => base64Encode(object);
}

@JsonSerializable()
class KeyBundle {
  @Uint8ListConverter()
  final int preKeyId;
  @Uint8ListConverter()
  final Uint8List preKey;

  final int signedPreKeyId;
  @Uint8ListConverter()
  final Uint8List signedPreKey;
  @Uint8ListConverter()
  final Uint8List signedPreKeySignature;

  KeyBundle({
    required this.preKeyId,
    required this.preKey,
    required this.signedPreKeyId,
    required this.signedPreKey,
    required this.signedPreKeySignature,
  });

  factory KeyBundle.fromJson(Map<String, dynamic> json) =>
      _$KeyBundleFromJson(json);

  Map<String, dynamic> toJson() => _$KeyBundleToJson(this);

  PreKeyBundle toPreKeyBundle({
    required int registrationId,
    required int did,
    required Uint8List identityKey,
  }) {
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
