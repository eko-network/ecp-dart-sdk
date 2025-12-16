import 'package:ecp/src/types/encrypted_message.dart';
import 'package:json_annotation/json_annotation.dart';
part 'create_activity.g.dart';

@JsonSerializable(explicitToJson: true)
class CreateActivity {
  @JsonKey(name: '@context')
  final dynamic context;

  @JsonKey(name: 'type')
  final String typeField;
  @JsonKey(includeToJson: false)
  final Uri? id;
  final Uri actor;
  final EncryptedMessage object;

  CreateActivity({
    required this.context,
    required this.typeField,
    required this.id,
    required this.actor,
    required this.object,
  });

  factory CreateActivity.fromJson(Map<String, dynamic> json) =>
      _$CreateActivityFromJson(json);
  Map<String, dynamic> toJson() => _$CreateActivityToJson(this);
}
