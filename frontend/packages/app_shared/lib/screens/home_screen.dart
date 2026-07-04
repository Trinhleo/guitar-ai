import 'package:flutter/material.dart';
import 'package:network/network.dart';

import '../services/auth_store.dart';
import 'achievements_screen.dart';
import 'history_screen.dart';
import 'leaderboard_screen.dart';
import 'library_screen.dart';
import 'practice_screen.dart';
import 'progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.api,
    required this.auth,
    required this.onLogout,
  });

  final ApiClient api;
  final AuthStore auth;
  final Future<void> Function() onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Instrument>> _instrumentsFuture;
  late Future<List<Recommendation>> _recommendationsFuture;
  String _recommendationInstrument = 'guitar';

  @override
  void initState() {
    super.initState();
    _instrumentsFuture = widget.api.listInstruments();
    _loadRecommendations();
  }

  void _loadRecommendations() {
    _recommendationsFuture = widget.api.getRecommendations(
      instrument: _recommendationInstrument,
    );
  }

  void _setRecommendationInstrument(String instrumentId) {
    setState(() {
      _recommendationInstrument = instrumentId;
      _loadRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music AI Tutor'),
        actions: [
          IconButton(
            tooltip: 'Leaderboard',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LeaderboardScreen(api: widget.api),
                ),
              );
            },
            icon: const Icon(Icons.leaderboard),
          ),
          IconButton(
            tooltip: 'Achievements',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AchievementsScreen(api: widget.api),
                ),
              );
            },
            icon: const Icon(Icons.emoji_events),
          ),
          IconButton(
            tooltip: 'Progress',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProgressScreen(api: widget.api),
                ),
              );
            },
            icon: const Icon(Icons.insights),
          ),
          IconButton(
            tooltip: 'History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HistoryScreen(api: widget.api),
                ),
              );
            },
            icon: const Icon(Icons.history),
          ),
          if (widget.auth.email != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.auth.email!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<List<Instrument>>(
        future: _instrumentsFuture,
        builder: (context, instrumentsSnapshot) {
          if (instrumentsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (instrumentsSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not reach API at ${widget.api.baseUrl}\n\n${instrumentsSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final instruments = instrumentsSnapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Recommended for you', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: instruments.map((instrument) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(instrument.name),
                        selected: _recommendationInstrument == instrument.id,
                        onSelected: (_) => _setRecommendationInstrument(instrument.id),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Recommendation>>(
                future: _recommendationsFuture,
                builder: (context, recSnapshot) {
                  if (recSnapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (recSnapshot.hasError) {
                    return Text('Could not load recommendations: ${recSnapshot.error}');
                  }

                  final recommendations = recSnapshot.data ?? [];
                  if (recommendations.isEmpty) {
                    return const Text('No recommendations yet — complete a session first.');
                  }

                  return Column(
                    children: recommendations.map(
                      (rec) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.recommend),
                          title: Text(rec.content.title),
                          subtitle: Text(
                            '${rec.content.type} · level ${rec.content.difficultyLevel}\n${rec.reason}',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.play_arrow),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PracticeScreen(
                                  api: widget.api,
                                  content: rec.content,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('Choose an instrument', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...instruments.map(
                (instrument) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(instrument.name),
                      subtitle: Text(instrument.family),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LibraryScreen(
                              api: widget.api,
                              instrument: instrument,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
