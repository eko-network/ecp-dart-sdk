import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import '../utils/b64.dart';

part '../../../generated/src/core/types/encrypted_message.g.dart';

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

  @Uint8ListConverter()
  final List<Uint8List> content;

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
    List<Uint8List>? content,
  }) {
    return EncryptedMessageEntry(
      to: to ?? this.to,
      from: from ?? this.from,
      content: content ?? this.content,
    );
  }
}
