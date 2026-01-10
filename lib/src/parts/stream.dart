import 'dart:async';
import 'package:ecp/src/ecp_client.dart';
import 'package:ecp/src/parts/messages.dart';
import 'package:ecp/src/types/activity_with_recipients.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class MessageStreamConfig {
  final Duration pollingInterval;
  final int maxRetries;
  final Duration retryDelay;
  final Duration websocketReconnectDelay;
  final bool preferWebSocket;

  const MessageStreamConfig({
    this.pollingInterval = const Duration(seconds: 5),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.websocketReconnectDelay = const Duration(seconds: 5),
    this.preferWebSocket = true,
  });
}

/// Controller for managing message streams
class MessageStreamController {
  final EcpClient client;
  final MessageStreamConfig config;

  StreamController<List<ActivityWithRecipients>>? _streamController;
  WebSocketChannel? _webSocketChannel;
  Timer? _pollingTimer;
  Timer? _reconnectTimer;
  bool _isPaused = false;
  bool _isDisposed = false;
  bool _shouldUseWebSocket = false;
  Uri? _socketUrl;
  StreamSubscription? _websocketSubscription;

  MessageStreamController({
    required this.client,
    this.config = const MessageStreamConfig(),
  });

  /// Pause the message stream and close connections
  void pause() {
    _isPaused = true;
    _closeCurrentConnection();
  }

  /// Resume the message stream and reconnect
  void resume() {
    _isPaused = false;

    // Restart streaming
    if (_webSocketChannel == null && _pollingTimer == null) {
      if (_shouldUseWebSocket && _socketUrl != null) {
        _tryWebSocket(_socketUrl!, false);
      } else {
        _startPolling();
      }
    }
  }

  /// Check if the stream is currently paused
  bool get isPaused => _isPaused;

  /// Check if WebSocket is currently active
  bool get isUsingWebSocket => _webSocketChannel != null;

  /// Check if polling is currently active
  bool get isUsingPolling => _pollingTimer != null;

  /// Manually retry WebSocket connection (useful after connectivity is restored)
  Future<void> retryWebSocket() async {
    if (_socketUrl != null && config.preferWebSocket) {
      _closeCurrentConnection();
      await _tryWebSocket(_socketUrl!, false);
    }
  }

  Stream<List<ActivityWithRecipients>> getMessagesStream({
    bool cancelOnError = false,
  }) async* {
    _streamController =
        StreamController<List<ActivityWithRecipients>>.broadcast();

    try {
      _socketUrl = client.capabilities.socket?.endpoint;

      if (_socketUrl != null && config.preferWebSocket) {
        _shouldUseWebSocket = true;
        await _tryWebSocket(_socketUrl!, cancelOnError);
      } else {
        _shouldUseWebSocket = false;
        _startPolling();
      }

      yield* _streamController!.stream;
    } catch (e) {
      if (cancelOnError) {
        rethrow;
      }
    }
  }

  Future<void> _tryWebSocket(Uri socketUrl, bool cancelOnError) async {
    if (_isPaused || _isDisposed) return;

    try {
      // Get the authentication token
      final token = await client.getAuthToken();

      if (token == null) {
        _closeWebSocket();
        return;
      }

      // Connect with Authorization header
      _webSocketChannel = IOWebSocketChannel.connect(
        socketUrl,
        headers: {'Authorization': 'Bearer $token'},
      );

      _websocketSubscription = _webSocketChannel!.stream.listen(
        (data) async {
          if (_isPaused || _isDisposed) return;

          try {
            final messages = await _parseWebSocketData(data);
            _streamController?.add(messages);
          } catch (e) {
            if (cancelOnError) {
              _streamController?.addError(e);
            }
          }
        },
        onError: (error) async {
          if (_isDisposed) return;

          // WebSocket failed, fall back to polling
          _closeWebSocket();

          if (!cancelOnError && !_isPaused) {
            await Future.delayed(config.websocketReconnectDelay);
            if (!_isDisposed && !_isPaused) {
              _startPolling();
            }
          } else if (cancelOnError) {
            _streamController?.addError(error);
          }
        },
        onDone: () async {
          if (_isDisposed) return;

          // WebSocket closed, fall back to polling
          _closeWebSocket();

          if (!_isPaused) {
            await Future.delayed(config.websocketReconnectDelay);
            if (!_isDisposed && !_isPaused) {
              _startPolling();
            }
          }
        },
        cancelOnError: cancelOnError,
      );

      if (_isPaused) {
        _websocketSubscription?.pause();
      }
    } catch (e) {
      // Failed to establish WebSocket, fall back to polling
      _closeWebSocket();

      if (!_isPaused) {
        _startPolling();
      }
    }
  }

  void _startPolling() {
    if (_isPaused || _isDisposed) return;

    int retryCount = 0;

    void poll() async {
      if (_isPaused || _isDisposed || _webSocketChannel != null) {
        return;
      }

      try {
        final messages = await client.getMessages();
        _streamController?.add(messages);
        retryCount = 0;

        // Try to reconnect to WebSocket after successful polling if preferred
        if (_shouldUseWebSocket &&
            _socketUrl != null &&
            config.preferWebSocket &&
            !_isDisposed &&
            !_isPaused) {
          // Schedule a WebSocket reconnection attempt
          _reconnectTimer?.cancel();
          _reconnectTimer = Timer(config.websocketReconnectDelay, () {
            if (!_isDisposed && !_isPaused && _webSocketChannel == null) {
              _tryWebSocket(_socketUrl!, false);
            }
          });
        }

        if (!_isDisposed && !_isPaused) {
          _pollingTimer = Timer(config.pollingInterval, poll);
        }
      } catch (e) {
        if (retryCount >= config.maxRetries) {
          _streamController?.addError(e);
          retryCount = 0;

          if (!_isDisposed && !_isPaused) {
            _pollingTimer = Timer(config.pollingInterval, poll);
          }
        } else {
          retryCount++;
          if (!_isDisposed && !_isPaused) {
            _pollingTimer = Timer(config.retryDelay, poll);
          }
        }
      }
    }

    poll();
  }

  Future<List<ActivityWithRecipients>> _parseWebSocketData(dynamic data) async {
    // Create a handler to parse activities
    final handler = MessageHandler(
      storage: client.storage,
      client: client.client,
      me: client.me,
      did: client.did,
    );
    return handler.parseActivities(data);
  }

  void _closeWebSocket() {
    _websocketSubscription?.cancel();
    _websocketSubscription = null;
    _webSocketChannel?.sink.close();
    _webSocketChannel = null;
  }

  void _closeCurrentConnection() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _closeWebSocket();
  }

  Stream<List<ActivityWithRecipients>> getMessagesBroadcastStream({
    bool cancelOnError = false,
  }) {
    return getMessagesStream(cancelOnError: cancelOnError).asBroadcastStream();
  }

  Stream<ActivityWithRecipients> getMessageStream({
    bool cancelOnError = false,
  }) async* {
    await for (final messageList in getMessagesStream(
      cancelOnError: cancelOnError,
    )) {
      for (final message in messageList) {
        yield message;
      }
    }
  }

  /// Dispose of the controller and clean up resources
  void dispose() {
    _isDisposed = true;
    _closeCurrentConnection();
    _streamController?.close();
  }
}
