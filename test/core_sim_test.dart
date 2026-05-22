import 'dart:convert';
import 'dart:typed_data';
import 'package:ecp/ecp.dart';
import 'package:test/test.dart';

class MockMlsEngineConfigStore implements MlsEngineConfigStore {
  final String dbPath;
  MockMlsEngineConfigStore(this.dbPath);
  @override
  Future<MlsEngineConfig> getConfig() async {
    return MlsEngineConfig(
      dbPath: dbPath,
      encryptionKey: Uint8List(32),
    );
  }
}

class MockMlsCredentialStore implements MlsCredentialStore {
  MlsCredentialRecord? _record;
  @override
  Future<MlsCredentialRecord?> getCredential() async => _record;
  @override
  Future<void> saveCredential(MlsCredentialRecord record) async =>
      _record = record;
}

class MockMlsKeyPackageStore implements MlsKeyPackageStore {
  List<Uint8List> _packages = [];
  @override
  Future<List<Uint8List>> getKeyPackages() async => _packages;
  @override
  Future<void> saveKeyPackages(List<Uint8List> keyPackages) async =>
      _packages = keyPackages;
}

class MockUserStore implements UserStore {
  @override
  Future<int?> getDevice(Uri did) async => null;
  @override
  Future<Map<Uri, int>?> getUser(Uri id) async => null;
  @override
  Future<int?> removeDevice(Uri did) async => null;
  @override
  Future<int> saveDevice(Uri id, Uri did) async => 0;
}

class MockCapabilitiesStore implements CapabilitiesStore {
  @override
  Future<CapabilitiesWithTime?> getCapabilities() async => null;
  @override
  Future<void> saveCapabilities(Map<String, dynamic> capabilities) async {}
}

class InMemoryStorage extends Storage {
  InMemoryStorage(String name)
      : super(
          mlsEngineConfigStore: MockMlsEngineConfigStore('$name.db'),
          mlsCredentialStore: MockMlsCredentialStore(),
          mlsKeyPackageStore: MockMlsKeyPackageStore(),
          userStore: MockUserStore(),
          capabilitiesStore: MockCapabilitiesStore(),
        );

  @override
  Future<void> clear() async {}
}

void main() {
  setUpAll(() async {
    await Openmls.init();
  });

  test('Simulate 1:1 chat between Alice and Bob', () async {
    final aliceStorage = InMemoryStorage('alice');
    final bobStorage = InMemoryStorage('bob');

    final aliceCore = EcpCore(storage: aliceStorage);
    final bobCore = EcpCore(storage: bobStorage);

    final aliceBundle = await aliceCore.initializeIdentity(
      credentialIdentity: Uint8List.fromList(utf8.encode('alice')),
    );
    final bobBundle = await bobCore.initializeIdentity(
      credentialIdentity: Uint8List.fromList(utf8.encode('bob')),
    );

    final groupId = Uint8List(32);

    // Alice creates group
    await aliceCore.createGroup(groupId);

    // Alice adds Bob
    final addResult = await aliceCore.addMembers(
      groupId,
      [bobBundle.keyPackages.first],
    );

    // Bob joins from welcome
    await bobCore.joinGroupFromWelcome(addResult.welcome);

    // Alice sends message
    final msg = Uint8List.fromList(utf8.encode('Hello Bob!'));
    final encrypted = await aliceCore.encryptMessage(groupId, msg);

    // Bob decrypts
    final processed = await bobCore.decryptMessage(groupId, encrypted.ciphertext);
    expect(processed.messageType, ProcessedMessageType.application);
    expect(utf8.decode(processed.applicationMessage!), 'Hello Bob!');

    // Bob sends reply
    final reply = Uint8List.fromList(utf8.encode('Hi Alice!'));
    final encryptedReply = await bobCore.encryptMessage(groupId, reply);

    // Alice processes Bob's message
    // Since Alice added Bob, she has the group state.
    final aliceProcessed = await aliceCore.decryptMessage(
      groupId,
      encryptedReply.ciphertext,
    );
    expect(aliceProcessed.messageType, ProcessedMessageType.application);
    expect(utf8.decode(aliceProcessed.applicationMessage!), 'Hi Alice!');
  });

  test('Simulate group chat between Alice, Bob, and Charlie', () async {
    final aliceStorage = InMemoryStorage('alice_g');
    final bobStorage = InMemoryStorage('bob_g');
    final charlieStorage = InMemoryStorage('charlie_g');

    final aliceCore = EcpCore(storage: aliceStorage);
    final bobCore = EcpCore(storage: bobStorage);
    final charlieCore = EcpCore(storage: charlieStorage);

    final aliceBundle = await aliceCore.initializeIdentity(
      credentialIdentity: Uint8List.fromList(utf8.encode('alice')),
    );
    final bobBundle = await bobCore.initializeIdentity(
      credentialIdentity: Uint8List.fromList(utf8.encode('bob')),
    );
    final charlieBundle = await charlieCore.initializeIdentity(
      credentialIdentity: Uint8List.fromList(utf8.encode('charlie')),
    );

    final groupId = Uint8List.fromList(List.generate(32, (i) => i + 1));

    // Alice creates group
    await aliceCore.createGroup(groupId);

    // Alice adds Bob and Charlie
    final addResult = await aliceCore.addMembers(
      groupId,
      [bobBundle.keyPackages.first, charlieBundle.keyPackages.first],
    );

    // Bob and Charlie join from welcome
    await bobCore.joinGroupFromWelcome(addResult.welcome);
    await charlieCore.joinGroupFromWelcome(addResult.welcome);

    // Charlie sends message to the group
    final msg = Uint8List.fromList(utf8.encode('Hello everyone!'));
    final encrypted = await charlieCore.encryptMessage(groupId, msg);

    // Alice decrypts
    final aliceProcessed = await aliceCore.decryptMessage(groupId, encrypted.ciphertext);
    expect(aliceProcessed.messageType, ProcessedMessageType.application);
    expect(utf8.decode(aliceProcessed.applicationMessage!), 'Hello everyone!');

    // Bob decrypts
    final bobProcessed = await bobCore.decryptMessage(groupId, encrypted.ciphertext);
    expect(bobProcessed.messageType, ProcessedMessageType.application);
    expect(utf8.decode(bobProcessed.applicationMessage!), 'Hello everyone!');
  });
}
