import 'package:uuid/uuid.dart';

const String _uuidPrefix = "urn:uuid:";
String serializeUuid(UuidValue id) => "$_uuidPrefix$id";
UuidValue deserializeUuid(String id) =>
    UuidValue.fromString(id.replaceFirst(_uuidPrefix, ''));
