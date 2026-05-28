// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../core/types/identity_bundle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IdentityBundle _$IdentityBundleFromJson(Map<String, dynamic> json) =>
    IdentityBundle(
      credentialIdentity: const Uint8ListConverter().fromJson(
        json['credentialIdentity'] as String,
      ),
      credential: const Uint8ListConverter().fromJson(
        json['credential'] as String,
      ),
      signer: const Uint8ListConverter().fromJson(json['signer'] as String),
      signerPublicKey: const Uint8ListConverter().fromJson(
        json['signerPublicKey'] as String,
      ),
      keyPackages: (json['keyPackages'] as List<dynamic>)
          .map((e) => const Uint8ListConverter().fromJson(e as String))
          .toList(),
    );

Map<String, dynamic> _$IdentityBundleToJson(IdentityBundle instance) =>
    <String, dynamic>{
      'credentialIdentity': const Uint8ListConverter().toJson(
        instance.credentialIdentity,
      ),
      'credential': const Uint8ListConverter().toJson(instance.credential),
      'signer': const Uint8ListConverter().toJson(instance.signer),
      'signerPublicKey': const Uint8ListConverter().toJson(
        instance.signerPublicKey,
      ),
      'keyPackages': instance.keyPackages
          .map(const Uint8ListConverter().toJson)
          .toList(),
    };
