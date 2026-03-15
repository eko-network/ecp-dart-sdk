import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:ecp/src/parts/canonical_json.dart';

abstract class DeviceEvent {
  final String type;
  final Uri id;
  final String? prev;
  final Uri did;
  final Map<String, String> signatures;

  DeviceEvent({
    required this.type,
    required this.id,
    required this.prev,
    required this.did,
    required this.signatures,
  });

  Map<String, dynamic> toJson();

  String toCanonicalJsonString() {
    return toCanonicalJson(toJson());
  }
}

/// AddDevice object for adding a device to the hash chain
class AddDevice extends DeviceEvent {
  final Uri keyPackage;
  final String publicKey;

  AddDevice({
    required Uri id,
    required String? prev,
    required Uri did,
    required this.keyPackage,
    required this.publicKey,
    required Map<String, String> signatures,
  }) : super(
         type: 'AddDevice',
         id: id,
         prev: prev,
         did: did,
         signatures: signatures,
       );

  factory AddDevice.fromJson(Map<String, dynamic> json) {
    return AddDevice(
      id: Uri.parse(json['id'] as String),
      prev: json['prev'] as String?,
      did: Uri.parse(json['did'] as String),
      keyPackage: Uri.parse(json['eko:keyPackage'] as String),
      publicKey: json['publicKey'] as String,
      signatures: Map<String, String>.from(json['signatures'] ?? {}),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '@context': [
        'https://www.w3.org/ns/activitystreams',
        'https://eko.network/ns',
      ],
      'type': type,
      'id': id.toString(),
      'prev': prev,
      'did': did.toString(),
      'eko:keyPackage': keyPackage.toString(),
      'publicKey': publicKey,
      'signatures': signatures,
    };
  }
}

/// RevokeDevice object for removing a device from the hash chain
class RevokeDevice extends DeviceEvent {
  RevokeDevice({
    required Uri id,
    required Uri did,
    required String? prev,
    required Map<String, String> signatures,
  }) : super(
         type: 'RevokeDevice',
         id: id,
         prev: prev,
         did: did,
         signatures: signatures,
       );

  factory RevokeDevice.fromJson(Map<String, dynamic> json) {
    return RevokeDevice(
      id: Uri.parse(json['id'] as String),
      did: Uri.parse(json['did'] as String),
      prev: json['prev'] as String?,
      signatures: Map<String, String>.from(json['signatures'] ?? {}),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '@context': [
        'https://www.w3.org/ns/activitystreams',
        'https://eko.network/ns',
      ],
      'type': type,
      'id': id.toString(),
      'did': did.toString(),
      'prev': prev,
      'signatures': signatures,
    };
  }
}

String computeHash(String canonicalJson) {
  final bytes = utf8.encode(canonicalJson);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

class DeviceList {
  final List<DeviceEvent> events;

  DeviceList({List<DeviceEvent>? events}) : events = events ?? [];

  bool validate() {
    if (events.isEmpty) {
      return true;
    }

    if (events.first.prev != null) {
      return false;
    }

    for (var i = 1; i < events.length; i++) {
      final prevEvent = events[i - 1];
      final currentEvent = events[i];
      final prevHash = computeHash(prevEvent.toCanonicalJsonString());
      if (currentEvent.prev != prevHash) {
        return false;
      }
    }

    return true;
  }

  String? getLastHash() {
    if (events.isEmpty) {
      return null;
    }
    return computeHash(events.last.toCanonicalJsonString());
  }

  AddDevice addDevice({
    required Uri id,
    required Uri did,
    required Uri keyPackage,
    required String publicKey,
    Map<String, String>? signatures,
  }) {
    final prev = getLastHash();

    final addDevice = AddDevice(
      id: id,
      prev: prev,
      did: did,
      keyPackage: keyPackage,
      publicKey: publicKey,
      signatures: signatures ?? {},
    );

    events.add(addDevice);
    return addDevice;
  }

  RevokeDevice revokeDevice({
    required Uri id,
    required Uri did,
    Map<String, String>? signatures,
  }) {
    final prev = getLastHash();

    final revokeDevice = RevokeDevice(
      id: id,
      did: did,
      prev: prev,
      signatures: signatures ?? {},
    );

    events.add(revokeDevice);
    return revokeDevice;
  }

  List<AddDevice> getActiveDevices() {
    final activeDevicesByDid = <Uri, AddDevice>{};

    for (final event in events) {
      if (event is AddDevice) {
        activeDevicesByDid[event.did] = event;
      } else if (event is RevokeDevice) {
        activeDevicesByDid.remove(event.did);
      }
    }

    return activeDevicesByDid.values.toList();
  }

  factory DeviceList.fromJson(List<dynamic> jsonList) {
    final events = <DeviceEvent>[];

    for (final json in jsonList) {
      final type = json['type'] as String;
      if (type == 'AddDevice') {
        events.add(AddDevice.fromJson(json));
      } else if (type == 'RevokeDevice') {
        events.add(RevokeDevice.fromJson(json));
      }
    }

    return DeviceList(events: events);
  }

  List<Map<String, dynamic>> toJson() {
    return events.map((e) => e.toJson()).toList();
  }
}
