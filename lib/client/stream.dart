import 'dart:async';

import 'package:ecp/ecp.dart';

class MessageStreamConfig {
  final Duration pollInterval;

  const MessageStreamConfig({this.pollInterval = const Duration(seconds: 5)});
}

/// Polls the inbox and emits newly received [StoredMessage]s.
class MessageStreamController {
  MessageStreamController({
    required this.client,
    this.config = const MessageStreamConfig(),
  });

  final EcpClient client;
  final MessageStreamConfig config;

  StreamController<List<StoredMessage>>? _controller;
  Timer? _timer;
  bool _pollInProgress = false;
  bool _paused = false;
  bool _disposed = false;
  int _listenerCount = 0;
  bool _cancelOnError = false;

  bool get isPaused => _paused;

  void pause() {
    _paused = true;
    _stopTimer();
  }

  void resume() {
    if (_disposed) return;
    _paused = false;
    if (_listenerCount > 0) {
      _startTimer();
    }
  }

  Stream<List<StoredMessage>> messages({bool cancelOnError = false}) {
    _cancelOnError = cancelOnError;
    _controller ??= StreamController<List<StoredMessage>>.broadcast(
      onListen: _onListen,
      onCancel: _onCancel,
    );
    return _controller!.stream;
  }

  Stream<StoredMessage> messageEvents({bool cancelOnError = false}) async* {
    await for (final batch in messages(cancelOnError: cancelOnError)) {
      yield* Stream.fromIterable(batch);
    }
  }

  void dispose() {
    _disposed = true;
    _stopTimer();
    _controller?.close();
    _controller = null;
  }

  void _onListen() {
    _listenerCount++;
    if (!_paused) {
      _startTimer();
      unawaited(_poll());
    }
  }

  void _onCancel() {
    _listenerCount--;
    if (_listenerCount <= 0) {
      _listenerCount = 0;
      _stopTimer();
    }
  }

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
}
