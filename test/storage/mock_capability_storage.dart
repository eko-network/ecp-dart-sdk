import 'package:ecp/ecp.dart';

class InMemoryCapabilitiesStore implements CapabilitiesStore {
  Map<String, dynamic>? _capabilities;
  DateTime? _timestamp;

  @override
  Future<CapabilitiesWithTime?> getCapabilities() async {
    if (_capabilities != null && _timestamp != null) {
      return (capabilities: _capabilities!, timestamp: _timestamp!);
    }
    return null;
  }

  @override
  Future<void> saveCapabilities(Map<String, dynamic> capabilities) async {
    _capabilities = capabilities;
    _timestamp = DateTime.now();
  }
}
