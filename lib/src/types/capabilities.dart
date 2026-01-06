class Capabilities {
  final Map<String, dynamic> _json;
  const Capabilities(this._json);
  factory Capabilities.fromJson(Map<String, dynamic> json) {
    return Capabilities(json);
  }

  Uri? get socket => Uri.tryParse(_json['websocket']);
  Uri? get spec => Uri.tryParse(_json['spec']);
  String? get protocol => _json['protocol'];
  Map<String, dynamic> get json => _json;
}
