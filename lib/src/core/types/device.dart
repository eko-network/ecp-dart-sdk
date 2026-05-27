import 'dart:typed_data';

import 'package:ecp/src/core/utils/b64.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part '../../../generated/src/core/types/device.g.dart';

/// Represents a Device in the Eko protocol
@JsonSerializable()
class Device {
  @JsonKey(name: '@context')
  final Object? context;
  final Uri id;
  final String did;
  final Uri keyCollection;
  @Uint8ListConverter()
  final Uint8List publicKey;

  const Device({
    required this.context,
    required this.id,
    required this.did,
    required this.keyCollection,
    required this.publicKey,
  });

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);

  Map<String, dynamic> toJson() {
    final json = _$DeviceToJson(this);
    json['type'] = 'Device';
    return json;
  }
}
