import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

part '../../../generated/src/core/types/key_package_bundle.g.dart';

class Uint8ListConverter implements JsonConverter<Uint8List, String> {
  const Uint8ListConverter();

  @override
  Uint8List fromJson(String json) => base64Decode(json);

  @override
  String toJson(Uint8List object) => base64Encode(object);
}

@JsonSerializable()
class KeyPackageBundle {
  @Uint8ListConverter()
  final Uint8List keyPackage;

  const KeyPackageBundle({required this.keyPackage});

  factory KeyPackageBundle.fromJson(Map<String, dynamic> json) =>
      _$KeyPackageBundleFromJson(json);

  factory KeyPackageBundle.fromTakeResponse(Map<String, dynamic> json) =>
      _$KeyPackageBundleFromJson(json['result']);

  Map<String, dynamic> toJson() => _$KeyPackageBundleToJson(this);
}
