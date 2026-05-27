/// Base exception for all ECP SDK errors.
class EcpException implements Exception {
  final String message;
  final Object? cause;

  const EcpException(this.message, {this.cause});

  @override
  String toString() {
    final causeStr = cause != null ? ' (caused by: $cause)' : '';
    return 'EcpException: $message$causeStr';
  }
}

/// Thrown when an HTTP request fails (non-2xx response or network error).
class EcpNetworkException extends EcpException {
  final int? statusCode;

  const EcpNetworkException(
    super.message, {
    this.statusCode,
    super.cause,
  });

  @override
  String toString() {
    final statusStr = statusCode != null ? ' [HTTP $statusCode]' : '';
    final causeStr = cause != null ? ' (caused by: $cause)' : '';
    return 'EcpNetworkException: $message$statusStr$causeStr';
  }
}

/// Thrown when MLS message decryption fails.
class EcpDecryptionException extends EcpException {
  const EcpDecryptionException(super.message, {super.cause});

  @override
  String toString() => 'EcpDecryptionException: $message';
}

/// Thrown when WebFinger or actor discovery fails.
class EcpDiscoveryException extends EcpException {
  const EcpDiscoveryException(super.message, {super.cause});

  @override
  String toString() => 'EcpDiscoveryException: $message';
}

/// Thrown when fetching or parsing server capabilities fails.
class EcpCapabilitiesException extends EcpException {
  const EcpCapabilitiesException(super.message, {super.cause});

  @override
  String toString() => 'EcpCapabilitiesException: $message';
}
