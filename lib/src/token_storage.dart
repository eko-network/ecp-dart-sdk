import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

abstract class TokenStorage extends SignalProtocolStore {
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<DateTime?> getExpiresAt();
  Future<String?> getServerUrl();

  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
    required String serverUrl,
    DateTime? expiresAt,
  });

  Future<void> clearTokens();
}

class TokenPair {
  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;

  TokenPair({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt?.toIso8601String(),
  };

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    final expiresIn = json['expires_in'] as int?;
    return TokenPair(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: expiresIn != null
          ? DateTime.now().add(Duration(seconds: expiresIn))
          : null,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!.subtract(Duration(seconds: 30)));
  }

  TokenPair copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) {
    return TokenPair(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
