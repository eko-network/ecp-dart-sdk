import 'dart:convert';

import 'package:ecp/src/auth.dart';
import 'package:ecp/src/authenticated_client.dart';
import 'package:ecp/src/token_storage.dart';
import 'package:http/http.dart' as http;

class ECPClient {
  late final AuthManager authManager;
  late final AuthenticatedHttpClient authenticatedClient;
  final String baseUrl;
  final String deviceName;

  ECPClient._({
    required this.authManager,
    required this.authenticatedClient,
    required this.baseUrl,
    required this.deviceName,
  });

  factory ECPClient({
    required TokenStorage storage,
    required String baseUrl,
    required String deviceName,
    http.Client? httpClient,
  }) {
    final authManager = AuthManager(
      storage: storage,
      baseUrl: baseUrl,
      deviceName: deviceName,
      httpClient: httpClient,
    );

    return ECPClient._(
      authManager: authManager,
      authenticatedClient: AuthenticatedHttpClient(authManager: authManager),
      baseUrl: baseUrl,
      deviceName: deviceName,
    );
  }

  static Future<ECPClient?> restore({
    required TokenStorage storage,
    required String deviceName,
    http.Client? httpClient,
  }) async {
    final serverUrl = await storage.getServerUrl();
    if (serverUrl == null) return null;

    final client = ECPClient(
      storage: storage,
      baseUrl: serverUrl,
      deviceName: deviceName,
      httpClient: httpClient,
    );

    await client._initialize();
    return client.isAuthenticated ? client : null;
  }

  /// Initialize the client (load stored tokens)
  Future<void> _initialize() async {
    await authManager.initialize();
  }

  /// Login with credentials
  Future<void> login(String email, String password) async {
    await authManager.login(email, password);
  }

  /// Logout and clear tokens
  Future<void> logout() async {
    final refreshToken = authManager.currentTokens?.refreshToken;
    if (refreshToken != null) {
      try {
        await authenticatedClient.post(
          Uri.parse('$baseUrl/auth/v1/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        );
      } catch (e) {
        // Even if remote logout fails, we clear local session
        print('Logout failed on server: $e');
      }
    }
    await authManager.clearSession();
  }

  /// Check if user is authenticated
  bool get isAuthenticated => authManager.isAuthenticated;

  /// Stream of token refresh events
  Stream<TokenPair> get onTokenRefresh => authManager.onTokenRefresh;

  // Example API methods using the authenticated client
  // Future<Map<String, dynamic>> getUserProfile() async {
  //   final response = await httpClient.get(
  //     Uri.parse('$baseUrl/api/user/profile'),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body) as Map<String, dynamic>;
  //   } else {
  //     throw Exception('Failed to get user profile');
  //   }
  // }
  //
  // Future<List<dynamic>> getMessages(String roomId) async {
  //   final response = await httpClient.get(
  //     Uri.parse('$baseUrl/api/rooms/$roomId/messages'),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body) as List<dynamic>;
  //   } else {
  //     throw Exception('Failed to get messages');
  //   }
  // }

  void dispose() {
    authManager.dispose();
    authenticatedClient.close();
  }
}
