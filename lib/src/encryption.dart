import 'token_storage.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class Encryption {
  final TokenStorage keyStores;
  Encryption({required this.keyStores});
}
