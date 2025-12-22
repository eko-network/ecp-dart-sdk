import 'package:ecp/ecp.dart';
import 'package:collection/collection.dart';

class InMemoryUserStore extends UserStore {
  final Map<Uri, Set<int>> _sto = {};
  int _serial = 1;

  @override
  Future<List<int>?> getUser(Uri id) async {
    return _sto[id]?.toList();
  }

  @override
  Future<void> saveUser(Uri id, int did) async {
    _sto.putIfAbsent(id, () => <int>{}).add(_serial++);
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

class MockTokenStorage extends Storage {
  MockTokenStorage()
    : super(
        preKeyStore: InMemoryPreKeyStore(),
        sessionStore: InMemorySessionStore(),
        signedPreKeyStore: InMemorySignedPreKeyStore(),
        identityKeyStore: ModifiedInMemoryIdentityKeyStore(),
        userStore: InMemoryUserStore(),
      );

  @override
  Future<void> clear() async {}
}
