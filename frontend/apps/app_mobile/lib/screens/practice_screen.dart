import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:network/network.dart';
import 'package:record/record.dart';
import 'package:shared_ui/shared_ui.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    required this.api,
    required this.content,
  });

  final ApiClient api;
  final MusicalContent content;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _recorder = AudioRecorder();
  PracticeWebSocket? _socket;
  String? _sessionId;
  bool _loading = false;
  bool _recording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String? _error;
  EvaluationScores? _scores;
  LiveFeedback? _liveFeedback;
  StreamSubscription<LiveFeedback>? _feedbackSub;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    setState(() => _loading = true);
    try {
      final sessionId = await widget.api.startPractice(
        contentId: widget.content.id,
        instrumentId: widget.content.instrumentId,
      );
      final socket = PracticeWebSocket(
        baseUrl: widget.api.baseUrl,
        sessionId: sessionId,
        token: widget.api.token ?? '',
      );
      await socket.connect();
      _feedbackSub = socket.feedback.listen((feedback) {
        if (mounted) setState(() => _liveFeedback = feedback);
      });

      setState(() {
        _sessionId = sessionId;
        _socket = socket;
      });
    } catch (err) {
      setState(() => _error = err.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _feedbackSub?.cancel();
    _socket?.close();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _submitPerfectPractice() async {
    if (_sessionId == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _scores = null;
    });

    try {
      for (final note in widget.content.expectedNotes) {
        _socket?.sendNote(note);
      }
      final scores = await widget.api.evaluatePractice(
        sessionId: _sessionId!,
        playedNotes: widget.content.expectedNotes,
      );
      setState(() => _scores = scores);
    } catch (err) {
      setState(() => _error = err.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      final path = await _recorder.stop();
      _recordTimer?.cancel();
      setState(() {
        _recording = false;
        _recordSeconds = 0;
      });
      if (path != null && _sessionId != null) {
        await _uploadRecording(path);
      }
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      setState(() => _error = 'Microphone permission denied');
      return;
    }

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav),
      path: 'practice_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordSeconds += 1);
    });
    setState(() {
      _recording = true;
      _error = null;
    });
  }

  Future<void> _uploadRecording(String path) async {
    if (_sessionId == null) return;
    setState(() => _loading = true);
    try {
      final bytes = await XFile(path).readAsBytes();
      final result = await widget.api.uploadPracticeAudio(
        sessionId: _sessionId!,
        wavBytes: bytes,
        filename: 'recording.wav',
      );
      final scoresJson = result['scores'] as Map<String, dynamic>;
      setState(() => _scores = EvaluationScores.fromJson(scoresJson));
    } catch (err) {
      setState(() => _error = err.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.content.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_liveFeedback != null) ...[
              Text('Live feedback', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_liveFeedback!.message),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ScoreChip(label: 'Live', value: _liveFeedback!.partialScore),
                  ScoreChip(label: 'Pitch', value: _liveFeedback!.pitchAccuracy),
                  ScoreChip(
                    label: 'Matched',
                    value: _liveFeedback!.totalNotes == 0
                        ? 0
                        : (_liveFeedback!.matchedNotes / _liveFeedback!.totalNotes) * 100,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Text('Expected notes', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: widget.content.expectedNotes.length,
                itemBuilder: (context, index) {
                  final note = widget.content.expectedNotes[index];
                  return ListTile(
                    leading: Text('${index + 1}'),
                    title: Text(note.note),
                    subtitle: Text('Start ${note.startMs}ms · Duration ${note.durationMs}ms'),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: _sessionId == null
                          ? null
                          : () => _socket?.sendNote(note),
                    ),
                  );
                },
              ),
            ),
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 12),
            ],
            if (_scores != null) ...[
              Text('Results', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ScoreChip(label: 'Overall', value: _scores!.overallScore),
                  ScoreChip(label: 'Pitch', value: _scores!.pitchAccuracy),
                  ScoreChip(label: 'Timing', value: _scores!.timingAccuracy),
                  ScoreChip(label: 'Technique', value: _scores!.techniqueScore),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading || _sessionId == null ? null : _toggleRecording,
                    icon: Icon(_recording ? Icons.stop : Icons.mic),
                    label: Text(_recording ? 'Stop ($_recordSeconds s)' : 'Record'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _loading || _sessionId == null ? null : _submitPerfectPractice,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
