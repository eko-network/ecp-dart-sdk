// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../src/core/types/device_actions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddDevice _$AddDeviceFromJson(Map<String, dynamic> json) => AddDevice(
  context: json['@context'],
  id: Uri.parse(json['id'] as String),
  prev: AddDevice._prevFromJson(json['prev'] as String?),
  did: Uri.parse(json['did'] as String),
  keyCollection: json['keyCollection'] as String,
  credentialIdentity: const Uint8ListConverter().fromJson(
    json['credentialIdentity'] as String,
  ),
  signerPublicKey: const Uint8ListConverter().fromJson(
    json['signerPublicKey'] as String,
  ),
  proof: (json['proof'] as List<dynamic>)
      .map((e) => DataIntegrityProof.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$AddDeviceToJson(AddDevice instance) => <String, dynamic>{
  '@context': instance.context,
  'id': instance.id.toString(),
  'prev': AddDevice._prevToJson(instance.prev),
  'did': instance.did.toString(),
  'keyCollection': instance.keyCollection,
  'credentialIdentity': const Uint8ListConverter().toJson(
    instance.credentialIdentity,
  ),
  'signerPublicKey': const Uint8ListConverter().toJson(
    instance.signerPublicKey,
  ),
  'proof': instance.proof,
};

RevokeDevice _$RevokeDeviceFromJson(Map<String, dynamic> json) => RevokeDevice(
  context: json['@context'],
  id: Uri.parse(json['id'] as String),
  did: Uri.parse(json['did'] as String),
  prev: AddDevice._prevFromJson(json['prev'] as String?),
  proof: (json['proof'] as List<dynamic>)
      .map((e) => DeviceProof.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$RevokeDeviceToJson(RevokeDevice instance) =>
    <String, dynamic>{
      '@context': instance.context,
      'id': instance.id.toString(),
      'did': instance.did.toString(),
      'prev': AddDevice._prevToJson(instance.prev),
      'proof': instance.proof,
    };

DataIntegrityProof _$DataIntegrityProofFromJson(Map<String, dynamic> json) =>
    DataIntegrityProof(
      typeField: json['type'] as String,
      cryptosuite: json['cryptosuite'] as String,
      verificationMethod: json['verificationMethod'] as String,
      proofPurpose: json['proofPurpose'] as String,
      proofValue: json['proofValue'] as String,
    );

Map<String, dynamic> _$DataIntegrityProofToJson(DataIntegrityProof instance) =>
    <String, dynamic>{
      'type': instance.typeField,
      'cryptosuite': instance.cryptosuite,
      'verificationMethod': instance.verificationMethod,
      'proofPurpose': instance.proofPurpose,
      'proofValue': instance.proofValue,
    };

DeviceProof _$DeviceProofFromJson(Map<String, dynamic> json) => DeviceProof(
  did: json['did'] as String,
  signature: json['signature'] as String,
);

Map<String, dynamic> _$DeviceProofToJson(DeviceProof instance) =>
    <String, dynamic>{'did': instance.did, 'signature': instance.signature};
