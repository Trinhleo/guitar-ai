import 'package:flutter/material.dart';
import 'package:network/network.dart';
import 'package:shared_ui/shared_ui.dart';

class SessionDetailScreen extends StatelessWidget {
  const SessionDetailScreen({
    super.key,
    required this.results,
  });

  final PracticeResults results;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(results.contentTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '${results.contentType} · ${results.createdAt ?? ''}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (results.pitchAccuracy != null && results.timingAccuracy != null)
            PitchMeter(
              pitchAccuracy: results.pitchAccuracy!,
              timingAccuracy: results.timingAccuracy,
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (results.overallScore != null)
                ScoreChip(label: 'Overall', value: results.overallScore!),
              if (results.pitchAccuracy != null)
                ScoreChip(label: 'Pitch', value: results.pitchAccuracy!),
              if (results.timingAccuracy != null)
                ScoreChip(label: 'Timing', value: results.timingAccuracy!),
              if (results.techniqueScore != null)
                ScoreChip(label: 'Technique', value: results.techniqueScore!),
            ],
          ),
          if (results.techniqueHints.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Technique tips', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...results.techniqueHints.map(
              (hint) => Card(
                child: ListTile(
                  leading: Icon(
                    hint.severity == 'warning' ? Icons.warning_amber : Icons.lightbulb_outline,
                    color: hint.severity == 'warning' ? Colors.orange : null,
                  ),
                  title: Text(hint.message),
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          Text('Expected notes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (results.expectedNotes.isEmpty)
            const Text('No expected notes recorded.')
          else
            ...results.expectedNotes.map(
              (note) => ListTile(
                dense: true,
                leading: const Icon(Icons.music_note, size: 20),
                title: Text(note.note),
                subtitle: Text('${note.startMs}ms · ${note.durationMs}ms'),
              ),
            ),
          const SizedBox(height: 24),
          Text('Played notes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (results.playedNotes.isEmpty)
            const Text('No played notes stored for this session.')
          else
            ...results.playedNotes.map(
              (note) => ListTile(
                dense: true,
                leading: Icon(
                  _matchesExpected(note, results.expectedNotes)
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  size: 20,
                  color: _matchesExpected(note, results.expectedNotes)
                      ? Colors.green
                      : null,
                ),
                title: Text(note.note),
                subtitle: Text('${note.startMs}ms · ${note.durationMs}ms'),
              ),
            ),
        ],
      ),
    );
  }

  bool _matchesExpected(PracticeNote played, List<PracticeNote> expected) {
    return expected.any((note) => note.note == played.note);
  }
}
