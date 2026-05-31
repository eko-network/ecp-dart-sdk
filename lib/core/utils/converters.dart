import 'dart:convert';
import 'dart:typed_data';

import 'package:ecp/core/types/key_package.dart';
import 'package:json_annotation/json_annotation.dart';

class Uint8ListConverter implements JsonConverter<Uint8List, String> {
  const Uint8ListConverter();
  @override
  Uint8List fromJson(String json) => base64Decode(json);
  @override
  String toJson(Uint8List object) => base64Encode(object);
}

class UriConverter implements JsonConverter<Uri, String> {
  const UriConverter();
  @override
  Uri fromJson(String json) => Uri.parse(json);
  @override
  String toJson(Uri uri) => uri.toString();
}

class KeyPackageConvertor implements JsonConverter<KeyPackage, String> {
  const KeyPackageConvertor();
  @override
  KeyPackage fromJson(String json) =>
      KeyPackage.fromJson(jsonDecode(json) as Map<String, dynamic>);
  @override
  String toJson(KeyPackage kp) => jsonEncode(kp);
}
