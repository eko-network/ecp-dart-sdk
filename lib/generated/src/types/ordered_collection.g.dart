// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../src/types/ordered_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderedCollection _$OrderedCollectionFromJson(Map<String, dynamic> json) =>
    OrderedCollection(
      context: json['@context'],
      typeField: json['type'] as String,
      id: json['id'] as String,
      totalItems: (json['totalItems'] as num).toInt(),
      orderedItems: json['orderedItems'] as List<dynamic>,
    );

Map<String, dynamic> _$OrderedCollectionToJson(OrderedCollection instance) =>
    <String, dynamic>{
      '@context': instance.context,
      'type': instance.typeField,
      'id': instance.id,
      'totalItems': instance.totalItems,
      'orderedItems': instance.orderedItems,
    };
