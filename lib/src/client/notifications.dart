import 'dart:convert';

import 'package:ecp/src/client/types/capabilities.dart';
import 'package:ecp/src/client/auth/request_authenticator.dart';
import 'package:http/http.dart' as http;

class NotificationHandler {
  final http.Client client;
  final WebPushCapabilities capability;
  final RequestAuthenticator? requestAuthenticator;
  NotificationHandler(this.client, this.capability, {this.requestAuthenticator});

  Future<void> register(String url, String p256dh, String auth) async {
    final authHeaders = await requestAuthenticator?.call() ?? {};
    await client.post(
      capability.register,
      headers: {
        'Content-Type': 'application/json',
        ...authHeaders,
      },
      body: jsonEncode({
        'endpoint': url,
        'keys': {'p256dh': p256dh, 'auth': auth},
      }),
    );
  }

  Future<void> revoke(String url, String p256dh, String auth) async {}
}
