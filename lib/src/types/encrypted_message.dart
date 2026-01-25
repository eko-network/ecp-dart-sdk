import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

part '../../generated/src/types/encrypted_message.g.dart';

class CiphertextSerializer {
  static Uint8List serialize(CiphertextMessage message) {
    final type = message.getType();
    final data = message.serialize();
    final result = Uint8List(1 + data.length);
    result[0] = type;
    result.setRange(1, result.length, data);

    return result;
  }

  static CiphertextMessage deserialize(Uint8List serialized) {
    if (serialized.isEmpty) {
      throw ArgumentError('Cannot deserialize empty data');
    }

    final type = serialized[0];
    final data = serialized.sublist(1);

    switch (type) {
      case CiphertextMessage.prekeyType:
        return PreKeySignalMessage(data);

      case CiphertextMessage.whisperType:
        return SignalMessage.fromSerialized(data);

      case CiphertextMessage.senderKeyType:
        return SenderKeyMessage.fromSerialized(data);

      case CiphertextMessage.senderKeyDistributionType:
        return SenderKeyDistributionMessageWrapper.fromSerialized(data);

      default:
        throw ArgumentError('Unknown message type: $type');
    }
  }
}

@JsonSerializable(explicitToJson: true)
class EncryptedMessage {
  @JsonKey(name: '@context')
  final dynamic context;

  @JsonKey(name: 'type')
  final String typeField;
  @JsonKey(includeToJson: false)
  final Uri? id;
  final List<EncryptedMessageEntry> content;
  final Uri attributedTo;
  final List<Uri> to;

  EncryptedMessage({
    required this.context,
    required this.typeField,
    required this.id,
    required this.content,
    required this.attributedTo,
    required this.to,
  });

  factory EncryptedMessage.fromJson(Map<String, dynamic> json) =>
      _$EncryptedMessageFromJson(json);
  Map<String, dynamic> toJson() => _$EncryptedMessageToJson(this);

  EncryptedMessage copyWith({
    dynamic context,
    String? typeField,
    Uri? id,
    List<EncryptedMessageEntry>? content,
    Uri? attributedTo,
    List<Uri>? to,
  }) {
    return EncryptedMessage(
      context: context ?? this.context,
      typeField: typeField ?? this.typeField,
      id: id ?? this.id,
      content: content ?? this.content,
      attributedTo: attributedTo ?? this.attributedTo,
      to: to ?? this.to,
    );
  }
}

@JsonSerializable()
class EncryptedMessageEntry {
  final Uri to;
  final Uri from;

  @JsonKey(fromJson: _de, toJson: _se)
  final CiphertextMessage content;

  EncryptedMessageEntry({
    required this.to,
    required this.from,
    required this.content,
  });

  factory EncryptedMessageEntry.fromJson(Map<String, dynamic> json) =>
      _$EncryptedMessageEntryFromJson(json);
  Map<String, dynamic> toJson() => _$EncryptedMessageEntryToJson(this);

  EncryptedMessageEntry copyWith({
    Uri? to,
    Uri? from,
    CiphertextMessage? content,
  }) {
    return EncryptedMessageEntry(
      to: to ?? this.to,
      from: from ?? this.from,
      content: content ?? this.content,
    );
  }

  static CiphertextMessage _de(String base64) =>
      CiphertextSerializer.deserialize(base64Decode(base64));
  static String _se(CiphertextMessage m) =>
      base64Encode(CiphertextSerializer.serialize(m));
}
