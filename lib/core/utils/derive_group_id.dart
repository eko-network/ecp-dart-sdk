import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

Uint8List deriveGroupId({required Uri a, required Uri b}) {
  final ids = [a.toString(), b.toString()]..sort();
  final data = utf8.encode('ecp-mls:${ids.join('|')}');
  final digest = sha256.convert(data);
  return Uint8List.fromList(digest.bytes);
}
