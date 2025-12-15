import 'dart:convert';
import 'dart:typed_data';
import 'package:ecp/ecp.dart';
import 'package:uuid/uuid.dart';

class Address {
  final UuidValue uid;
  final Uri domain;

  Address({required this.uid, required this.domain});

  factory Address.parse(String value) {
    final parts = value.split('@');
    if (parts.length != 2) {
      throw FormatException('Expected uuid@domain');
    }

    return Address(
      uid: UuidValue.fromString(parts[0]),
      domain: Uri.parse(parts[1]),
    );
  }

  String serialize() => '${uid.toString()}@${domain.toString()}';
}

class Base {
  final Address actor;
  final Address to;

  Base({required this.actor, required this.to});

  factory Base.fromJson(Map<String, dynamic> json) {
    return Base(
      actor: Address.parse(json['actor'] as String),
      to: Address.parse(json['to'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'actor': actor.serialize(),
    'to': to.serialize(),
  };
}

class KeyBundle {
  final UuidValue did; // UUID
  final Uint8List identityKey;
  final int registrationId;

  final int preKeyId;
  final Uint8List preKey;

  final int signedPreKeyId;
  final Uint8List signedPreKey;
  final Uint8List signedPreKeySignature;

  KeyBundle({
    required this.did,
    required this.identityKey,
    required this.registrationId,
    required this.preKeyId,
    required this.preKey,
    required this.signedPreKeyId,
    required this.signedPreKey,
    required this.signedPreKeySignature,
  });

  factory KeyBundle.fromJson(Map<String, dynamic> json) {
    return KeyBundle(
      did: UuidValue.fromString(json['did']),
      identityKey: base64Decode(json['identity_key']),
      registrationId: json['registration_id'],
      preKeyId: json['pre_key_id'],
      preKey: base64Decode(json['pre_key']),
      signedPreKeyId: json['signed_pre_key_id'],
      signedPreKey: base64Decode(json['signed_pre_key']),
      signedPreKeySignature: base64Decode(json['signed_pre_key_signature']),
    );
  }

  Map<String, dynamic> toJson() => {
    'did': did.toString(),
    'identity_key': base64Encode(identityKey),
    'registration_id': registrationId,
    'pre_key_id': preKeyId,
    'pre_key': base64Encode(preKey),
    'signed_pre_key_id': signedPreKeyId,
    'signed_pre_key': base64Encode(signedPreKey),
    'signed_pre_key_signature': base64Encode(signedPreKeySignature),
  };

  PreKeyBundle toPreKeyBundle(int ldid) {
    return PreKeyBundle(
      registrationId,
      ldid,
      preKeyId,
      Curve.decodePoint(preKey, 0),
      signedPreKeyId,
      Curve.decodePoint(signedPreKey, 0),
      signedPreKeySignature,
      IdentityKey.fromBytes(identityKey, 0),
    );
  }
}

abstract class Activity {
  Base get base;

  String get type;

  Map<String, dynamic> toJson();

  factory Activity.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'KeyRequest':
        return KeyRequest.fromJson(json);
      case 'KeyResponse':
        return KeyResponse.fromJson(json);
      case 'Note':
        return Note.fromJson(json);
      default:
        throw UnsupportedError('Unknown activity type: ${json['type']}');
    }
  }
}

class KeyRequest implements Activity {
  @override
  final Base base;

  KeyRequest({required this.base});

  factory KeyRequest.fromJson(Map<String, dynamic> json) {
    return KeyRequest(base: Base.fromJson(json));
  }

  @override
  String get type => 'KeyRequest';

  @override
  Map<String, dynamic> toJson() => {'type': type, ...base.toJson()};
}

class KeyResponse implements Activity {
  @override
  final Base base;
  final List<KeyBundle> bundles;

  KeyResponse({required this.base, required this.bundles});

  factory KeyResponse.fromJson(Map<String, dynamic> json) {
    return KeyResponse(
      base: Base.fromJson(json),
      bundles: (json['bundles'] as List)
          .map((e) => KeyBundle.fromJson(e))
          .toList(),
    );
  }

  @override
  String get type => 'KeyResponse';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    ...base.toJson(),
    'bundles': bundles.map((b) => b.toJson()).toList(),
  };
}

class Message {
  final UuidValue did;
  final CiphertextMessage content;
  Message({required this.did, required this.content});
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      did: UuidValue.fromString(json["did"]),
      content: CiphertextSerializer.deserialize(base64Decode(json['content'])),
    );
  }

  Map<String, dynamic> toJson() => {
    'did': did.toString(),
    'content': base64Encode(CiphertextSerializer.serialize(content)),
  };
}

class Note implements Activity {
  @override
  final Base base;
  final List<Message> messages;

  Note({required this.base, required this.messages});

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      base: Base.fromJson(json),
      messages: (json['messages'] as List)
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  String get type => 'Note';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    ...base.toJson(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };
}

class CiphertextSerializer {
  static Uint8List serialize(CiphertextMessage message) {
    final type = message.getType();
    final data = message.serialize();
    final result = Uint8List(1 + data.length);
    result[0] = type;
    result.setRange(1, result.length, data);

    return result;
  }

  static CiphertextMessage deserialize(Uint8List serialized) {
    if (serialized.isEmpty) {
      throw ArgumentError('Cannot deserialize empty data');
    }

    final type = serialized[0];
    final data = serialized.sublist(1);

    switch (type) {
      case CiphertextMessage.prekeyType:
        return PreKeySignalMessage(data);

      case CiphertextMessage.whisperType:
        return SignalMessage.fromSerialized(data);

      case CiphertextMessage.senderKeyType:
        return SenderKeyMessage.fromSerialized(data);

      case CiphertextMessage.senderKeyDistributionType:
        return SenderKeyDistributionMessageWrapper.fromSerialized(data);

      default:
        throw ArgumentError('Unknown message type: $type');
    }
  }
}
