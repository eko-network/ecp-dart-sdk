import 'dart:typed_data';
import 'package:ecp/core/utils/converters.dart';
import 'package:json_annotation/json_annotation.dart';

part '../../generated/core/types/key_package.g.dart';

@JsonSerializable()
class KeyPackage {
  @Uint8ListConverter()
  final Uint8List key;
  final String did;

  const KeyPackage({required this.key, required this.did});

  factory KeyPackage.fromJson(Map<String, dynamic> json) =>
      _$KeyPackageFromJson(json);

  factory KeyPackage.fromTakeResponse(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is! Map<String, dynamic>) {
      throw ArgumentError('Take response missing result');
    }
    return KeyPackage.fromJson(result);
  }

  Map<String, dynamic> toJson() => _$KeyPackageToJson(this);
}
