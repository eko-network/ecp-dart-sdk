import 'dart:convert';
import 'dart:typed_data';

import 'package:ecp/src/core/types/encrypted_message.dart';
import 'package:ecp/src/core/types/key_package_bundle.dart';
import 'package:ecp/src/core/utils/b64.dart';
import 'package:test/test.dart';

bool listsEqual(List<int>? a, List<int>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

void main() {
  group('Serialization tests', () {
    test('KeyPackageBundle serialization', () {
      final bytes = Uint8List.fromList(List<int>.generate(10, (i) => i));
      final bundle = KeyPackageBundle(keyPackage: bytes);
      final json = bundle.toJson();
      final fromJson = KeyPackageBundle.fromJson(json);

      expect(listsEqual(fromJson.keyPackage, bundle.keyPackage), isTrue);
    });

    test('MLS message base64 serialization', () {
      final message = Uint8List.fromList(utf8.encode('test message'));
      final encoded = MlsMessageCodec.encode(message);
      final decoded = MlsMessageCodec.decode(encoded);

      expect(listsEqual(decoded, message), isTrue);
    });

    test('EncryptedMessage optimized serialization', () {
      final ciphertext = Uint8List.fromList([1, 2, 3]);
      final welcome = Uint8List.fromList([4, 5, 6]);
      final commit = Uint8List.fromList([7, 8, 9]);
      
      final msg = EncryptedMessage(
        context: "ctx",
        typeField: "EncryptedMessage",
        id: null,
        ciphertext: ciphertext,
        recipients: [
          EncryptedRecipient(
            to: Uri.parse("did:1"),
            from: Uri.parse("did:2"),
            welcome: welcome,
          ),
          EncryptedRecipient(
            to: Uri.parse("did:3"),
            from: Uri.parse("did:2"),
            commit: commit,
          ),
        ],
        attributedTo: Uri.parse("actor:1"),
        to: [Uri.parse("actor:2")],
      );

      final json = msg.toJson();
      final decoded = EncryptedMessage.fromJson(json);

      expect(listsEqual(decoded.ciphertext, ciphertext), isTrue);
      expect(decoded.recipients.length, 2);
      expect(listsEqual(decoded.recipients[0].welcome, welcome), isTrue);
      expect(decoded.recipients[0].commit, isNull);
      expect(listsEqual(decoded.recipients[1].commit, commit), isTrue);
      expect(decoded.recipients[1].welcome, isNull);
    });
  });
}
