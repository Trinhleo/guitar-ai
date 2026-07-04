import 'package:flutter/material.dart';
import 'package:network/network.dart';

import '../services/auth_store.dart';
import 'achievements_screen.dart';
import 'history_screen.dart';
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
  late Future<({List<Instrument> instruments, List<Recommendation> recommendations})> _homeFuture;

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  void _loadHome() {
    _homeFuture = _fetchHome();
  }

  Future<({List<Instrument> instruments, List<Recommendation> recommendations})> _fetchHome() async {
    final results = await Future.wait([
      widget.api.listInstruments(),
      widget.api.getRecommendations(),
    ]);
    return (
      instruments: results[0] as List<Instrument>,
      recommendations: results[1] as List<Recommendation>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guitar AI Tutor'),
        actions: [
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
      body: FutureBuilder<({List<Instrument> instruments, List<Recommendation> recommendations})>(
        future: _homeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not reach API at ${widget.api.baseUrl}\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (data.recommendations.isNotEmpty) ...[
                Text('Recommended for you', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ...data.recommendations.map(
                  (rec) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.recommend),
                      title: Text(rec.content.title),
                      subtitle: Text('${rec.content.type} · level ${rec.content.difficultyLevel}\n${rec.reason}'),
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
                ),
                const SizedBox(height: 24),
              ],
              Text('Choose an instrument', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...data.instruments.map(
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
