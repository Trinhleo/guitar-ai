import 'package:app_shared/app_shared.dart';
import 'package:flutter/material.dart';
import 'package:network/network.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  runApp(const GuitarAiApp());
}

class GuitarAiApp extends StatefulWidget {
  const GuitarAiApp({super.key});

  @override
  State<GuitarAiApp> createState() => _GuitarAiAppState();
}

class _GuitarAiAppState extends State<GuitarAiApp> {
  late final ApiClient _api;
  late final AuthStore _auth;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _auth = AuthStore(_api);
    _auth.restore().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  void _onAuthenticated() {
    setState(() {});
  }

  Future<void> _onLogout() async {
    await _auth.logout();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guitar AI Tutor',
      theme: AppTheme.light(),
      home: !_ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _auth.isLoggedIn
              ? HomeScreen(
                  api: _api,
                  auth: _auth,
                  onLogout: _onLogout,
                )
              : LoginScreen(
                  auth: _auth,
                  onAuthenticated: _onAuthenticated,
                ),
    );
  }
}
