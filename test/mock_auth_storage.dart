import 'package:ecp/src/auth_storage.dart';
import 'package:ecp/src/types/auth_info.dart';

class InMemoryAuthStorage implements AuthStorage {
  AuthInfo? _info;

  @override
  Future<AuthInfo?> getAuthInfo() async {
    return _info;
  }

  @override
  Future<void> saveAuthInfo(AuthInfo tokens) async {
    _info = tokens;
  }

  @override
  Future<void> clear() async {
    _info = null;
  }
}
