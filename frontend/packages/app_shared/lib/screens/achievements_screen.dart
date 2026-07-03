import 'package:flutter/material.dart';
import 'package:network/network.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late Future<List<Achievement>> _achievementsFuture;

  @override
  void initState() {
    super.initState();
    _achievementsFuture = widget.api.getAchievements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: FutureBuilder<List<Achievement>>(
        future: _achievementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final achievements = snapshot.data ?? [];
          if (achievements.isEmpty) {
            return const Center(child: Text('No achievements yet.'));
          }

          final unlocked = achievements.where((a) => a.unlocked).length;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                '$unlocked / ${achievements.length} unlocked',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ...achievements.map(
                (achievement) => Card(
                  child: ListTile(
                    leading: Icon(
                      achievement.unlocked ? Icons.emoji_events : Icons.lock_outline,
                      color: achievement.unlocked
                          ? Colors.amber.shade700
                          : Theme.of(context).disabledColor,
                    ),
                    title: Text(achievement.title),
                    subtitle: Text(achievement.description),
                    trailing: achievement.unlocked
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
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
