import 'package:ecp/src/parts/utils.dart';
import 'package:uuid/uuid.dart';

import 'objects.dart';

final _uuid = Uuid();

/// Represents a generic activity.
sealed class Activity {
  String get type;
}

/// Represents an activity that is not persisted.
abstract class TransientActivity extends Activity {
  Map<String, dynamic> toJson();
  String get type;

  static final Map<
    String,
    TransientActivity Function(Map<String, dynamic> fromJson)
  >
  _factories = {'Typing': Typing.fromJson};

  static void registerActivity(
    String type,
    TransientActivity Function(Map<String, dynamic> fromJson) fromJson,
  ) {
    _factories[type] = fromJson;
  }

  factory TransientActivity.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) {
      throw ArgumentError('Activity JSON must have a "type" field');
    }
    final factory = _factories[type];
    if (factory != null) {
      return factory(json);
    }
    throw UnsupportedError('Unknown transient activity type: $type');
  }
}

/// Represents an activity that is persisted.
abstract class StableActivity {
  ActivityBase get base;
  Map<String, dynamic> toJson();
  String get type;

  static final Map<
    String,
    StableActivity Function(Map<String, dynamic> fromJson)
  >
  _factories = {
    'Create': Create.fromJson,
    'Update': Update.fromJson,
    'Delete': Delete.fromJson,
  };

  static void registerActivity(
    String type,
    StableActivity Function(Map<String, dynamic> fromJson) fromJson,
  ) {
    _factories[type] = fromJson;
  }

  factory StableActivity.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) {
      throw ArgumentError('Activity JSON must have a "type" field');
    }
    final factory = _factories[type];
    if (factory != null) {
      return factory(json);
    }
    throw UnsupportedError('Unknown activity type: $type');
  }
}

/// Base class for all activities, containing a unique ID.
class ActivityBase {
  final UuidValue id;

  ActivityBase({required this.id});

  factory ActivityBase.fromJson(Map<String, dynamic> json) {
    return ActivityBase(id: deserializeUuid(json['id'] as String));
  }

  Map<String, dynamic> toJson() => {'id': serializeUuid(id)};
}

/// Represents a typing activity.
class Typing implements TransientActivity {
  @override
  String get type => 'Typing';
  Typing();

  factory Typing.fromJson(Map<String, dynamic> json) {
    return Typing();
  }

  @override
  Map<String, dynamic> toJson() => {'type': type};
}

/// Represents an activity for creating an object.
class Create implements StableActivity {
  @override
  final ActivityBase base;
  final ActivityPubObject object;

  Create({required this.base, required this.object});

  @override
  String get type => 'Create';

  factory Create.fromJson(Map<String, dynamic> json) {
    return Create(
      base: ActivityBase.fromJson(json),
      object: ActivityPubObject.fromJson(
        json['object'] as Map<String, dynamic>,
      ),
    );
  }
  factory Create.note({String? content}) {
    return Create(
      base: ActivityBase(id: _uuid.v7obj()),
      object: Note(
        content: content,
        base: ObjectBase(id: _uuid.v7obj()),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = base.toJson();
    json['type'] = type;
    json['object'] = object.toJson();
    return json;
  }
}

/// Represents an activity for updating an object.
class Update implements StableActivity {
  @override
  final ActivityBase base;
  final ActivityPubObject object;

  Update({required this.base, required this.object});

  @override
  String get type => 'Update';

  factory Update.fromJson(Map<String, dynamic> json) {
    return Update(
      base: ActivityBase.fromJson(json),
      object: ActivityPubObject.fromJson(
        json['object'] as Map<String, dynamic>,
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = base.toJson();
    json['type'] = type;
    json['object'] = object.toJson();
    return json;
  }
}

/// Represents an activity for deleting an object.
class Delete implements StableActivity {
  @override
  final ActivityBase base;
  final DeletableObject object;

  Delete({required this.base, required this.object});
  @override
  String get type => 'Delete';

  factory Delete.fromJson(Map<String, dynamic> json) {
    final objectJson = json['object'];
    final DeletableObject object;

    object = switch (objectJson) {
      Map<String, dynamic> map => ObjectReference(
        ActivityPubObject.fromJson(map),
      ),
      String id => IdReference(deserializeUuid(id)),
      _ => throw FormatException(
        'Invalid format for Delete activity object: expected Map or String, got ${objectJson.runtimeType}',
      ),
    };

    return Delete(base: ActivityBase.fromJson(json), object: object);
  }

  @override
  Map<String, dynamic> toJson() {
    final json = base.toJson();
    json['type'] = type;
    json['object'] = object.serialize();
    return json;
  }
}

/// Sealed class representing an object that can be deleted.
sealed class DeletableObject {
  Object serialize();
}

/// References an `ActivityPubObject` for deletion.
class ObjectReference extends DeletableObject {
  final ActivityPubObject object;
  ObjectReference(this.object);

  @override
  Object serialize() => object.toJson();
}

/// References an object by its URI for deletion.
class IdReference extends DeletableObject {
  final UuidValue id;
  IdReference(this.id);

  @override
  Object serialize() => serializeUuid(id);
}
