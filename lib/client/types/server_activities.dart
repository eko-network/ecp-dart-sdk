import '../../core/types/encrypted_message.dart';

const List<Object?> ecpJsonLdContext = [
  'https://www.w3.org/ns/activitystreams',
  <String, String>{'ecp': 'https://www.w3.org/ns/activitystreams'},
];

abstract class WireActivity {
  WireActivityBase get base;

  String get type;

  Map<String, dynamic> toJson();

  factory WireActivity.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'Create':
        return WireCreate.fromJson(json);
      case 'Reject':
        return WireReject.fromJson(json);
      case 'Delivered':
        return WireDelivered.fromJson(json);
      default:
        throw UnsupportedError('Unknown activity type: ${json['type']}');
    }
  }
}

class WireActivityBase {
  final Uri? id;
  final Uri actor;
  final Object? context;
  final Uri to;

  WireActivityBase({
    required this.id,
    required this.actor,
    Object? context,
    required this.to,
  }) : context = context ?? ecpJsonLdContext;

  factory WireActivityBase.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    return WireActivityBase(
      to: Uri.parse((json['to'] as List).first as String),
      id: id == null ? null : Uri.parse(id),
      actor: Uri.parse(json['actor'] as String),
      context: json['@context'],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      '@context': context,
      'actor': actor.toString(),
      'to': [to.toString()],
    };
  }

  WireActivityBase copyWith({
    Uri? id,
    Uri? actor,
    Object? context,
    Uri? to,
  }) {
    return WireActivityBase(
      id: id ?? this.id,
      actor: actor ?? this.actor,
      context: context ?? this.context,
      to: to ?? this.to,
    );
  }
}

class WireTake implements WireActivity {
  @override
  final WireActivityBase base;

  @override
  String get type => 'Take';

  WireTake({required this.base});

  @override
  Map<String, dynamic> toJson() {
    final json = base.toJson();
    json['type'] = type;
    return json;
  }

  WireTake copyWith({WireActivityBase? base}) {
    return WireTake(base: base ?? this.base);
  }
}

class WireCreate implements WireActivity {
  @override
  final WireActivityBase base;
  final EncryptedMessage object;

  WireCreate({required this.base, required this.object});

  @override
  String get type => 'Create';

  factory WireCreate.fromJson(Map<String, dynamic> json) {
    return WireCreate(
      base: WireActivityBase.fromJson(json),
      object: EncryptedMessage.fromJson(
          json['object'] as Map<String, dynamic>),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = base.toJson();
    json['type'] = type;
    json['object'] = object.toJson();
    return json;
  }

  WireCreate copyWith({WireActivityBase? base, EncryptedMessage? object}) {
    return WireCreate(
        base: base ?? this.base, object: object ?? this.object);
  }
}

class WireReject implements WireActivity {
  @override
  final WireActivityBase base;

  /// Either a [Uri] (when the server sends an ID reference) or a
  /// [Map<String, dynamic>] (when the server sends an inline object).
  final Object object;

  WireReject({required this.base, required this.object});

  @override
  String get type => 'Reject';

  factory WireReject.fromJson(Map<String, dynamic> json) {
    final objectJson = json['object'];
    final Object object;
    if (objectJson is String) {
      object = Uri.parse(objectJson);
    } else {
      object = objectJson as Map<String, dynamic>;
    }
    return WireReject(base: WireActivityBase.fromJson(json), object: object);
  }

  /// [WireReject] is a receive-only type; serialization is not supported.
  @override
  Map<String, dynamic> toJson() {
    throw UnsupportedError(
      'WireReject is receive-only and cannot be serialized to JSON.',
    );
  }

  WireReject copyWith({WireActivityBase? base, Object? object}) {
    return WireReject(
        base: base ?? this.base, object: object ?? this.object);
  }
}

class WireDelivered implements WireActivity {
  @override
  final WireActivityBase base;
  final String object; // The ID of the Create activity being acknowledged

  WireDelivered({required this.base, required this.object});

  @override
  String get type => 'Delivered';

  factory WireDelivered.fromJson(Map<String, dynamic> json) {
    return WireDelivered(
      base: WireActivityBase.fromJson(json),
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

  WireDelivered copyWith({WireActivityBase? base, String? object}) {
    return WireDelivered(
        base: base ?? this.base, object: object ?? this.object);
  }
}
