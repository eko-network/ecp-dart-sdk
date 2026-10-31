import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart' as cg;
import 'package:ecp/core/utils/bytes.dart';
import 'package:ecp/ecp.dart';

/// One signed event in a user's device hash chain.
///
/// The chain is the only source of truth for which devices belong to a user.
/// Every entry is signed by a device that is valid at that point in the chain,
/// except the first which is self-signed (trusted on first use). The server
/// stores and serves the chain but holds no signing key, so it cannot add a
/// device on its own: the most it can do is replace the whole chain, which
/// clients notice because it no longer extends the head they pinned.
class DeviceChainEntry {
  static const addType = 'AddDevice';
  static const revokeType = 'RevokeDevice';

  final String type;
  final Uri actor;
  final String did;

  /// The device's signing key, set on [addType] entries only.
  final Uint8List? identityKey;

  /// Hash of the previous entry, null on the first entry.
  final Uint8List? prev;

  /// Device id of the device that signed this entry.
  final String signer;
  final Uint8List signature;

  /// Unsigned field the server annotates [addType] entries with.
  final Uri? keyCollection;

  const DeviceChainEntry({
    required this.type,
    required this.actor,
    required this.did,
    required this.identityKey,
    required this.prev,
    required this.signer,
    required this.signature,
    this.keyCollection,
  });

  /// Self-signed first entry for this device, used when the server trusts it
  /// on first use and starts a new chain.
  static Future<DeviceChainEntry> genesis({
    required Uri actor,
    required String did,
    required MlsCredentialRecord credential,
  }) {
    return _sign(
      type: addType,
      actor: actor,
      did: did,
      identityKey: credential.signerPublicKey,
      prev: null,
      signer: did,
      credential: credential,
    );
  }

  static Future<DeviceChainEntry> _sign({
    required String type,
    required Uri actor,
    required String did,
    required Uint8List? identityKey,
    required Uint8List? prev,
    required String signer,
    required MlsCredentialRecord credential,
  }) async {
    final fields = _signedFields(
      type: type,
      actor: actor,
      did: did,
      identityKey: identityKey,
      prev: prev,
      signer: signer,
    );
    final signature = await _ed25519.sign(
      _canonical(fields),
      keyPair: await _keyPair(credential),
    );
    return DeviceChainEntry(
      type: type,
      actor: actor,
      did: did,
      identityKey: identityKey,
      prev: prev,
      signer: signer,
      signature: Uint8List.fromList(signature.bytes),
    );
  }

  static Map<String, String?> _signedFields({
    required String type,
    required Uri actor,
    required String did,
    required Uint8List? identityKey,
    required Uint8List? prev,
    required String signer,
  }) => {
    'type': type,
    'actor': actor.toString(),
    'did': did,
    if (identityKey != null) 'identityKey': base64Encode(identityKey),
    'prev': prev == null ? null : base64Encode(prev),
    'signer': signer,
  };

  Map<String, String?> get _fields => _signedFields(
    type: type,
    actor: actor,
    did: did,
    identityKey: identityKey,
    prev: prev,
    signer: signer,
  );

  /// SHA-256 over the signed fields and the signature, what the next entry's
  /// [prev] refers to.
  Uint8List get hash => Uint8List.fromList(
    sha256
        .convert(_canonical({..._fields, 'signature': base64Encode(signature)}))
        .bytes,
  );

  Future<bool> _verify(Uint8List publicKey) {
    return _ed25519.verify(
      _canonical(_fields),
      signature: cg.Signature(
        signature,
        publicKey: cg.SimplePublicKey(publicKey, type: cg.KeyPairType.ed25519),
      ),
    );
  }

  /// The JSON stored and served by the server. Unknown fields the server adds
  /// (e.g. [keyCollection]) are not signed.
  Map<String, dynamic> toJson() => {
    ..._fields,
    'signature': base64Encode(signature),
  };

