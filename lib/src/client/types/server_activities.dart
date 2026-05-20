import '../../core/types/encrypted_message.dart';

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
      case 'Delivered':
        return Delivered.fromJson(json);
      default:
        throw UnsupportedError('Unknown activity type: ${json['type']}');
    }
  }
}

class RemoteActivityBase {
  final Uri? id;
  final Uri actor;
  final dynamic context;
  final Uri to;

  RemoteActivityBase({
    required this.id,
    required this.actor,
    this.context,
    required this.to,
  });

  factory RemoteActivityBase.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    return RemoteActivityBase(
      to: Uri.parse((json['to'] as List).first as String),
      id: id == null ? null : Uri.parse(id),
      actor: Uri.parse(json['actor'] as String),
      context: json['@context'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'actor': actor.toString(),
      '@context': context ?? "TODO",
      'to': [to.toString()],
    };

    return json;
  }

  RemoteActivityBase copyWith({Uri? id, Uri? actor, dynamic context, Uri? to}) {
    return RemoteActivityBase(
      id: id ?? this.id,
      actor: actor ?? this.actor,
      context: context ?? this.context,
      to: to ?? this.to,
    );
  }
}

class Take implements ServerActivity {
  final RemoteActivityBase base;
  @override
  String get type => 'Take';
  Take({required this.base});
  @override
  Map<String, dynamic> toJson() {
    final json = base.toJson();
    json['type'] = type;
    return json;
  }

  Take copyWith({RemoteActivityBase? base, Uri? target}) {
    return Take(base: base ?? this.base);
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

class Delivered implements ServerActivity {
  @override
  final RemoteActivityBase base;
  final String object; // The ID of the Create activity being acknowledged

  Delivered({required this.base, required this.object});

  @override
  String get type => 'Delivered';

  factory Delivered.fromJson(Map<String, dynamic> json) {
    return Delivered(
      base: RemoteActivityBase.fromJson(json),
      object: json['object'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = base.toJson();
    json['type'] = type;
    json['object'] = object;
    return json;
  }

  Delivered copyWith({RemoteActivityBase? base, String? object}) {
    return Delivered(base: base ?? this.base, object: object ?? this.object);
  }
}
