import 'package:flutter/material.dart';
import 'package:network/network.dart';
import 'package:shared_ui/shared_ui.dart';

import 'session_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<PracticeHistoryResponse> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = widget.api.listPracticeHistory();
  }

  Future<void> _openSession(String sessionId) async {
    try {
      final results = await widget.api.getResults(sessionId);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SessionDetailScreen(results: results),
        ),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load session: $err')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice history')),
      body: FutureBuilder<PracticeHistoryResponse>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final history = snapshot.data!;
          if (history.items.isEmpty) {
            return const Center(
              child: Text('No practice sessions yet.\nComplete a lesson to see history here.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: history.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = history.items[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(item.contentType[0].toUpperCase()),
                  ),
                  title: Text(item.contentTitle),
                  subtitle: Text('${item.contentType} · ${item.instrumentId}'),
                  trailing: item.overallScore != null
                      ? ScoreChip(label: 'Score', value: item.overallScore!)
                      : const Chip(label: Text('Pending')),
                  onTap: item.overallScore != null
                      ? () => _openSession(item.sessionId)
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
