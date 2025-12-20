import 'package:ecp/src/types/auth_info.dart';

abstract class AuthStorage {
  Future<void> saveAuthInfo(AuthInfo tokens);
  Future<AuthInfo?> getAuthInfo();
  Future<void> clear();
}
