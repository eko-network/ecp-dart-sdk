import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth.dart';

class AuthenticatedHttpClient {
  final AuthManager authManager;
  final http.Client _inner;

  AuthenticatedHttpClient({required this.authManager, http.Client? innerClient})
    : _inner = innerClient ?? http.Client();

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    return _requestWithAuth(
      (authHeaders) =>
          _inner.get(url, headers: {...?headers, ...authHeaders}),
    );
  }

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _requestWithAuth(
      (authHeaders) => _inner.post(url,
          headers: {...?headers, ...authHeaders},
          body: body,
          encoding: encoding),
    );
  }

  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _requestWithAuth(
      (authHeaders) => _inner.put(url,
          headers: {...?headers, ...authHeaders},
          body: body,
          encoding: encoding),
    );
  }

  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _requestWithAuth(
      (authHeaders) => _inner.delete(url,
          headers: {...?headers, ...authHeaders},
          body: body,
          encoding: encoding),
    );
  }

  Future<http.Response> _requestWithAuth(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    try {
      // Get valid token (auto-refreshes if needed)
      final token = await authManager.getValidAccessToken();

      // Add auth header
      final authHeaders = {'Authorization': 'Bearer $token'};

      // Make request with updated headers
      final response = await request(authHeaders);

      // If 401, token might be stale despite our checks, try refresh once
      if (response.statusCode == 401) {
        await authManager.refreshTokens();
        final newToken = await authManager.getValidAccessToken();
        final retryHeaders = {'Authorization': 'Bearer $newToken'};
        return await request(retryHeaders);
      }

      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw HttpException('Request failed: $e');
    }
  }

  void close() {
    _inner.close();
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => 'HttpException: $message';
}
