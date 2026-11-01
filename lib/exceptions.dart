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

/// Thrown when a WebSocket connection fails.
class EcpWebSocketException extends EcpException {
  const EcpWebSocketException(super.message, {super.cause});

  @override
  String toString() => 'EcpWebSocketException: $message';
}

/// Thrown when a user's device chain fails verification, or a key package
/// does not belong to the device the chain lists.
class EcpDeviceChainException extends EcpException {
  const EcpDeviceChainException(super.message, {super.cause});

  @override
  String toString() => 'EcpDeviceChainException: $message';
}

/// Thrown when a user's device chain no longer extends the one this device
/// pinned: their devices were reset, or the server is trying to swap them.
/// Nothing is sent to the user's devices until the new chain is accepted with
/// [DeviceManager.trust].
class EcpDeviceChainChangedException extends EcpException {
  final Uri actor;

  const EcpDeviceChainChangedException(this.actor)
    : super('The devices of $actor changed');

  @override
  String toString() => 'EcpDeviceChainChangedException: $message';
}

/// Thrown when the server turns down a claim on a group's epoch, or a commit
/// to it: another device is committing, or the group moved on. Catching up on
/// the inbox and trying again can succeed.
class EcpEpochConflictException extends EcpException {
  const EcpEpochConflictException(super.message);

  @override
  String toString() => 'EcpEpochConflictException: $message';
}
