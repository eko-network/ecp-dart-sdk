import 'dart:convert';

import 'package:http/http.dart' as http;

class NotificationConfig {
  final Uri register;
  final Uri revoke;
  final http.Client client;
  NotificationConfig({
    required this.register,
    required this.revoke,
    required this.client,
  });
}

class NotificationHandler {
  final NotificationConfig config;
  NotificationHandler(this.config);

  Future<Uri> register(String fcm) async {
    final response = await config.client.post(
      config.register,
      headers: {'Content-Type': 'application/json'},
      //FIXME not sure I want platform
      body: {'token': fcm, 'platform': 'test-platform'},
    );
    return Uri.parse(jsonDecode(response.body)['url']);
  }
}
