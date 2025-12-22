import 'package:json_annotation/json_annotation.dart';
part '../../generated/src/types/person.g.dart';

@JsonSerializable()
class Person {
  @JsonKey(name: '@context')
  final dynamic context;

  @JsonKey(name: 'type')
  final String typeField;

  final Uri id;
  final Uri inbox;
  final Uri outbox;
  final Uri keyBundle;
  final String preferredUsername;

  Person({
    this.context = '',
    this.typeField = 'Person',
    required this.id,
    required this.inbox,
    required this.outbox,
    required this.keyBundle,
    required this.preferredUsername,
  });

  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);
  Map<String, dynamic> toJson() => _$PersonToJson(this);
}
