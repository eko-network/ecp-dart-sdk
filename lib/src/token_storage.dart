import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart'
    as libsignal;

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
  Future<void> saveUser(Uri id, int did);
  Future<List<int>?> getUser(Uri id);
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

class AuthTokens {
  final String uid;
  final int did;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final Uri serverUrl;
  factory AuthTokens.fromJson(Map<String, Object?> json, Uri serverUrl) {
    return AuthTokens(
      uid: json['uid'] as String,
      did: json['did'] as int,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      serverUrl: serverUrl,
    );
  }

  AuthTokens({
    required this.uid,
    required this.did,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.serverUrl,
  });

  bool get isExpired {
    return DateTime.now().isAfter(expiresAt.subtract(Duration(seconds: 30)));
  }
}
