import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart'
    as libsignal;
import 'package:uuid/uuid.dart';

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

abstract class UserStore {
  /// saves the user info and returns the local id. The local id is a non-zero integer. zero is reserved for current device
  Future<int> saveUser(UuidValue uid, UuidValue did);
  Future<Map<UuidValue, int>?> getUser(UuidValue uid);
}

abstract class TokenStorage {
  final IdentityKeyStore identityKeyStore;
  final libsignal.PreKeyStore preKeyStore;
  final libsignal.SessionStore sessionStore;
  final libsignal.SignedPreKeyStore signedPreKeyStore;
  final AuthTokenStore authTokenStore;
  final UserStore userStore;
  TokenStorage({
    required this.identityKeyStore,
    required this.preKeyStore,
    required this.sessionStore,
    required this.signedPreKeyStore,
    required this.authTokenStore,
    required this.userStore,
  });

  Future<void> clear();
}

@freezed
abstract class AuthTokens with _$AuthTokens {
  const AuthTokens._();
  const factory AuthTokens({
    required UuidValue uid,
    required UuidValue did,
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    required Uri serverUrl,
  }) = _AuthTokens;
  factory AuthTokens.fromJson(Map<String, Object?> json, Uri serverUrl) {
    return AuthTokens(
      uid: UuidValue.fromString(json['uid'] as String),
      did: UuidValue.fromString(json['did'] as String),
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
