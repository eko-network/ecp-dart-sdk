import 'dart:convert';

/// RFC 8785 canonical JSON serialization.
///
/// Produces deterministic JSON output by sorting object keys
/// alphabetically. Used for computing hashes and HMAC signatures
/// over JSON objects (e.g., device hash chain, group control messages).
///
/// Ref: https://github.com/aps-lab/jcs_dart/blob/master/lib/src/jcs_dart_base.dart

void _serialize(Object? o, StringBuffer sb) {
  if (o == null || o is num || o is bool || o is String) {
    // Primitive type
    sb.write(json.encode(o));
  } else if (o is List) {
    // Array - Maintain element order
    sb.write('[');
    var next = false;
    for (final element in o) {
      if (next) {
        sb.write(',');
      }
      next = true;
      // Array element - Recursive expansion
      _serialize(element, sb);
    }
    sb.write(']');
  } else if (o is Map) {
    // Object - Sort properties before serializing
    sb.write('{');
    var next = false;
    final keys = List<String>.from(o.keys);
    keys.sort();
    for (final element in keys) {
      if (next) {
        sb.write(',');
      }
      next = true;
      // Property names are strings - Use ES6/JSON
      sb.write(json.encode(element));
      sb.write(':');
      // Property value - Recursive expansion
      _serialize(o[element], sb);
    }
    sb.write('}');
  }
}

/// Serialize an object to RFC 8785 canonical JSON string.
///
/// Map keys are sorted alphabetically, primitives use standard
/// JSON encoding, and arrays maintain element order.
String toCanonicalJson(Object? o) {
  final sb = StringBuffer();
  _serialize(o, sb);
  return sb.toString();
}
