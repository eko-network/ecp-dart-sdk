import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth.dart';

Uri _joinUri(Uri uri, List<String> path) {
  return uri.replace(pathSegments: [...uri.pathSegments, ...path]);
}

class AuthenticatedHttpClient {
  final AuthManager auth;
  final http.Client _inner;

  AuthenticatedHttpClient({required this.auth, http.Client? innerClient})
    : _inner = innerClient ?? http.Client();

  Future<http.Response> get(
    List<String> endpoint, {
    Map<String, String>? headers,
  }) async {
    return _requestWithAuth(
      (authHeaders) => _inner.get(
        _joinUri(auth.url!, endpoint),
        headers: {...?headers, ...authHeaders},
      ),
    );
  }

  Future<http.Response> post(
    List<String> endpoint, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _requestWithAuth(
      (authHeaders) => _inner.post(
        _joinUri(auth.url!, endpoint),
        headers: {...?headers, ...authHeaders},
        body: body,
        encoding: encoding,
      ),
    );
  }

  Future<http.Response> put(
    List<String> endpoint, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _requestWithAuth(
      (authHeaders) => _inner.put(
        _joinUri(auth.url!, endpoint),
        headers: {...?headers, ...authHeaders},
        body: body,
        encoding: encoding,
      ),
    );
  }

  Future<http.Response> delete(
    List<String> endpoint, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _requestWithAuth(
      (authHeaders) => _inner.delete(
        _joinUri(auth.url!, endpoint),
        headers: {...?headers, ...authHeaders},
        body: body,
        encoding: encoding,
      ),
    );
  }

  Future<http.Response> _requestWithAuth(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    try {
      // Get valid token (auto-refreshes if needed)
      final token = await auth.getValidAccessToken();

      // Add auth header
      final authHeaders = {'Authorization': 'Bearer $token'};

      // Make request with updated headers
      final response = await request(authHeaders);

      // If 401, token might be stale despite our checks, try refresh once
      if (response.statusCode == 401) {
        await auth.refreshTokens();
        final newToken = await auth.getValidAccessToken();
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
