import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'models.dart';

class LiveFeedback {
  LiveFeedback({
    required this.partialScore,
    required this.pitchAccuracy,
    required this.timingAccuracy,
    required this.matchedNotes,
    required this.totalNotes,
    required this.message,
  });

  final double partialScore;
  final double pitchAccuracy;
  final double timingAccuracy;
  final int matchedNotes;
  final int totalNotes;
  final String message;

  factory LiveFeedback.fromJson(Map<String, dynamic> json) {
    return LiveFeedback(
      partialScore: (json['partialScore'] as num).toDouble(),
      pitchAccuracy: (json['pitchAccuracy'] as num).toDouble(),
      timingAccuracy: (json['timingAccuracy'] as num).toDouble(),
      matchedNotes: json['matchedNotes'] as int,
      totalNotes: json['totalNotes'] as int,
      message: json['message'] as String,
    );
  }
}

class PracticeWebSocket {
  PracticeWebSocket({
    required this.baseUrl,
    required this.sessionId,
    required this.token,
    this.maxReconnectAttempts = 5,
  });

  final String baseUrl;
  final String sessionId;
  final String token;
  final int maxReconnectAttempts;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final _feedbackController = StreamController<LiveFeedback>.broadcast();
  bool _closed = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  Stream<LiveFeedback> get feedback => _feedbackController.stream;

  bool get isConnected => _channel != null && !_closed;

  Future<void> connect() async {
    if (_closed) return;

    await _subscription?.cancel();
    await _channel?.sink.close();

    final wsBase =
        baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
    final uri = Uri.parse('$wsBase/ws/practice/$sessionId?token=$token');
    _channel = WebSocketChannel.connect(uri);
    _subscription = _channel!.stream.listen(
      (event) {
        _reconnectAttempts = 0;
        final jsonMap = jsonDecode(event as String) as Map<String, dynamic>;
        if (jsonMap['type'] == 'feedback') {
          _feedbackController.add(LiveFeedback.fromJson(jsonMap));
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _feedbackController.addError(error, stackTrace);
        _scheduleReconnect();
      },
      onDone: _scheduleReconnect,
      cancelOnError: false,
    );
  }

  void _scheduleReconnect() {
    if (_closed || _reconnectAttempts >= maxReconnectAttempts) return;

    _reconnectAttempts++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _reconnectAttempts.clamp(1, 5)), () {
      if (!_closed) {
        connect();
      }
    });
  }

  void sendNote(PracticeNote note) {
    _channel?.sink.add(jsonEncode({
      'type': 'note',
      'note': note.toJson(),
    }));
  }

  Future<void> close() async {
    _closed = true;
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    await _feedbackController.close();
  }
}
