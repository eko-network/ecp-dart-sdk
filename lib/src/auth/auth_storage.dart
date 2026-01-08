import 'package:ecp/src/types/auth_info.dart';

abstract class AuthStorage {
  Future<void> saveAuthInfo(AuthInfo tokens);
  Future<void> handleRefresh(RefreshResponse refresh);
  Future<AuthInfo?> getAuthInfo();
  Future<void> clear();
}
