import 'package:flutter/material.dart';
import 'package:network/network.dart';

import '../services/auth_store.dart';
import 'library_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _instrumentsFuture = widget.api.listInstruments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guitar AI Tutor'),
        actions: [
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

          final instruments = snapshot.data ?? [];
          if (instruments.isEmpty) {
            return const Center(child: Text('No instruments found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: instruments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final instrument = instruments[index];
              return Card(
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
              );
            },
          );
        },
      ),
    );
  }
}
