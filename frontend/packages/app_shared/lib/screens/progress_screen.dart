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
  late Future<({UserProgress progress, PracticeInsightsResponse insights})> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<({UserProgress progress, PracticeInsightsResponse insights})> _fetchData() async {
    final results = await Future.wait([
      widget.api.getProgress(),
      widget.api.getPracticeInsights(),
    ]);
    return (
      progress: results[0] as UserProgress,
      insights: results[1] as PracticeInsightsResponse,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your progress')),
      body: FutureBuilder<({UserProgress progress, PracticeInsightsResponse insights})>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final progress = snapshot.data!.progress;
          final insights = snapshot.data!.insights;
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
                'Practice insights',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(
                    label: 'Streak',
                    value: '${insights.practiceStreak} days',
                  ),
                  _StatCard(
                    label: 'This week',
                    value: '${insights.sessionsThisWeek}',
                  ),
                  if (insights.weakArea != null)
                    _StatCard(
                      label: 'Focus area',
                      value: insights.weakArea!,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ...insights.insights.map(
                (insight) => Card(
                  child: ListTile(
                    leading: Icon(
                      insight.severity == 'warning'
                          ? Icons.warning_amber
                          : Icons.lightbulb_outline,
                      color: insight.severity == 'warning'
                          ? Colors.orange
                          : Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(insight.message),
                    subtitle: Text(insight.category),
                  ),
                ),
              ),
              const SizedBox(height: 32),
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
