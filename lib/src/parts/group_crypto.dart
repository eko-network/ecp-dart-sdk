import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:libsignal_protocol_dart/src/kdf/hkdfv3.dart';
import 'package:pointycastle/export.dart' as pc;

import 'canonical_json.dart';
import '../types/group.dart';

/// Generate a 32-byte cryptographically random group master key.
Uint8List generateGroupMasterKey() {
  final random = Random.secure();
  return Uint8List.fromList(List<int>.generate(32, (_) => random.nextInt(256)));
}

/// Derive group signing key from the group master key using HKDF.
Uint8List deriveGroupSigningKey(Uint8List groupMasterKey) {
  final hkdf = HKDFv3();
  return hkdf.deriveSecrets(
    groupMasterKey,
    Uint8List.fromList(utf8.encode('eko.group.signing')),
    32,
  );
}

/// Derive a symmetric encryption key for encrypting group state blobs.
///
/// Uses HKDF over the provided [keyMaterial] with a distinct info string.
/// The caller is responsible for providing a user-level secret that is
/// shared across all of the user's devices (e.g. synced via Signal sessions).
Uint8List deriveGroupStateEncryptionKey(Uint8List keyMaterial) {
  final hkdf = HKDFv3();
  return hkdf.deriveSecrets(
    keyMaterial,
    Uint8List.fromList(utf8.encode('eko.group.state.encryption')),
    32,
  );
}

/// Sign a group control message with HMAC-SHA256.

/// Computes HMAC-SHA256(key=signingKey, message=canonicalJson) and
/// Returns a [GroupSignature] with the base64-encoded MAC.
GroupSignature signGroupControl(
  Map<String, dynamic> controlJson,
  Uint8List signingKey,
) {
  final stripped = Map<String, dynamic>.from(controlJson)..remove('signature');
  final canonical = toCanonicalJson(stripped);
  final hmac = Hmac(sha256, signingKey);
  final digest = hmac.convert(utf8.encode(canonical));
  return GroupSignature(value: base64Encode(digest.bytes));
}

/// Verify the HMAC-SHA256 signature on a group control message.
///
/// Recomputes the MAC and compares it to the `signature.value` field.
/// Returns `false` if the signature is missing or doesn't match.
bool verifyGroupControl(
  Map<String, dynamic> controlJson,
  Uint8List signingKey,
) {
  final existingSignature = controlJson['signature'];
  if (existingSignature == null) return false;

  final expected = GroupSignature.fromJson(
    existingSignature as Map<String, dynamic>,
  );
  final computed = signGroupControl(controlJson, signingKey);
  return expected.value == computed.value;
}

const int _ivLength = 12; // 96-bit initialization vector for GCM

/// Encrypt a [GroupState] for server storage.
///
/// Uses AES-256-GCM with a random IV. The output format is:
/// `IV (12 bytes) || ciphertext || auth tag (16 bytes)`, base64-encoded.
String encryptGroupState(GroupState state, Uint8List encryptionKey) {
  final plaintext = utf8.encode(jsonEncode(state.toJson()));
  final encrypted = _aesGcmEncrypt(
    Uint8List.fromList(plaintext),
    encryptionKey,
  );
  return base64Encode(encrypted);
}

/// Decrypt an [EncryptedGroupState] blob from the server.
///
/// Expects the content to be base64-encoded `IV || ciphertext || tag`.
GroupState decryptGroupState(String ciphertext, Uint8List encryptionKey) {
  final encrypted = base64Decode(ciphertext);
  final plaintext = _aesGcmDecrypt(encrypted, encryptionKey);
  final json = jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
  return GroupState.fromJson(json);
}

/// AES-256-GCM encrypt. Returns `IV (12) || ciphertext || tag (16)`.
Uint8List _aesGcmEncrypt(Uint8List plaintext, Uint8List key) {
  final random = Random.secure();
  final iv = Uint8List.fromList(
    List<int>.generate(_ivLength, (_) => random.nextInt(256)),
  );

  final cipher = pc.GCMBlockCipher(pc.AESEngine())
    ..init(
      true, // for encryption
      pc.AEADParameters(
        pc.KeyParameter(key),
        128, // tag length in bits
        iv,
        Uint8List(0), // no additional authenticated data
      ),
    );

  final output = cipher.process(plaintext);

  // IV || ciphertext || tag
  return Uint8List.fromList([...iv, ...output]);
}

/// AES-256-GCM decrypt. Expects `IV (12) || ciphertext || tag (16)`.
Uint8List _aesGcmDecrypt(Uint8List data, Uint8List key) {
  final iv = data.sublist(0, _ivLength);
  final ciphertextAndTag = data.sublist(_ivLength);

  final cipher = pc.GCMBlockCipher(pc.AESEngine())
    ..init(
      false, // for decryption
      pc.AEADParameters(
        pc.KeyParameter(key),
        128, // tag length in bits
        iv,
        Uint8List(0), // no additional authenticated data
      ),
    );

  return cipher.process(ciphertextAndTag);
}
