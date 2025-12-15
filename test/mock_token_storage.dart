import 'package:ecp/ecp.dart';
import 'package:uuid/uuid_value.dart';
import 'package:collection/collection.dart';

class InMemoryAuthTokenStore implements AuthTokenStore {
  AuthTokens? _tokens;

  @override
  Future<AuthTokens?> getAuthTokens() async {
    return _tokens;
  }

  @override
  Future<void> saveAuthTokens(AuthTokens tokens) async {
    _tokens = tokens;
  }

  void clear() {
    _tokens = null;
  }
}

class InMemoryUserStore extends UserStore {
  final Map<UuidValue, Map<UuidValue, int>> _sto = {};
  int _serial = 1;

  @override
  Future<Map<UuidValue, int>?> getUser(UuidValue uid) async {
    return _sto[uid] == null ? null : Map.unmodifiable(_sto[uid]!);
  }

  @override
  Future<int> saveUser(UuidValue uid, UuidValue did) async {
    return _sto
        .putIfAbsent(uid, () => <UuidValue, int>{})
        .putIfAbsent(did, () => _serial++);
  }
}

class ModifiedInMemoryIdentityKeyStore extends IdentityKeyStore {
  final trustedKeys = Map<SignalProtocolAddress, IdentityKey>();

  IdentityKeyPair? identityKeyPair = null;
  int? localRegistrationId = null;

  @override
  Future<IdentityKey?> getIdentity(SignalProtocolAddress address) async =>
      trustedKeys[address]!;

  @override
  Future<IdentityKeyPair> getIdentityKeyPair() async => identityKeyPair!;

  @override
  Future<int> getLocalRegistrationId() async => localRegistrationId!;

  @override
  Future<bool> isTrustedIdentity(
    SignalProtocolAddress address,
    IdentityKey? identityKey,
    Direction? direction,
  ) async {
    final trusted = trustedKeys[address];
    if (identityKey == null) {
      return false;
    }
    return trusted == null ||
        ListEquality().equals(trusted.serialize(), identityKey.serialize());
  }

  @override
  Future<bool> saveIdentity(
    SignalProtocolAddress address,
    IdentityKey? identityKey,
  ) async {
    final existing = trustedKeys[address];
    if (identityKey == null) {
      return false;
    }
    if (identityKey != existing) {
      trustedKeys[address] = identityKey;
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<IdentityKeyPair?> getIdentityKeyPairOrNull() async {
    return identityKeyPair;
  }

  @override
  Future<void> storeIdentityKeyPair(
    IdentityKeyPair identityKeyPair,
    int localRegistrationId,
  ) async {
    this.identityKeyPair = identityKeyPair;
    this.localRegistrationId = localRegistrationId;
  }
}

class MockTokenStorage extends TokenStorage {
  MockTokenStorage()
    : super(
        preKeyStore: InMemoryPreKeyStore(),
        authTokenStore: InMemoryAuthTokenStore(),
        sessionStore: InMemorySessionStore(),
        signedPreKeyStore: InMemorySignedPreKeyStore(),
        identityKeyStore: ModifiedInMemoryIdentityKeyStore(),
        userStore: InMemoryUserStore(),
      );

  @override
  Future<void> clear() async {
    (authTokenStore as InMemoryAuthTokenStore).clear();
  }
}
