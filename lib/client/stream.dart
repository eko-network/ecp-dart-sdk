import 'dart:async';
import 'dart:convert';

import 'package:ecp/ecp.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MessageStreamConfig {
  final Duration pollInterval;
  final bool useWebSocket;
  final Duration reconnectDelay;
  final Duration maxReconnectDelay;

  /// Detects a dead connection, and keeps proxies from closing an idle one.
  final Duration pingInterval;

  const MessageStreamConfig({
    this.pollInterval = const Duration(seconds: 5),
    this.useWebSocket = false,
    this.reconnectDelay = const Duration(seconds: 1),
    this.maxReconnectDelay = const Duration(seconds: 30),
    this.pingInterval = const Duration(seconds: 25),
  });
}

enum WebSocketState {
  disconnected,
  connecting,
  connected,
  authenticated,
  failed,
}

/// Polls the inbox or listens via WebSocket and emits newly received [ReceivedEvent]s.
class MessageStreamController {
  MessageStreamController({
    required this.client,
    this.config = const MessageStreamConfig(),
  });

  final EcpClient client;
  final MessageStreamConfig config;

  StreamController<List<ReceivedEvent>>? _controller;
  StreamController<WebSocketState>? _wsStateController;
  Timer? _timer;
  bool _pollInProgress = false;
  bool _paused = false;
  bool _disposed = false;
  int _listenerCount = 0;
  bool _cancelOnError = false;

  WebSocketChannel? _wsChannel;
  StreamSubscription<dynamic>? _wsSubscription;
  WebSocketState _wsState = WebSocketState.disconnected;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  bool get isPaused => _paused;
  WebSocketState get webSocketState => _wsState;

  Stream<WebSocketState> get webSocketStateChanges {
    _wsStateController ??= StreamController<WebSocketState>.broadcast();
    return _wsStateController!.stream;
  }

  void pause() {
    _paused = true;
    _stopAll();
  }

  void resume() {
    if (_disposed) return;
    _paused = false;
    if (_listenerCount > 0) {
      if (config.useWebSocket) {
        _connectWebSocket();
      } else {
        _startTimer();
        unawaited(_poll());
      }
    }
  }

  Stream<List<ReceivedEvent>> messages({bool cancelOnError = false}) {
    _cancelOnError = cancelOnError;
    _controller ??= StreamController<List<ReceivedEvent>>.broadcast(
      onListen: _onListen,
      onCancel: _onCancel,
    );
    return _controller!.stream;
  }

  Stream<ReceivedEvent> messageEvents({bool cancelOnError = false}) async* {
    await for (final batch in messages(cancelOnError: cancelOnError)) {
      yield* Stream.fromIterable(batch);
    }
  }

  void dispose() {
    _disposed = true;
    _stopAll();
    _controller?.close();
    _controller = null;
    _wsStateController?.close();
    _wsStateController = null;
  }

  void _onListen() {
    _listenerCount++;
    if (!_paused) {
      if (config.useWebSocket) {
        _connectWebSocket();
      } else {
        _startTimer();
        unawaited(_poll());
      }
    }
  }

  void _onCancel() {
    _listenerCount--;
    if (_listenerCount <= 0) {
      _listenerCount = 0;
      _stopAll();
    }
  }

  void _stopAll() {
    _stopTimer();
    _disconnectWebSocket();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _emitWsState(WebSocketState state) {
    _wsState = state;
    _wsStateController?.add(state);
  }

  // for polling

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(config.pollInterval, (_) => _poll());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    if (_disposed || _paused || _pollInProgress) return;

    _pollInProgress = true;
    try {
      final messages = await client.getInbox();
      if (messages.isNotEmpty) {
        _controller?.add(messages);
      }
    } catch (e, st) {
      if (_cancelOnError) {
        _controller?.addError(e, st);
        dispose();
      }
    } finally {
      _pollInProgress = false;
    }
  }

  // for websockets

  Future<void> _connectWebSocket() async {
    if (_disposed || _paused) return;
    if (_wsState == WebSocketState.connecting) return;

    final socketEndpoint = client.capabilities.socket?.endpoint;
    if (socketEndpoint == null) {
      _emitWsState(WebSocketState.failed);
      _startTimer();
      return;
    }

    _emitWsState(WebSocketState.connecting);

    try {
      final token = await client.getAuthToken();
      final channel = IOWebSocketChannel.connect(
        socketEndpoint,
        headers: {'Authorization': 'Bearer $token'},
        pingInterval: config.pingInterval,
      );
      _wsChannel = channel;
      _emitWsState(WebSocketState.connected);
      // connect returns before the handshake, a rejected one must keep
      // backing off
      unawaited(
        channel.ready.then((_) {
          if (_wsChannel == channel) _reconnectAttempts = 0;
        }, onError: (_) {}),
      );

      _wsSubscription = channel.stream.listen(
        _handleWsMessage,
        onError: _handleWsError,
        onDone: _handleWsDone,
        cancelOnError: false,
      );
    } catch (e) {
      _emitWsState(WebSocketState.failed);
      _scheduleReconnect();
    }
  }

  void _handleWsMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String);

      if (json is Map<String, dynamic>) {
        if (json['type'] == 'auth') {
          _emitWsState(
            json['status'] == 'ok'
                ? WebSocketState.authenticated
                : WebSocketState.failed,
          );
          return;
        }
      }

      unawaited(
        client.handleInbox(json).then((messages) {
          if (messages.isNotEmpty && !_disposed) {
            _controller?.add(messages);
          }
        }),
      );
    } catch (e, st) {
      if (_cancelOnError) {
        _controller?.addError(e, st);
        dispose();
      }
    }
  }

  void _handleWsError(Object error) {
    _emitWsState(WebSocketState.failed);
    if (_cancelOnError && !_disposed) {
      _controller?.addError(error);
      dispose();
    } else if (!_disposed) {
      _scheduleReconnect();
    }
  }

  void _handleWsDone() {
    _emitWsState(WebSocketState.disconnected);
    if (!_disposed && !_paused) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed || _paused || _reconnectTimer != null) return;

    _reconnectAttempts++;

    final delay = Duration(
      milliseconds:
          (config.reconnectDelay.inMilliseconds *
                  (1 << (_reconnectAttempts - 1)))
              .clamp(0, config.maxReconnectDelay.inMilliseconds),
    );

    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (!_disposed && !_paused) {
        _connectWebSocket();
      }
    });
  }

  void _disconnectWebSocket() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _wsChannel?.sink.close();
    _wsChannel = null;
    _emitWsState(WebSocketState.disconnected);
  }
}
