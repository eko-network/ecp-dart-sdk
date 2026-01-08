import 'package:ecp/src/parts/storage.dart';
import 'package:ecp/src/types/person.dart';
import 'package:ecp/src/types/key_bundle.dart';
import 'package:ecp/src/types/current_user_keys.dart';
import 'package:http/http.dart' as http;
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'dart:convert';

class SessionManager {
  final Storage storage;

  SessionManager({required this.storage});

  /// Build a session cipher for a specific address
  SessionCipher buildSessionCipher(SignalProtocolAddress address) {
    return SessionCipher(
      storage.sessionStore,
      storage.preKeyStore,
      storage.signedPreKeyStore,
      storage.identityKeyStore,
      address,
    );
  }

  /// Request keys from another user and establish sessions
  /// Returns list of device IDs
  Future<List<int>> requestKeys({
    required Person person,
    required http.Client client,
  }) async {
    final response = await client.get(person.keyBundle);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to request keys: ${response.statusCode}\n${response.body}',
      );
    }

    final jsonBody = jsonDecode(response.body) as List;
    final List<int> devices = [];

    for (final obj in jsonBody) {
      final bundle = KeyBundle.fromJson(obj);
      final remoteAddress = SignalProtocolAddress(
        person.id.toString(),
        bundle.did,
      );

      final sessionBuilder = SessionBuilder(
        storage.sessionStore,
        storage.preKeyStore,
        storage.signedPreKeyStore,
        storage.identityKeyStore,
        remoteAddress,
      );

      await sessionBuilder.processPreKeyBundle(bundle.toPreKeyBundle());
      devices.add(bundle.did);
      await storage.userStore.saveUser(person.id, bundle.did);
    }

    return devices;
  }

  /// Get or generate current user's keys
  Future<CurrentUserKeys> getCurrentUserKeys({required int numPreKeys}) async {
    final existingIdentity = await storage.identityKeyStore
        .getIdentityKeyPairOrNull();

    if (existingIdentity == null) {
      // Generate new keys
      final identityKeyPair = generateIdentityKeyPair();
      final registrationId = generateRegistrationId(false);
      final preKeys = generatePreKeys(0, numPreKeys);
      final signedPreKey = generateSignedPreKey(identityKeyPair, 0);

      // Store generated keys
      await storage.identityKeyStore.storeIdentityKeyPair(
        identityKeyPair,
        registrationId,
      );
      for (var p in preKeys) {
        await storage.preKeyStore.storePreKey(p.id, p);
      }
      await storage.signedPreKeyStore.storeSignedPreKey(
        signedPreKey.id,
        signedPreKey,
      );

      return CurrentUserKeys(
        registrationId: registrationId,
        preKeys: preKeys,
        signedPreKey: signedPreKey,
        identityKeyPair: identityKeyPair,
      );
    } else {
      // Load existing keys
      final identityKeyPair = await storage.identityKeyStore
          .getIdentityKeyPair();
      final registrationId = await storage.identityKeyStore
          .getLocalRegistrationId();
      final List<PreKeyRecord> preKeys = [];
      for (int i = 0; i < numPreKeys; i++) {
        preKeys.add(await storage.preKeyStore.loadPreKey(i));
      }
      final signedPreKey = await storage.signedPreKeyStore.loadSignedPreKey(0);

      return CurrentUserKeys(
        registrationId: registrationId,
        preKeys: preKeys,
        signedPreKey: signedPreKey,
        identityKeyPair: identityKeyPair,
      );
    }
  }
}
