// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../src/core/types/device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Device _$DeviceFromJson(Map<String, dynamic> json) => Device(
  context: json['@context'],
  id: Uri.parse(json['id'] as String),
  did: json['did'] as String,
  keyCollection: Uri.parse(json['keyCollection'] as String),
  publicKey: const Uint8ListConverter().fromJson(json['publicKey'] as String),
);

Map<String, dynamic> _$DeviceToJson(Device instance) => <String, dynamic>{
  '@context': instance.context,
  'id': instance.id.toString(),
  'did': instance.did,
  'keyCollection': instance.keyCollection.toString(),
  'publicKey': const Uint8ListConverter().toJson(instance.publicKey),
};
