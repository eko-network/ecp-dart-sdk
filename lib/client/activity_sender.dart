import 'dart:convert';
import 'dart:typed_data';

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
  Future<T> sendActivity<T extends WireActivity>(T activity) async {
    final payload = activity.toJson();
    final body = jsonEncode(payload);

    final response = await client.post(
      _me.outbox,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 409) {
      throw EcpEpochConflictException(response.body);
    }
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

    return WireActivity.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        )
        as T;
  }

  /// Claims [epoch] of [groupId] for this device, which then has a short
  /// while to send its commit to it.
  Future<void> claimEpoch(Uint8List groupId, BigInt epoch) async {
    final response = await client.post(
      _claimUrl(groupId),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'epoch': epoch.toInt()}),
    );
    if (response.statusCode == 409) {
      throw EcpEpochConflictException(response.body);
    }
    if (response.statusCode != 200) {
      throw EcpNetworkException(
        'Failed to claim epoch $epoch: ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }

  /// Gives up this device's claim on [groupId]'s epoch.
  Future<void> releaseEpoch(Uint8List groupId) async {
    final response = await client.delete(_claimUrl(groupId));
    if (response.statusCode >= 300) {
      throw EcpNetworkException(
        'Failed to release the epoch claim: ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }

  Uri _claimUrl(Uint8List groupId) => Uri.parse(_me.id.origin).replace(
    pathSegments: [
      'groups',
      base64Url.encode(groupId).replaceAll('=', ''),
      'claim',
    ],
  );
}
