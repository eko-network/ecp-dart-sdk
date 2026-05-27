import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import '../utils/b64.dart';

part '../../../generated/src/core/types/encrypted_message.g.dart';

@JsonSerializable(explicitToJson: true)
class EncryptedMessage {
  @JsonKey(name: '@context')
  final Object? context;

  @JsonKey(name: 'type')
  final String type;
  @JsonKey(includeToJson: false)
  final Uri? id;

  @Uint8ListConverter()
  final Uint8List? ciphertext;

  final List<EncryptedRecipient> recipients;
  final Uri attributedTo;
  final List<Uri> to;

  EncryptedMessage({
    required this.context,
    required this.type,
    required this.id,
    this.ciphertext,
    required this.recipients,
    required this.attributedTo,
    required this.to,
  });

  factory EncryptedMessage.fromJson(Map<String, dynamic> json) =>
      _$EncryptedMessageFromJson(json);
  Map<String, dynamic> toJson() => _$EncryptedMessageToJson(this);
}

@JsonSerializable()
class EncryptedRecipient {
  final Uri to;
  final Uri from;

  @Uint8ListConverter()
  final Uint8List? welcome;

  @Uint8ListConverter()
  final Uint8List? commit;

  EncryptedRecipient({
    required this.to,
    required this.from,
    this.welcome,
    this.commit,
  });

  factory EncryptedRecipient.fromJson(Map<String, dynamic> json) =>
      _$EncryptedRecipientFromJson(json);
  Map<String, dynamic> toJson() => _$EncryptedRecipientToJson(this);
}
