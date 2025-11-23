import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart'
    as libsignal;

part 'token_storage.freezed.dart';

abstract class IdentityKeyStore extends libsignal.IdentityKeyStore {
  @override
  Future<libsignal.IdentityKeyPair> getIdentityKeyPair() async {
    final kp = await getIdentityKeyPairOrNull();
    if (kp == null) throw StateError("IdentityKeyPair cannot be null");
    return kp;
  }

  Future<libsignal.IdentityKeyPair?> getIdentityKeyPairOrNull();

  Future<void> storeIdentityKeyPair(
    libsignal.IdentityKeyPair identityKeyPair,
    int localRegistrationId,
  );
}

abstract class AuthTokenStore {
  Future<void> saveAuthTokens(AuthTokens tokens);
  Future<AuthTokens?> getAuthTokens();
}

abstract class TokenStorage {
  final IdentityKeyStore identityKeyStore;
  final libsignal.PreKeyStore preKeyStore;
  final libsignal.SessionStore sessionStore;
  final libsignal.SignedPreKeyStore signedPreKeyStore;
  final AuthTokenStore authTokenStore;
  TokenStorage({
    required this.identityKeyStore,
    required this.preKeyStore,
    required this.sessionStore,
    required this.signedPreKeyStore,
    required this.authTokenStore,
  });

  Future<void> clear();
}

@freezed
abstract class AuthTokens with _$AuthTokens {
  const AuthTokens._();
  const factory AuthTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    required Uri serverUrl,
  }) = _AuthTokens;
  factory AuthTokens.fromJson(Map<String, Object?> json, Uri serverUrl) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      serverUrl: serverUrl,
    );
  }

  bool get isExpired {
    return DateTime.now().isAfter(expiresAt.subtract(Duration(seconds: 30)));
  }
}
