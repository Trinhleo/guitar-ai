import 'package:flutter/material.dart';
import 'package:network/network.dart';
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
  bool _loading = false;
  String? _error;
  EvaluationScores? _scores;

  Future<void> _submitPractice() async {
    setState(() {
      _loading = true;
      _error = null;
      _scores = null;
    });

    try {
      final sessionId = await widget.api.startPractice(
        contentId: widget.content.id,
        instrumentId: widget.content.instrumentId,
      );
      final scores = await widget.api.evaluatePractice(
        sessionId: sessionId,
        playedNotes: widget.content.expectedNotes,
      );
      setState(() => _scores = scores);
    } catch (err) {
      setState(() => _error = err.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.content.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expected notes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: widget.content.expectedNotes.length,
                itemBuilder: (context, index) {
                  final note = widget.content.expectedNotes[index];
                  return ListTile(
                    leading: Text('${index + 1}'),
                    title: Text(note.note),
                    subtitle: Text(
                      'Start ${note.startMs}ms · Duration ${note.durationMs}ms',
                    ),
                  );
                },
              ),
            ),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            if (_scores != null) ...[
              Text(
                'Results',
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _submitPractice,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_loading ? 'Evaluating...' : 'Submit perfect practice'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