  factory DeviceChainEntry.fromJson(Map<String, dynamic> json) {
    String str(String key) {
      final value = json[key];
      if (value is! String) {
        throw EcpDeviceChainException('Chain entry is missing $key');
      }
      return value;
    }

    Uint8List? bytes(String key) {
      final value = json[key];
      return value == null ? null : base64Decode(value as String);
    }

    final keyCollection = json['keyCollection'];
    return DeviceChainEntry(
      type: str('type'),
      actor: Uri.parse(str('actor')),
      did: str('did'),
      identityKey: bytes('identityKey'),
      prev: bytes('prev'),
      signer: str('signer'),
      signature: base64Decode(str('signature')),
      keyCollection: keyCollection is String ? Uri.parse(keyCollection) : null,
    );
  }
}

/// A chain that passed [DeviceChain.verify]: the devices valid at its end.
class DeviceChain {
  final Person person;
  final List<DeviceChainEntry> entries;
  final List<Device> devices;

  DeviceChain._(this.person, this.entries, this.devices);

  Uint8List get head => entries.last.hash;

  /// Whether the chain contains an entry hashing to [head], i.e. it is the
  /// chain pinned at [head] or an extension of it.
  bool includes(Uint8List head) => entries.any((e) => bytesEqual(e.hash, head));

  Device? deviceFor(String did) =>
      devices.where((d) => d.did == did).firstOrNull;

  /// Replays [entries] from the start, checking the links, the signatures
  /// and that every signer is a valid device of [person] when it signs.
  static Future<DeviceChain> verify(
    Person person,
    List<DeviceChainEntry> entries,
  ) async {
    if (entries.isEmpty) {
      throw EcpDeviceChainException('${person.id} has no devices');
    }

    // did -> (identity key, key collection) of the currently valid devices
    final valid = <String, (Uint8List, Uri?)>{};
    Uint8List? prev;
    for (final (i, entry) in entries.indexed) {
      Never fail(String reason) => throw EcpDeviceChainException(
        'Device chain of ${person.id} is invalid at entry $i: $reason',
      );

      if (entry.actor != person.id) fail('signed for ${entry.actor}');
      if (i == 0) {
        if (entry.prev != null) fail('first entry links to a previous one');
        if (entry.type != DeviceChainEntry.addType ||
            entry.signer != entry.did) {
          fail('first entry is not a self-signed AddDevice');
        }
      } else if (entry.prev == null || !bytesEqual(entry.prev!, prev!)) {
        fail('does not link to the previous entry');
      }

      final signerKey = i == 0 ? entry.identityKey : valid[entry.signer]?.$1;
      if (signerKey == null) fail('signer ${entry.signer} is not a device');
      if (!await entry._verify(signerKey)) fail('bad signature');

      switch (entry.type) {
        case DeviceChainEntry.addType:
          final key = entry.identityKey;
          if (key == null) fail('AddDevice without an identity key');
          valid[entry.did] = (key, entry.keyCollection);
        case DeviceChainEntry.revokeType:
          if (valid.remove(entry.did) == null) {
            fail('revokes ${entry.did}, which is not a device');
          }
        default:
          fail('unknown type ${entry.type}');
      }
      prev = entry.hash;
    }

    final devices = [
      for (final MapEntry(key: did, value: (key, keyCollection))
          in valid.entries)
        Device(
          context: null,
          id: person.devicesEndpoint.replace(
            pathSegments: [...person.devicesEndpoint.pathSegments, did],
          ),
          did: did,
          keyCollection:
              keyCollection ??
              person.devicesEndpoint.replace(
                pathSegments: [
                  ...person.devicesEndpoint.pathSegments,
                  did,
                  'keys',
                ],
              ),
          publicKey: key,
        ),
    ];
    return DeviceChain._(person, entries, devices);
  }

