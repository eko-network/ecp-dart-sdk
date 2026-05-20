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
  });
}
