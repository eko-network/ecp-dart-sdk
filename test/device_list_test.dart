import 'package:test/test.dart';
import 'package:ecp/src/types/device_list.dart';

void main() {
  group('DeviceList', () {
    test('should create empty device list', () {
      final deviceList = DeviceList();
      expect(deviceList.events, isEmpty);
      expect(deviceList.validate(), isTrue);
    });

    test('should add device with null prev for first device', () {
      final deviceList = DeviceList();

      final addDevice = deviceList.addDevice(
        id: Uri.parse('https://eko.network/user/devices/actions/1'),
        did: Uri.parse('1'),
        keyPackage: Uri.parse('https://eko.network/user/user1/keyPackage'),
        publicKey: 'publicKey1',
      );

      expect(addDevice.prev, isNull);
      expect(deviceList.events.length, 1);
      expect(deviceList.validate(), isTrue);
    });

    test('should create valid hash chain for multiple devices', () {
      final deviceList = DeviceList();

      // Add first device
      deviceList.addDevice(
        id: Uri.parse('https://eko.network/user/devices/actions/1'),
        did: Uri.parse('1'),
        keyPackage: Uri.parse('https://eko.network/user/user1/keyPackage'),
        publicKey: 'publicKey1',
      );

      // Add second device
      final secondDevice = deviceList.addDevice(
        id: Uri.parse('https://eko.network/user/devices/actions/2'),
        did: Uri.parse('2'),
        keyPackage: Uri.parse('https://eko.network/user/user2/keyPackage'),
        publicKey: 'publicKey2',
      );

      expect(secondDevice.prev, isNotNull);
      expect(deviceList.events.length, 2);
      expect(deviceList.validate(), isTrue);
    });

    test('should compute correct prev hash', () {
      final deviceList = DeviceList();

      final firstDevice = deviceList.addDevice(
        id: Uri.parse('https://eko.network/user/devices/actions/1'),
        did: Uri.parse('1'),
        keyPackage: Uri.parse('https://eko.network/user/user1/keyPackage'),
        publicKey: 'publicKey1',
      );

      final firstHash = computeHash(firstDevice.toCanonicalJson());

      final secondDevice = deviceList.addDevice(
        id: Uri.parse('https://eko.network/user/devices/actions/2'),
        did: Uri.parse('2'),
        keyPackage: Uri.parse('https://eko.network/user/user2/keyPackage'),
        publicKey: 'publicKey2',
      );

      expect(secondDevice.prev, equals(firstHash));
    });

    test('should revoke device', () {
      final deviceList = DeviceList();

      deviceList.addDevice(
        id: Uri.parse('https://eko.network/user/devices/actions/1'),
        did: Uri.parse('1'),
        keyPackage: Uri.parse('https://eko.network/user/user1/keyPackage'),
        publicKey: 'publicKey1',
      );

      deviceList.revokeDevice(
        id: Uri.parse('https://eko.network/user/devices/actions/2'),
        did: Uri.parse('1'),
      );

      expect(deviceList.events.length, 2);
      expect(deviceList.validate(), isTrue);
      expect(deviceList.events[1], isA<RevokeDevice>());
    });

    test('should track active devices correctly', () {
      final deviceList = DeviceList();

      // Add devices
      deviceList.addDevice(
        id: Uri.parse('https://eko.network/user/devices/actions/1'),
        did: Uri.parse('1'),
        keyPackage: Uri.parse('https://eko.network/user/user1/keyPackage'),
        publicKey: 'publicKey1',
      );

      deviceList.addDevice(
        id: Uri.parse('https://eko.network/user/devices/actions/2'),
        did: Uri.parse('2'),
        keyPackage: Uri.parse('https://eko.network/user/user2/keyPackage'),
        publicKey: 'publicKey2',
      );

      // Revoke device 1
      deviceList.revokeDevice(
        id: Uri.parse('https://eko.network/user/devices/actions/3'),
        did: Uri.parse('1'),
      );

      final activeDevices = deviceList.getActiveDevices();
      expect(activeDevices.length, 1);
      expect(activeDevices[0].did, Uri.parse('2'));
    });

    test('should validate hash chain correctly', () {
      final deviceList = DeviceList();

      deviceList.addDevice(
        id: Uri.parse('https://eko.network/user/devices/actions/1'),
        did: Uri.parse('1'),
        keyPackage: Uri.parse('https://eko.network/user/user1/keyPackage'),
        publicKey: 'publicKey1',
      );

      deviceList.addDevice(
        id: Uri.parse('https://eko.network/user/devices/actions/2'),
        did: Uri.parse('2'),
        keyPackage: Uri.parse('https://eko.network/user/user2/keyPackage'),
        publicKey: 'publicKey2',
      );

      expect(deviceList.validate(), isTrue);
    });

    test('should detect invalid hash chain', () {
      final device1 = AddDevice(
        id: Uri.parse('https://eko.network/user/devices/actions/1'),
        prev: null,
        did: Uri.parse('1'),
        keyPackage: Uri.parse('https://eko.network/user/user1/keyPackage'),
        publicKey: 'publicKey1',
        signatures: {},
      );

      final device2 = AddDevice(
        id: Uri.parse('https://eko.network/user/devices/actions/2'),
        prev: 'invalid_hash',
        did: Uri.parse('2'),
        keyPackage: Uri.parse('https://eko.network/user/user2/keyPackage'),
        publicKey: 'publicKey2',
        signatures: {},
      );

      final deviceList = DeviceList(events: [device1, device2]);
      expect(deviceList.validate(), isFalse);
    });

    test('should serialize and deserialize to JSON', () {
      final deviceList = DeviceList();

      deviceList.addDevice(
        id: Uri.parse('https://eko.network/user/devices/actions/1'),
        did: Uri.parse('1'),
        keyPackage: Uri.parse('https://eko.network/user/user1/keyPackage'),
        publicKey: 'publicKey1',
      );

      deviceList.revokeDevice(
        id: Uri.parse('https://eko.network/user/devices/actions/2'),
        did: Uri.parse('1'),
      );

      final json = deviceList.toJson();
      final reconstructed = DeviceList.fromJson(json);

      expect(reconstructed.events.length, 2);
      expect(reconstructed.validate(), isTrue);
      expect(reconstructed.events[0], isA<AddDevice>());
      expect(reconstructed.events[1], isA<RevokeDevice>());
    });

    test('should produce valid AddDevice JSON structure', () {
      final addDevice = AddDevice(
        id: Uri.parse('https://eko.network/user/devices/actions/1'),
        prev: null,
        did: Uri.parse('1'),
        keyPackage: Uri.parse('https://eko.network/user/user1/keyPackage'),
        publicKey: 'testPublicKey',
        signatures: {'1': 'signature1'},
      );

      final json = addDevice.toJson();

      expect(
        json['@context'],
        contains('https://www.w3.org/ns/activitystreams'),
      );
      expect(json['@context'], contains('https://eko.network/ns'));
      expect(json['type'], equals('AddDevice'));
      expect(json['id'], equals('https://eko.network/user/devices/actions/1'));
      expect(json['prev'], isNull);
      expect(json['did'], equals('1'));
      expect(
        json['eko:keyPackage'],
        equals('https://eko.network/user/user1/keyPackage'),
      );
      expect(json['publicKey'], equals('testPublicKey'));
      expect(json['signatures'], equals({'1': 'signature1'}));
    });

    test('should produce valid RevokeDevice JSON structure', () {
      final revokeDevice = RevokeDevice(
        id: Uri.parse('https://eko.network/user/devices/actions/2'),
        did: Uri.parse('1'),
        prev: 'somehash',
        signatures: {'1': 'signature1'},
      );

      final json = revokeDevice.toJson();

      expect(
        json['@context'],
        contains('https://www.w3.org/ns/activitystreams'),
      );
      expect(json['@context'], contains('https://eko.network/ns'));
      expect(json['type'], equals('RevokeDevice'));
      expect(json['id'], equals('https://eko.network/user/devices/actions/2'));
      expect(json['prev'], equals('somehash'));
      expect(json['did'], equals('1'));
      expect(json['signatures'], equals({'1': 'signature1'}));
    });
  });
}
