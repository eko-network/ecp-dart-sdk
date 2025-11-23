import 'dart:convert';

import 'auth.dart';
import 'authenticated_client.dart';
import 'token_storage.dart';
import 'package:http/http.dart' as http;

ECPClient get ecp => ECPClient.instance;

class ECPClient {
  late final AuthManager authManager;
  late final AuthenticatedHttpClient authenticatedClient;
  final String deviceName;
  final String deviceId;

  ECPClient._({
    required this.authManager,
    required this.authenticatedClient,
    required this.deviceName,
    required this.deviceId,
  });

  Uri? _baseUrl = null;

  Uri get baseUrl {
    if (_baseUrl == null) {
      throw StateError("BaseUrl accessed before login");
    }
    return _baseUrl!;
  }

  factory ECPClient({
    required TokenStorage storage,
    required String deviceName,
    required String deviceId,
    http.Client? httpClient,
  }) {
    final authManager = AuthManager(
      deviceId: deviceId,
      storage: storage,
      deviceName: deviceName,
      httpClient: httpClient,
    );

    return ECPClient._(
      authManager: authManager,
      authenticatedClient: AuthenticatedHttpClient(authManager: authManager),
      deviceName: deviceName,
      deviceId: deviceId,
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
    required String deviceId,
    http.Client? httpClient,
  }) async {
    final client = ECPClient(
      storage: storage,
      deviceName: deviceName,
      httpClient: httpClient,
      deviceId: deviceId,
    );

    final tokens = await client.authManager.initialize();
    if (tokens != null) client._baseUrl = tokens.serverUrl;
    _instance = client;
    return client;
  }

  /// Login with credentials
  Future<void> login({
    required String email,
    required String password,
    required Uri url,
  }) async {
    _baseUrl = url;
    await authManager.login(email, password, url);
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
