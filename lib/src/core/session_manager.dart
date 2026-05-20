import 'dart:typed_data';
import 'types/storage.dart';
import 'types/identity_bundle.dart';

class SessionManager {
  final Storage storage;

  SessionManager({required this.storage});

  Future<IdentityBundle> getCurrentUserCredential({
    required int numKeyPackages,
    required Uint8List credentialIdentity,
  }) async {
    return IdentityBundle.fromUser(
      credentialIdentity: credentialIdentity,
      storage: storage,
      numKeyPackages: numKeyPackages,
    );
  }
}
