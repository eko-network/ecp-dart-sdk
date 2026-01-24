import 'dart:typed_data';
import 'package:ecp/src/types/key_bundle.dart';
import 'package:json_annotation/json_annotation.dart';

part '../../generated/src/types/device_actions.g.dart';

/// Device action base class
sealed class DeviceAction {
  const DeviceAction();

  factory DeviceAction.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'AddDevice':
        return AddDevice.fromJson(json);
      case 'RevokeDevice':
        return RevokeDevice.fromJson(json);
      default:
        throw ArgumentError('Unknown device action type: $type');
    }
  }

  Map<String, dynamic> toJson();
}

/// Represents an AddDevice action in the Eko protocol
@JsonSerializable()
final class AddDevice extends DeviceAction {
  @JsonKey(name: '@context')
  final dynamic context;
  final Uri id;
  @JsonKey(fromJson: _prevFromJson, toJson: _prevToJson)
  final Uint8List? prev;
  final Uri did;
  final String keyCollection;
  @Uint8ListConverter()
  final Uint8List identityKey;
  final int registrationId;
  final List<DataIntegrityProof> proof;

  const AddDevice({
    required this.context,
    required this.id,
    this.prev,
    required this.did,
    required this.keyCollection,
    required this.identityKey,
    required this.registrationId,
    required this.proof,
  });

  factory AddDevice.fromJson(Map<String, dynamic> json) =>
      _$AddDeviceFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    final json = _$AddDeviceToJson(this);
    json['type'] = 'AddDevice';
    return json;
  }

  static Uint8List? _prevFromJson(String? hex) {
    if (hex == null) return null;
    final cleaned = hex.startsWith('0x') ? hex.substring(2) : hex;
    final bytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      bytes[i] = int.parse(cleaned.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }

  static String? _prevToJson(Uint8List? bytes) {
    if (bytes == null) return null;
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  static Uint8List _base64FromJson(String base64) {
    return Uint8List.fromList(base64.codeUnits);
  }

  static String _base64ToJson(Uint8List bytes) {
    return String.fromCharCodes(bytes);
  }
}

/// Represents a RevokeDevice action in the Eko protocol
@JsonSerializable()
final class RevokeDevice extends DeviceAction {
  @JsonKey(name: '@context')
  final dynamic context;
  final Uri id;
  final Uri did;
  @JsonKey(fromJson: AddDevice._prevFromJson, toJson: AddDevice._prevToJson)
  final Uint8List? prev;
  final List<DeviceProof> proof;

  const RevokeDevice({
    required this.context,
    required this.id,
    required this.did,
    this.prev,
    required this.proof,
  });

  factory RevokeDevice.fromJson(Map<String, dynamic> json) =>
      _$RevokeDeviceFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    final json = _$RevokeDeviceToJson(this);
    json['type'] = 'RevokeDevice';
    return json;
  }
}

/// Data Integrity Proof
@JsonSerializable()
class DataIntegrityProof {
  @JsonKey(name: 'type')
  final String typeField;
  final String cryptosuite;
  final String verificationMethod;
  final String proofPurpose;
  final String proofValue;

  const DataIntegrityProof({
    required this.typeField,
    required this.cryptosuite,
    required this.verificationMethod,
    required this.proofPurpose,
    required this.proofValue,
  });

  factory DataIntegrityProof.fromJson(Map<String, dynamic> json) =>
      _$DataIntegrityProofFromJson(json);

  Map<String, dynamic> toJson() => _$DataIntegrityProofToJson(this);
}

/// Proof entry for RevokeDevice
@JsonSerializable()
class DeviceProof {
  final String did;
  final String signature;

  const DeviceProof({required this.did, required this.signature});

  factory DeviceProof.fromJson(Map<String, dynamic> json) =>
      _$DeviceProofFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceProofToJson(this);
}
