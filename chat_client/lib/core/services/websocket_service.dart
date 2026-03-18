import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';

enum WebSocketStatus { disconnected, connecting, connected, error }

class WebSocketMessage {
  final String event;
  final dynamic data;

  WebSocketMessage({required this.event, this.data});

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      event: json['event'] as String,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() => {'event': event, 'data': data};
}

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});

class WebSocketService {
  WebSocketChannel? _channel;
  final _messageController = StreamController<WebSocketMessage>.broadcast();
  final _statusController = StreamController<WebSocketStatus>.broadcast();
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  String? _authToken;
  bool _shouldReconnect = true;

  Stream<WebSocketMessage> get messageStream => _messageController.stream;
  Stream<WebSocketStatus> get statusStream => _statusController.stream;
  WebSocketStatus _status = WebSocketStatus.disconnected;
  WebSocketStatus get status => _status;

  void connect(String authToken) {
    _authToken = authToken;
    _shouldReconnect = true;
    _doConnect();
  }

  void _doConnect() {
    if (_authToken == null) return;

    _updateStatus(WebSocketStatus.connecting);

    try {
      final uri = Uri.parse('${AppConfig.wsUrl}?token=$_authToken');
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _updateStatus(WebSocketStatus.connected);
      _startPingTimer();
    } catch (e) {
      _updateStatus(WebSocketStatus.error);
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final wsMessage = WebSocketMessage.fromJson(data);
      _messageController.add(wsMessage);
    } catch (e) {
      // Handle parse error
    }
  }

  void _onError(Object error) {
    _updateStatus(WebSocketStatus.error);
    _scheduleReconnect();
  }

  void _onDone() {
    _updateStatus(WebSocketStatus.disconnected);
    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(AppConfig.wsReconnectDelay, () {
      if (_shouldReconnect) {
        _doConnect();
      }
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      sendPing();
    });
  }

  void _updateStatus(WebSocketStatus status) {
    _status = status;
    _statusController.add(status);
  }

  void send(String event, dynamic data) {
    if (_channel != null && _status == WebSocketStatus.connected) {
      final message = jsonEncode({'event': event, 'data': data});
      _channel!.sink.add(message);
    }
  }

  void sendPing() {
    send('ping', {'timestamp': DateTime.now().toIso8601String()});
  }

  // Auth events
  void sendAuth() {
    if (_authToken != null) {
      send('auth', {'token': _authToken});
    }
  }

  // Message events
  void sendTyping(String chatId, String type) {
    send('typing', {'chat_id': chatId, 'type': type});
  }

  void sendStopTyping(String chatId, String type) {
    send('stop_typing', {'chat_id': chatId, 'type': type});
  }

  void sendMessage(dynamic messageData) {
    send('message', messageData);
  }

  void sendReadReceipt(String messageId) {
    send('read', {'message_id': messageId});
  }

  void sendRecallMessage(String messageId) {
    send('recall', {'message_id': messageId});
  }

  // Call events
  void sendCallOffer(String callId, String calleeId, dynamic offer) {
    send('call_offer', {
      'call_id': callId,
      'callee_id': calleeId,
      'offer': offer,
    });
  }

  void sendCallAnswer(String callId, String callerId, dynamic answer) {
    send('call_answer', {
      'call_id': callId,
      'caller_id': callerId,
      'answer': answer,
    });
  }

  void sendCallIceCandidate(String callId, String targetUserId, dynamic candidate) {
    send('call_ice', {
      'call_id': callId,
      'target_user_id': targetUserId,
      'candidate': candidate,
    });
  }

  void sendCallEnd(String callId, String targetUserId) {
    send('call_end', {
      'call_id': callId,
      'target_user_id': targetUserId,
    });
  }

  void sendCallAccepted(String callId) {
    send('call_accepted', {'call_id': callId});
  }

  void sendCallRejected(String callId) {
    send('call_rejected', {'call_id': callId});
  }

  // Presence events
  void sendOnlineStatus() {
    send('online', {'timestamp': DateTime.now().toIso8601String()});
  }

  void sendOfflineStatus() {
    send('offline', {'timestamp': DateTime.now().toIso8601String()});
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _updateStatus(WebSocketStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
  }
}
