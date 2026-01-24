import 'package:ecp/src/types/person.dart';

class AuthInfo {
  final Uri did;
  final String accessToken;
  final String refreshToken;
  final Person actor;
  final DateTime expiresAt;
  final Uri serverUrl;
  factory AuthInfo.fromJson(Map<String, Object?> json, Uri serverUrl) {
    return AuthInfo(
      serverUrl: serverUrl,
      did: Uri.parse(json['did'] as String),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      actor: Person.fromJson(json['actor'] as Map<String, dynamic>),
    );
  }

  AuthInfo({
    required this.did,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.serverUrl,
    required this.actor,
  });

  bool get isExpired {
    return DateTime.now().isAfter(expiresAt.subtract(Duration(seconds: 30)));
  }

  AuthInfo copyWith(RefreshResponse response) {
    return AuthInfo(
      did: did,
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      expiresAt: response.expiresAt,
      serverUrl: serverUrl,
      actor: actor,
    );
  }
}

class RefreshResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  factory RefreshResponse.fromJson(Map<String, Object?> json) {
    return RefreshResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  RefreshResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });
}
