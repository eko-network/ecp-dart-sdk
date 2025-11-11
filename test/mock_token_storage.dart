import 'package:ecp/src/token_storage.dart';

class MockTokenStorage implements TokenStorage {
  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;
  String? _serverUrl;

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<DateTime?> getExpiresAt() async => _expiresAt;

  @override
  Future<String?> getServerUrl() async => _serverUrl;

  @override
  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
    required String serverUrl,
    DateTime? expiresAt,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _expiresAt = expiresAt;
    _serverUrl = serverUrl;
  }

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    _serverUrl = null;
  }
}
