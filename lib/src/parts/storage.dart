import 'package:ecp/src/types/typedefs.dart';
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

abstract class UserStore {
  Future<void> saveUser(Uri id, int did);
  Future<List<int>?> getUser(Uri id);
}

abstract class CapabilitiesStore {
  Future<void> saveCapabilities(Map<String, dynamic> capabilities);
  Future<CapabilitiesWithTime?> getCapabilities();
}

abstract class Storage {
  final IdentityKeyStore identityKeyStore;
  final libsignal.PreKeyStore preKeyStore;
  final libsignal.SessionStore sessionStore;
  final libsignal.SignedPreKeyStore signedPreKeyStore;
  final UserStore userStore;
  final CapabilitiesStore capabilitiesStore;
  Storage({
    required this.identityKeyStore,
    required this.preKeyStore,
    required this.sessionStore,
    required this.signedPreKeyStore,
    required this.userStore,
    required this.capabilitiesStore,
  });

  Future<void> clear();
}
