// import 'dart:async';
// import 'package:ecp/src/ecp_client.dart';
// import 'package:ecp/src/client/messages.dart';
// import 'package:ecp/src/client/types/typedefs.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/io.dart';
//
// class MessageStreamConfig {
//   final Duration websocketReconnectDelay;
//   final bool preferWebSocket;
//
//   const MessageStreamConfig({
//     this.websocketReconnectDelay = const Duration(seconds: 5),
//     this.preferWebSocket = true,
//   });
// }
//
// class MessageStreamController {
//   final EcpClient client;
//   final MessageHandler messageHandler;
//   final MessageStreamConfig config;
//
//   StreamController<List<ActivityWithMetaData>>? _streamController;
//   WebSocketChannel? _webSocketChannel;
//   Timer? _reconnectTimer;
//   bool _isPaused = false;
//   bool _isDisposed = false;
//   Uri? _socketUrl;
//   StreamSubscription? _websocketSubscription;
//
//   MessageStreamController({
//     required this.messageHandler,
//     required this.client,
//     this.config = const MessageStreamConfig(),
//   });
//
//   bool get supportsStreaming => client.capabilities.socket?.endpoint != null;
//
//   void pause() {
//     _isPaused = true;
//     _closeCurrentConnection();
//   }
//
//   void resume() {
//     _isPaused = false;
//
//     if (_webSocketChannel == null &&
//         _socketUrl != null &&
//         config.preferWebSocket) {
//       _tryWebSocket(_socketUrl!, false);
//     }
//   }
//
//   bool get isPaused => _isPaused;
//
//   bool get isUsingWebSocket => _webSocketChannel != null;
//
//   bool get isUsingPolling => false;
//
//   Future<void> retryWebSocket() async {
//     if (_socketUrl != null && config.preferWebSocket) {
//       _closeCurrentConnection();
//       await _tryWebSocket(_socketUrl!, false);
//     }
//   }
//
//   Stream<List<ActivityWithMetaData>> getMessagesStream({
//     bool cancelOnError = false,
//   }) async* {
//     _streamController =
//         StreamController<List<ActivityWithMetaData>>.broadcast();
//
//     try {
//       _socketUrl = client.capabilities.socket?.endpoint;
//
//       if (_socketUrl != null && config.preferWebSocket) {
//         await _tryWebSocket(_socketUrl!, cancelOnError);
//       }
//
//       yield* _streamController!.stream;
//     } catch (e) {
//       if (cancelOnError) {
//         rethrow;
//       }
//     }
//   }
//
//   Future<void> _tryWebSocket(Uri socketUrl, bool cancelOnError) async {
//     if (_isPaused || _isDisposed) return;
//
//     try {
//       final token = await client.getAuthToken();
//       final headers = token == null ? null : {'Authorization': 'Bearer $token'};
//
//       final channel = IOWebSocketChannel.connect(
//         socketUrl,
//         headers: headers,
//         connectTimeout: const Duration(seconds: 10),
//       );
//
//       _webSocketChannel = channel;
//
//       _websocketSubscription = channel.stream.listen(
//         (data) async {
//           if (_isPaused || _isDisposed) return;
//
//           try {
//             final messages = await _parseWebSocketData(data);
//             _streamController?.add(messages);
//           } catch (e) {
//             if (cancelOnError) {
//               _streamController?.addError(e);
//             }
//           }
//         },
//         onError: (error) async {
//           if (_isDisposed) return;
//
//           _closeWebSocket();
//
//           if (!cancelOnError && !_isPaused) {
//             _scheduleWebSocketReconnect(cancelOnError);
//           } else if (cancelOnError) {
//             _streamController?.addError(error);
//           }
//         },
//         onDone: () async {
//           if (_isDisposed) return;
//
//           _closeWebSocket();
//
//           if (!_isPaused) {
//             _scheduleWebSocketReconnect(cancelOnError);
//           }
//         },
//         cancelOnError: false,
//       );
//
//       if (_isPaused) {
//         _websocketSubscription?.pause();
//       }
//     } catch (e) {
//       _closeWebSocket();
//
//       if (!cancelOnError && !_isPaused && !_isDisposed) {
//         _scheduleWebSocketReconnect(cancelOnError);
//       } else if (cancelOnError) {
//         _streamController?.addError(e);
//       }
//     }
//   }
//
//   void _scheduleWebSocketReconnect(bool cancelOnError) {
//     if (_socketUrl == null || !config.preferWebSocket) return;
//
//     _reconnectTimer?.cancel();
//     _reconnectTimer = Timer(config.websocketReconnectDelay, () {
//       if (!_isDisposed && !_isPaused && _webSocketChannel == null) {
//         _tryWebSocket(_socketUrl!, cancelOnError);
//       }
//     });
//   }
//
//   Future<List<ActivityWithMetaData>> _parseWebSocketData(dynamic data) async {
//     return messageHandler.parseActivities(data);
//   }
//
//   void _closeWebSocket() {
//     _websocketSubscription?.cancel();
//     _websocketSubscription = null;
//     _webSocketChannel?.sink.close();
//     _webSocketChannel = null;
//   }
//
//   void _closeCurrentConnection() {
//     _reconnectTimer?.cancel();
//     _reconnectTimer = null;
//     _closeWebSocket();
//   }
//
//   Stream<List<ActivityWithMetaData>> getMessagesBroadcastStream({
//     bool cancelOnError = false,
//   }) {
//     return getMessagesStream(cancelOnError: cancelOnError).asBroadcastStream();
//   }
//
//   Stream<ActivityWithMetaData> getMessageStream({
//     bool cancelOnError = false,
//   }) async* {
//     await for (final messageList in getMessagesStream(
//       cancelOnError: cancelOnError,
//     )) {
//       for (final message in messageList) {
//         yield message;
//       }
//     }
//   }
//
//   void dispose() {
//     _isDisposed = true;
//     _closeCurrentConnection();
//     _streamController?.close();
//   }
// }
