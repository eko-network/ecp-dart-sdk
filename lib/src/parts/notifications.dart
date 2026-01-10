import 'dart:convert';

import 'package:ecp/src/types/capabilities.dart';
import 'package:http/http.dart' as http;

class NotificationHandler {
  final http.Client client;
  final WebPushCapabilities capability;
  NotificationHandler(this.client, this.capability);

  Future<void> register(String url, String p256dh, String auth) async {
    await client.post(
      capability.register,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'endpoint': url,
        'keys': {'p256dh': p256dh, 'auth': auth},
      }),
    );
  }

  Future<void> revoke(String url, String p256dh, String auth) async {}
}
