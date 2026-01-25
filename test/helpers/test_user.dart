import 'test_config.dart';
import 'test_device.dart';

/// Represents a test user account that can have multiple devices
class TestUser {
  final int userNumber;
  final String email;
  final String password;
  final List<TestDevice> _devices = [];

  TestUser._({
    required this.userNumber,
    required this.email,
    required this.password,
  });

  /// Create a TestUser from environment variables
  static TestUser fromEnv({required int userNumber}) {
    return TestUser._(
      userNumber: userNumber,
      email: TestConfig.getEmail(userNumber),
      password: TestConfig.getPassword(userNumber),
    );
  }

  /// Add a new device for this user
  /// Returns the created TestDevice
  Future<TestDevice> addDevice({String? deviceName, Uri? baseUrl}) async {
    final device = await TestDevice.create(
      user: this,
      deviceName:
          deviceName ??
          TestConfig.deviceName(userNumber, deviceNumber: _devices.length + 1),
      baseUrl: baseUrl ?? TestConfig.baseUrl,
    );
    _devices.add(device);
    return device;
  }

  /// Get all devices for this user
  List<TestDevice> get devices => List.unmodifiable(_devices);

  /// Get the first device
  TestDevice get primaryDevice {
    if (_devices.isEmpty) {
      throw StateError('User has no devices. Call addDevice() first.');
    }
    return _devices.first;
  }

  /// Cleanup all devices for this user
  Future<void> cleanup() async {
    for (final device in _devices) {
      await device.cleanup();
    }
    _devices.clear();
  }
}
