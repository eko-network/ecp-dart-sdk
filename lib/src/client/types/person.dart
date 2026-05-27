import 'package:json_annotation/json_annotation.dart';
part '../../../generated/src/client/types/person.g.dart';

@JsonSerializable()
class Person {
  @JsonKey(name: '@context')
  final Object? context;

  @JsonKey(name: 'type')
  final String type;

  final Uri id;
  final Uri inbox;
  final Uri outbox;
  final Uri devicesEndpoint;

  Person({
    this.context = '',
    this.type = 'Person',
    required this.id,
    required this.inbox,
    required this.outbox,
    required this.devicesEndpoint,
  });

  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);
  Map<String, dynamic> toJson() => _$PersonToJson(this);
}
