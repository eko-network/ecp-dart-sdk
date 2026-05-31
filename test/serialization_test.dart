import 'dart:typed_data';
import 'package:ecp/core/utils/converters.dart';
import 'package:ecp/ecp.dart';
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
      final bundle = KeyPackage(key: bytes, did: "1");
      final json = bundle.toJson();
      final fromJson = KeyPackage.fromJson(json);

      expect(listsEqual(fromJson.key, bundle.key), isTrue);
    });

    test('KeyPackageBundle fromTakeResponse accepts key field', () {
      final bytes = Uint8List.fromList([9, 8, 7]);
      final encoded = const Uint8ListConverter().toJson(bytes);
      final bundle = KeyPackage.fromTakeResponse({
        'result': {'type': 'KeyPackage', 'key': encoded},
      });
      expect(listsEqual(bundle.key, bytes), isTrue);
    });
  });
}
