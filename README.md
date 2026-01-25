# ECP Dart SDK

A Dart SDK for implementing the Eko Communication Protocol (ECP), an ActivityPub extension enabling secure, end-to-end encrypted messaging with the Signal protocol.

## Features

- **End-to-end encryption** using the Signal protocol (libsignal)
- **Actor discovery** via WebFinger
- **Encrypted messaging** with key management
- **Server capabilities** detection and caching
- **WebSocket streams** for real-time messages
- **Web push notifications** support
- **Storage abstraction** for keys and messages

## Getting started

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  ecp:
    git:
        url: https://github.com/eko-network/ecp-dart-sdk
        ref: main
```

Implement the `Storage` interface to provide persistent storage for keys and capabilities.

## Usage

```dart
import 'package:ecp/ecp.dart';
import 'package:http/http.dart' as http;

// Initialize the client
final client = await EcpClient.build(
  storage: yourStorageImplementation,
  client: http.Client(),
  me: currentUser,
  did: userDid,
);

// Discover an actor
final person = await client.getActorWithWebfinger('user@example.com');

// Send an encrypted message
await client.sendMessage(
  person: person,
  message: yourActivity,
);

// Get messages
final messages = await client.getMessages();

// Listen to real-time messages
client.messageStreamController.stream.listen((message) {
  print('New message: $message');
});
```

## Additional information

This package is in early development.
