import 'package:flutter/material.dart';
import 'package:network/network.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<LeaderboardResponse> _leaderboardFuture;
  String? _instrumentFilter;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  void _loadLeaderboard() {
    _leaderboardFuture = widget.api.getLeaderboard(
      instrument: _instrumentFilter,
      limit: 20,
    );
  }

  void _setFilter(String? instrument) {
    setState(() {
      _instrumentFilter = instrument;
      _loadLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _instrumentFilter == null,
                  onSelected: (_) => _setFilter(null),
                ),
                const SizedBox(width: 8),
                for (final instrument in ['guitar', 'piano', 'violin', 'drums'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(instrument),
                      selected: _instrumentFilter == instrument,
                      onSelected: (_) => _setFilter(instrument),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<LeaderboardResponse>(
              future: _leaderboardFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final leaderboard = snapshot.data!;
                if (leaderboard.items.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No ranked sessions yet.\nComplete a practice session to appear on the board.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (leaderboard.currentUserRank != null)
                      Card(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text('Your rank: #${leaderboard.currentUserRank}'),
                          subtitle: const Text('Based on average session score'),
                        ),
                      ),
                    const SizedBox(height: 8),
                    ...leaderboard.items.map(
                      (entry) => Card(
                        color: entry.isCurrentUser
                            ? Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5)
                            : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('#${entry.rank}'),
                          ),
                          title: Text(entry.displayName),
                          subtitle: Text('${entry.sessionCount} sessions'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                entry.averageScore.toStringAsFixed(1),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'best ${entry.bestScore.toStringAsFixed(1)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
