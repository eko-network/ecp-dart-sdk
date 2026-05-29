import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

const String _uuidPrefix = "urn:uuid:";
const _uuid = Uuid();

class InternalIdConverter implements JsonConverter<InternalId, String> {
  const InternalIdConverter();

  @override
  InternalId fromJson(String json) => InternalId.fromSerialized(json);

  @override
  String toJson(InternalId object) => object.serialize();
}

class InternalId {
  late final Uint8List _id;

  InternalId({required Uint8List id}) {
    assert(Uuid.isValidUUID(fromByteList: id), "invalid uid");
    this._id = id;
  }

  String serialize() {
    return '$_uuidPrefix${Uuid.unparse(_id)}';
  }

  factory InternalId.gen() {
    return InternalId(id: _uuid.v7obj().toBytes());
  }

  factory InternalId.fromString(String string) {
    return InternalId(id: Uint8List.fromList(Uuid.parse(string)));
  }

  factory InternalId.fromSerialized(String string) {
    return InternalId.fromString(string.replaceFirst(_uuidPrefix, ''));
  }
}
