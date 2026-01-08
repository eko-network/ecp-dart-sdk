import 'dart:convert';
import 'package:ecp/src/types/person.dart';
import 'package:http/http.dart' as http;

class ActorDiscovery {
  final http.Client client;
  final Uri baseUrl;

  ActorDiscovery({required this.client, required this.baseUrl});

  /// Get an actor by their WebFinger username (e.g., @user@example.com)
  Future<Person> getActorWithWebfinger(String username) async {
    final id = await webFinger(username);
    return getActor(id);
  }

  /// Get an actor by their ID URI
  Future<Person> getActor(Uri id) async {
    final response = await client.get(id);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch actor: ${response.statusCode}');
    }
    return Person.fromJson(jsonDecode(response.body));
  }

  /// Resolve a WebFinger username to an actor URI
  Future<Uri> webFinger(String username) async {
    final String host;
    final int? port;
    final String resource;

    if (username.contains('@')) {
      final cleanUsername = username.startsWith('@')
          ? username.substring(1)
          : username;

      final atIndex = cleanUsername.lastIndexOf('@');
      final userPart = cleanUsername.substring(0, atIndex);
      final hostPart = cleanUsername.substring(atIndex + 1);

      final colonIndex = hostPart.indexOf(':');
      if (colonIndex != -1) {
        host = hostPart.substring(0, colonIndex);
        port = int.tryParse(hostPart.substring(colonIndex + 1));
      } else {
        host = hostPart;
        port = null;
      }

      resource = 'acct:$userPart@$host';
    } else {
      // Use base URL
      host = baseUrl.host;
      port = baseUrl.port;
      final portSuffix = (port != 80 && port != 443) ? ':$port' : '';
      resource = 'acct:$username@$host$portSuffix';
    }

    final isLocal = host == '127.0.0.1' || host == 'localhost';
    final builder = isLocal ? Uri.http : Uri.https;
    final authority = port != null ? '$host:$port' : host;

    final url = builder(authority, '/.well-known/webfinger', {
      'resource': resource,
    });

    final response = await http.get(
      url,
      headers: {'Accept': 'application/jrd+json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch WebFinger for $username: '
        'HTTP ${response.statusCode} at $url',
      );
    }

    final data = jsonDecode(response.body);
    final links = data['links'] as List<dynamic>?;

    if (links == null) {
      throw Exception('Invalid WebFinger response: No links found');
    }

    final selfLink = links.firstWhere(
      (link) => link['rel'] == 'self',
      orElse: () => throw Exception('No "self" link found'),
    );

    return Uri.parse(selfLink['href'] as String);
  }
}