  /// An entry adding (or re-keying) [did] with [identityKey], signed by this
  /// device, which has to be valid in the chain.
  Future<DeviceChainEntry> approve({
    required String did,
    required Uint8List identityKey,
    required String signerDid,
    required MlsCredentialRecord credential,
  }) {
    _checkSigner(signerDid, credential);
    return DeviceChainEntry._sign(
      type: DeviceChainEntry.addType,
      actor: person.id,
      did: did,
      identityKey: identityKey,
      prev: head,
      signer: signerDid,
      credential: credential,
    );
  }

  /// An entry revoking [did], signed by this device, which has to be valid in
  /// the chain. A device may revoke itself.
  Future<DeviceChainEntry> revoke({
    required String did,
    required String signerDid,
    required MlsCredentialRecord credential,
  }) {
    _checkSigner(signerDid, credential);
    if (deviceFor(did) == null) {
      throw EcpDeviceChainException('$did is not a device of ${person.id}');
    }
    return DeviceChainEntry._sign(
      type: DeviceChainEntry.revokeType,
      actor: person.id,
      did: did,
      identityKey: null,
      prev: head,
      signer: signerDid,
      credential: credential,
    );
  }

  void _checkSigner(String signerDid, MlsCredentialRecord credential) {
    final signer = deviceFor(signerDid);
    if (signer == null ||
        !bytesEqual(signer.publicKey, credential.signerPublicKey)) {
      throw EcpDeviceChainException(
        'This device is not a valid device of ${person.id}',
      );
    }
  }
}

final _ed25519 = cg.Ed25519();

/// The MLS signer doubles as the device's chain signing key. Its serialized
/// form is openmls' JSON `{private, public, scheme}` with the Ed25519 seed as
/// the private key.
Future<cg.SimpleKeyPair> _keyPair(MlsCredentialRecord credential) {
  final json = jsonDecode(utf8.decode(credential.signerBytes)) as Map;
  final seed = (json['private'] as List).cast<int>();
  return _ed25519.newKeyPairFromSeed(seed);
}

/// RFC 8785 (JCS) canonical form for the flat string/null objects the chain
/// uses: keys sorted, no whitespace. jsonEncode's string escaping matches JCS
/// for these values.
Uint8List _canonical(Map<String, String?> fields) {
  final keys = fields.keys.toList()..sort();
  final body = keys
      .map((k) => '${jsonEncode(k)}:${jsonEncode(fields[k])}')
      .join(',');
  return utf8.encode('{$body}');
}

/// Reads the leaf signature key and credential identity out of a serialized
/// MLS KeyPackage (RFC 9420 §10), so a key package handed out by the server
/// can be matched against the device chain before it is added to a group.
({Uint8List signatureKey, Uint8List identity}) parseKeyPackage(
  Uint8List bytes,
) {
  var offset = 0;
  void skip(int n) {
    if (offset + n > bytes.length) {
      throw const EcpException('Truncated key package');
    }
    offset += n;
  }

  Uint8List vector() {
    // RFC 9420 §2.1.2 variable-length integer prefix
    if (offset >= bytes.length) {
      throw const EcpException('Truncated key package');
    }
    final first = bytes[offset];
    final prefix = first >> 6;
    if (prefix == 3) throw const EcpException('Invalid vector length');
    final size = 1 << prefix;
    if (offset + size > bytes.length) {
      throw const EcpException('Truncated key package');
    }
    var length = first & 0x3f;
    for (var i = 1; i < size; i++) {
      length = (length << 8) | bytes[offset + i];
    }
    skip(size);
    final start = offset;
    skip(length);
    return Uint8List.sublistView(bytes, start, offset);
  }

  int uint16() {
    final start = offset;
    skip(2);
    return (bytes[start] << 8) | bytes[start + 1];
  }

  uint16(); // protocol version
  uint16(); // cipher suite
  vector(); // init key
  vector(); // leaf node encryption key
  final signatureKey = vector();
  const basicCredential = 1;
  if (uint16() != basicCredential) {
    throw const EcpException('Key package does not use a basic credential');
  }
  final identity = vector();
  return (signatureKey: signatureKey, identity: identity);
}
