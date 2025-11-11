import 'dart:async';
import 'dart:convert';
import 'token_storage.dart';
import 'package:http/http.dart' as http;

class AuthManager {
  final TokenStorage storage;
  Uri baseUrl;
  final String deviceName;
  final http.Client httpClient;

  TokenPair? _currentTokens;
  Future<TokenPair>? _refreshFuture;
  final _authStateController = StreamController<bool>.broadcast();

  AuthManager({
    required this.deviceName,
    required this.storage,
    required this.baseUrl,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  Stream<bool> get stream => _authStateController.stream;

  Future<void> initialize() async {
    final accessToken = await storage.getAccessToken();
    final refreshToken = await storage.getRefreshToken();
    final expiresAt = await storage.getExpiresAt();

    if (accessToken != null && refreshToken != null) {
      _currentTokens = TokenPair(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
      );

      // Auto-refresh if expired
      if (_currentTokens!.isExpired) {
        try {
          await refreshTokens();
        } catch (e) {
          _authStateController.add(isAuthenticated);
          // If refresh fails on init, clear tokens
          await clearSession();
        }
      }
    }
    _authStateController.add(isAuthenticated);
  }

  Future<TokenPair> login(String email, String password) async {
    final response = await httpClient.post(
      baseUrl.replace(
        pathSegments: [...baseUrl.pathSegments, "auth", "v1", "login"],
      ),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'device_name': deviceName,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tokens = TokenPair.fromJson(data);
      await _saveTokens(tokens);
      _authStateController.add(isAuthenticated);
      return tokens;
    } else {
      throw AuthException('Login failed: ${response.body}');
    }
  }

  Future<TokenPair> refreshTokens() async {
    // Prevent concurrent refresh requests
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    final currentRefreshToken = _currentTokens?.refreshToken;
    if (currentRefreshToken == null) {
      throw AuthException('No refresh token available');
    }

    _refreshFuture = _performRefresh(currentRefreshToken);

    try {
      final tokens = await _refreshFuture!;
      return tokens;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<TokenPair> _performRefresh(String refreshToken) async {
    final response = await httpClient.post(
      baseUrl.replace(
        pathSegments: [...baseUrl.pathSegments, "auth", "v1", "refresh"],
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tokens = TokenPair.fromJson(data);
      await _saveTokens(tokens);
      return tokens;
    } else if (response.statusCode == 401) {
      await clearSession();
      throw AuthException('Session expired. Please log in again.');
    } else {
      throw AuthException('Token refresh failed: ${response.body}');
    }
  }

  Future<String> getValidAccessToken() async {
    if (_currentTokens == null) {
      throw AuthException('Not authenticated');
    }

    if (_currentTokens!.isExpired) {
      await refreshTokens();
    }

    return _currentTokens!.accessToken;
  }

  Future<void> _saveTokens(TokenPair tokens) async {
    _currentTokens = tokens;
    await storage.saveAuthTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresAt: tokens.expiresAt,
      serverUrl: baseUrl.toString(),
    );
  }

  Future<void> clearSession() async {
    _currentTokens = null;
    _refreshFuture = null;
    await storage.clearTokens();
    _authStateController.add(isAuthenticated);
  }

  bool get isAuthenticated => _currentTokens != null;

  TokenPair? get currentTokens => _currentTokens;
  set currentTokens(TokenPair? value) => _currentTokens = value;

  void dispose() {
    _authStateController.close();
    httpClient.close();
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
