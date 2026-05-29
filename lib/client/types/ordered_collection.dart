import 'package:json_annotation/json_annotation.dart';

part '../../generated/client/types/ordered_collection.g.dart';

/// Represents an ActivityPub OrderedCollection
@JsonSerializable()
class OrderedCollection {
  @JsonKey(name: '@context')
  final Object? context;

  @JsonKey(name: 'type')
  final String type;

  final String id;
  final int totalItems;
  final List<dynamic> orderedItems;

  OrderedCollection({
    required this.context,
    required this.type,
    required this.id,
    required this.totalItems,
    required this.orderedItems,
  });

  factory OrderedCollection.fromJson(Map<String, dynamic> json) =>
      _$OrderedCollectionFromJson(json);

  Map<String, dynamic> toJson() => _$OrderedCollectionToJson(this);
}
