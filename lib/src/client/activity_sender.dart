import 'dart:convert';
import 'package:ecp/src/client/types/person.dart';
import 'package:ecp/src/client/types/server_activities.dart';
import 'package:ecp/src/client/auth/request_authenticator.dart';
import 'package:http/http.dart' as http;

/// Handles sending activities to the outbox
class ActivitySender {
  final http.Client client;
  final Person me;
  final Uri did;
  final RequestAuthenticator? requestAuthenticator;

  ActivitySender({
    required this.client,
    required this.me,
    required this.did,
    this.requestAuthenticator,
  });

  /// Send a ServerActivity to the outbox
  /// Returns the response body for processing
  Future<http.Response> sendActivity(ServerActivity activity) async {
    final authHeaders = await requestAuthenticator?.call() ?? {};
    final response = await client.post(
      me.outbox,
      headers: {
        'Content-Type': 'application/json',
        ...authHeaders,
      },
      body: jsonEncode(activity.toJson()),
    );

    if (response.statusCode >= 400) {
      throw http.ClientException(
        "HTTP error ${response.statusCode}: ${response.body}",
        response.request?.url,
      );
    }

    return response;
  }
}
