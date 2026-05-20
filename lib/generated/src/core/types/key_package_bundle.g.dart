// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../src/core/types/key_package_bundle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeyPackageBundle _$KeyPackageBundleFromJson(Map<String, dynamic> json) =>
    KeyPackageBundle(
      keyPackage: const Uint8ListConverter().fromJson(
        json['keyPackage'] as String,
      ),
    );

Map<String, dynamic> _$KeyPackageBundleToJson(KeyPackageBundle instance) =>
    <String, dynamic>{
      'keyPackage': const Uint8ListConverter().toJson(instance.keyPackage),
    };
