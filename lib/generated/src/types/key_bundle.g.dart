// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../src/types/key_bundle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeyBundle _$KeyBundleFromJson(Map<String, dynamic> json) => KeyBundle(
  preKeyId: (json['preKeyId'] as num).toInt(),
  preKey: const Uint8ListConverter().fromJson(json['preKey'] as String),
  signedPreKeyId: (json['signedPreKeyId'] as num).toInt(),
  signedPreKey: const Uint8ListConverter().fromJson(
    json['signedPreKey'] as String,
  ),
  signedPreKeySignature: const Uint8ListConverter().fromJson(
    json['signedPreKeySignature'] as String,
  ),
);

Map<String, dynamic> _$KeyBundleToJson(KeyBundle instance) => <String, dynamic>{
  'preKeyId': instance.preKeyId,
  'preKey': const Uint8ListConverter().toJson(instance.preKey),
  'signedPreKeyId': instance.signedPreKeyId,
  'signedPreKey': const Uint8ListConverter().toJson(instance.signedPreKey),
  'signedPreKeySignature': const Uint8ListConverter().toJson(
    instance.signedPreKeySignature,
  ),
};
