import 'dart:convert';

import 'auth.dart';
import 'authenticated_client.dart';
import 'token_storage.dart';
import 'package:http/http.dart' as http;

ECPClient get ecp => ECPClient.instance;

class ECPClient {
  late final AuthManager authManager;
  late final AuthenticatedHttpClient authenticatedClient;
  Uri baseUrl;
  final String deviceName;

  ECPClient._({
    required this.authManager,
    required this.authenticatedClient,
    required this.baseUrl,
    required this.deviceName,
  });

  factory ECPClient({
    required TokenStorage storage,
    required Uri baseUrl,
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

  static ECPClient? _instance;
  static ECPClient get instance {
    assert(
      _instance != null,
      'ECP has not been initialized. Please call ECP.initialize() before using it.',
    );

    return _instance!;
  }

  static Future<ECPClient> initialize({
    required TokenStorage storage,
    required String deviceName,
    required Uri baseUrl,
    http.Client? httpClient,
  }) async {
    final serverUrl = await storage.getServerUrl();
    late final uri;
    if (serverUrl == null) {
      uri = baseUrl;
    } else {
      final tmpUri = Uri.tryParse(serverUrl);
      if (tmpUri != null && tmpUri.hasScheme) {
        uri = tmpUri;
      } else {
        uri = baseUrl;
      }
    }

    final client = ECPClient(
      storage: storage,
      baseUrl: uri,
      deviceName: deviceName,
      httpClient: httpClient,
    );

    await client.authManager.initialize();
    _instance = client;
    return client;
  }

  /// Login with credentials
  Future<void> login({required String email, required String password}) async {
    await authManager.login(email, password);
  }

  /// Logout and clear tokens
  Future<void> logout() async {
    final refreshToken = authManager.currentTokens?.refreshToken;
    if (refreshToken != null) {
      try {
        await authenticatedClient.post(
          baseUrl.replace(
            pathSegments: [...baseUrl.pathSegments, "auth", "v1", "logout"],
          ),

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

  /// Sets a new base URL for the ECP client.
  /// Throws a [StateError] if a user is currently authenticated.
  void setBaseUrl(Uri newUrl) {
    if (isAuthenticated) {
      throw StateError(
        'Cannot change base URL while a user is logged in. Please log out first.',
      );
    }
    baseUrl = newUrl;
    authManager.baseUrl = newUrl;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => authManager.isAuthenticated;

  /// Stream of authentication state changes
  Stream<bool> get authStream => authManager.stream;

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
