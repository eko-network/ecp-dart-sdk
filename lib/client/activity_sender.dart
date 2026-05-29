import 'dart:convert';
import 'package:ecp/ecp.dart';
import 'package:http/http.dart' as http;

/// Handles sending activities to the outbox
class ActivitySender {
  final String did;
  final http.Client client;
  final EcpCore core;
  final Person _me;

  ActivitySender({required this.client, required this.did, required this.core})
    : _me = core.identity;

  /// Send a [WireActivity] to the outbox.
  /// Returns the response body for processing.
  Future<http.Response> sendActivity(WireActivity activity) async {
    final payload = activity.toJson();
    final body = jsonEncode(payload);

    assert(() {
      print('ECP outbox POST ${_me.outbox}\n$body');
      return true;
    }());

    final response = await client.post(
      _me.outbox,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode >= 400) {
      // ignore: avoid_print
      print(
        'ECP outbox POST ${_me.outbox} failed '
        '${response.statusCode}: ${response.body}\n'
        'Request body: $body',
      );
      throw http.ClientException(
        "HTTP error ${response.statusCode}: ${response.body}",
        response.request?.url,
      );
    }

    return response;
  }
}
