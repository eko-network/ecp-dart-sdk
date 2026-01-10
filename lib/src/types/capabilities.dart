class WebPushCapabilities {
  final String vapidPublicKey;
  final Uri register;
  final Uri revoke;

  WebPushCapabilities({
    required this.vapidPublicKey,
    required this.register,
    required this.revoke,
  });

  factory WebPushCapabilities.fromJson(Map<String, dynamic> json) {
    final webPushJson = json['webpush'];
    return WebPushCapabilities(
      vapidPublicKey: webPushJson['vapid']['publicKey'] as String,
      register: Uri.parse(webPushJson['endpoints']['register']),
      revoke: Uri.parse(webPushJson['endpoints']['revoke']),
    );
  }
}

class SocketCapabilities {
  final Uri endpoint;
  final String auth;

  SocketCapabilities({required this.endpoint, required this.auth});

  factory SocketCapabilities.fromJson(Map<String, dynamic> json) {
    final webSocketJson = json['websocket'];
    return SocketCapabilities(
      endpoint: Uri.parse(webSocketJson['endpoint'] as String),
      auth: webSocketJson['auth'] as String,
    );
  }
}

class Capabilities {
  final Map<String, dynamic> _json;
  late final SocketCapabilities? socket;
  late final WebPushCapabilities? webPush;
  Capabilities._(this._json) {
    try {
      socket = SocketCapabilities.fromJson(json);
    } catch (_) {
      socket = null;
    }
    try {
      webPush = WebPushCapabilities.fromJson(json);
    } catch (_) {
      webPush = null;
    }
  }
  factory Capabilities.fromJson(Map<String, dynamic> json) {
    return Capabilities._(json);
  }

  Uri? get spec => Uri.tryParse(_json['spec']);
  String? get protocol => _json['protocol'];
  Map<String, dynamic> get json => Map.unmodifiable(_json);
}
