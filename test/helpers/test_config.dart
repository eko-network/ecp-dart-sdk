import 'dart:io';

class TestConfig {
  static Uri get baseUrl => Uri.parse('http://localhost:3000');

  static String getEmail(int userNumber) {
    final email = Platform.environment['USER${userNumber}_EMAIL'];
    if (email == null) {
      throw StateError('Environment variable USER${userNumber}_EMAIL not set.');
    }
    return email;
  }

  static String getPassword(int userNumber) {
    final password = Platform.environment['USER${userNumber}_PASSWORD'];
    if (password == null) {
      throw StateError(
        'Environment variable USER${userNumber}_PASSWORD not set.',
      );
    }
    return password;
  }

  static String deviceName(int userNumber, {int deviceNumber = 1}) =>
      'test-device-$userNumber-$deviceNumber';
}
