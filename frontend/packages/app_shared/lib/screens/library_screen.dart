import 'package:flutter/material.dart';
import 'package:network/network.dart';

import 'practice_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.api,
    required this.instrument,
  });

  final ApiClient api;
  final Instrument instrument;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late Future<List<MusicalContent>> _contentFuture;
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  void _loadContent() {
    _contentFuture = widget.api.listContent(
      instrument: widget.instrument.id,
      type: _typeFilter,
    );
  }

  void _setTypeFilter(String? type) {
    setState(() {
      _typeFilter = type;
      _loadContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.instrument.name} Library'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _typeFilter == null,
                  onSelected: (_) => _setTypeFilter(null),
                ),
                FilterChip(
                  label: const Text('Lessons'),
                  selected: _typeFilter == 'lesson',
                  onSelected: (_) => _setTypeFilter('lesson'),
                ),
                FilterChip(
                  label: const Text('Solos'),
                  selected: _typeFilter == 'solo',
                  onSelected: (_) => _setTypeFilter('solo'),
                ),
                FilterChip(
                  label: const Text('Chords'),
                  selected: _typeFilter == 'chord',
                  onSelected: (_) => _setTypeFilter('chord'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<MusicalContent>>(
              future: _contentFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final content = snapshot.data ?? [];
                if (content.isEmpty) {
                  return const Center(child: Text('No lessons available yet.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: content.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final lesson = content[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${lesson.difficultyLevel}'),
                        ),
                        title: Text(lesson.title),
                        subtitle: Text('Type: ${lesson.type}'),
                        trailing: const Icon(Icons.play_arrow),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PracticeScreen(
                                api: widget.api,
                                content: lesson,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
