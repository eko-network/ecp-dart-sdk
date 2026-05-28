// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../core/types/key_package.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeyPackage _$KeyPackageFromJson(Map<String, dynamic> json) => KeyPackage(
  key: const Uint8ListConverter().fromJson(json['key'] as String),
  did: json['did'] as String,
);

Map<String, dynamic> _$KeyPackageToJson(KeyPackage instance) =>
    <String, dynamic>{
      'key': const Uint8ListConverter().toJson(instance.key),
      'did': instance.did,
    };
