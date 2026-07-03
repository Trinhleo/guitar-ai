import 'package:flutter/material.dart';
import 'package:network/network.dart';
import 'package:shared_ui/shared_ui.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Future<UserProgress> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = widget.api.getProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your progress')),
      body: FutureBuilder<UserProgress>(
        future: _progressFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final progress = snapshot.data!;
          final pitchTrend = progress.trends
              .where((point) => point.pitchAccuracy != null)
              .map((point) => point.pitchAccuracy!)
              .toList();
          final timingTrend = progress.trends
              .where((point) => point.timingAccuracy != null)
              .map((point) => point.timingAccuracy!)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Overview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(
                    label: 'Sessions',
                    value: '${progress.totalSessions}',
                  ),
                  _StatCard(
                    label: 'Evaluated',
                    value: '${progress.evaluatedCount}',
                  ),
                  if (progress.averageScore != null)
                    _StatCard(
                      label: 'Average',
                      value: progress.averageScore!.toStringAsFixed(1),
                    ),
                  if (progress.bestScore != null)
                    _StatCard(
                      label: 'Best',
                      value: progress.bestScore!.toStringAsFixed(1),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Trends',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ScoreTrendChart(
                label: 'Pitch accuracy over sessions',
                values: pitchTrend,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),
              ScoreTrendChart(
                label: 'Timing accuracy over sessions',
                values: timingTrend,
                color: AppTheme.secondaryColor,
              ),
              const SizedBox(height: 32),
              Text(
                'By content type',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (progress.sessionsByType.isEmpty)
                const Text('No sessions yet.')
              else
                ...progress.sessionsByType.entries.map(
                  (entry) => ListTile(
                    title: Text(entry.key),
                    trailing: Text('${entry.value}'),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Recent scores',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (progress.recentScores.isEmpty)
                const Text('Complete a practice session to see scores.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: progress.recentScores
                      .map((score) => ScoreChip(label: 'Score', value: score))
                      .toList(),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label),
          ],
        ),
      ),
    );
  }
}
