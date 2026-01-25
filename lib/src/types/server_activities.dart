import 'encrypted_message.dart';

abstract class ServerActivity {
  RemoteActivityBase get base;

  String get type;

  Map<String, dynamic> toJson();

  factory ServerActivity.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'Create':
        return Create.fromJson(json);
      case 'Reject':
        return Reject.fromJson(json);
      default:
        throw UnsupportedError('Unknown activity type: ${json['type']}');
    }
  }
}

class RemoteActivityBase {
  final Uri? id;
  final Uri actor;
  final dynamic context;

  RemoteActivityBase({required this.id, required this.actor, this.context});

  factory RemoteActivityBase.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    return RemoteActivityBase(
      id: id == null ? null : Uri.parse(id),
      actor: Uri.parse(json['actor']),
      context: json['@context'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'actor': actor.toString(),
      '@context': context ?? "TODO",
    };

    return json;
  }

  RemoteActivityBase copyWith({Uri? id, Uri? actor, dynamic context}) {
    return RemoteActivityBase(
      id: id ?? this.id,
      actor: actor ?? this.actor,
      context: context ?? this.context,
    );
  }
}

class Take implements ServerActivity {
  final Uri target;
  final RemoteActivityBase base;
  @override
  String get type => 'Take';
  Take({required this.base, required this.target});
  @override
  Map<String, dynamic> toJson() {
    final json = base.toJson();
    json['type'] = type;
    json['target'] = target.toString();
    return json;
  }

  Take copyWith({RemoteActivityBase? base, Uri? target}) {
    return Take(base: base ?? this.base, target: target ?? this.target);
  }
}

class Create implements ServerActivity {
  @override
  final RemoteActivityBase base;
  final EncryptedMessage object;

  Create({required this.base, required this.object});

  @override
  String get type => 'Create';

  factory Create.fromJson(Map<String, dynamic> json) {
    return Create(
      base: RemoteActivityBase.fromJson(json),
      object: EncryptedMessage.fromJson(json['object'] as Map<String, dynamic>),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = base.toJson();
    json['type'] = type;
    json['object'] = object.toJson();
    return json;
  }

  Create copyWith({RemoteActivityBase? base, EncryptedMessage? object}) {
    return Create(base: base ?? this.base, object: object ?? this.object);
  }
}

class Reject implements ServerActivity {
  @override
  final RemoteActivityBase base;
  // This can be the Uri of an object or the object itself
  final dynamic object;

  Reject({required this.base, required this.object});

  @override
  String get type => 'Reject';

  factory Reject.fromJson(Map<String, dynamic> json) {
    final objectJson = json['object'];
    dynamic object;
    if (objectJson is String) {
      object = Uri.parse(objectJson);
    } else {
      object = objectJson;
    }

    return Reject(base: RemoteActivityBase.fromJson(json), object: object);
  }

  @override
  Map<String, dynamic> toJson() {
    throw UnimplementedError();
  }

  Reject copyWith({RemoteActivityBase? base, dynamic object}) {
    return Reject(base: base ?? this.base, object: object ?? this.object);
  }
}
