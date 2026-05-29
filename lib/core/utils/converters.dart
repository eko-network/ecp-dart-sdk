import 'dart:convert';
import 'dart:typed_data';

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
