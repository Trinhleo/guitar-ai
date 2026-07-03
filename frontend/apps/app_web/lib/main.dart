import 'package:flutter/material.dart';
import 'package:network/network.dart';
import 'package:shared_ui/shared_ui.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const GuitarAiApp());
}

class GuitarAiApp extends StatelessWidget {
  const GuitarAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guitar AI Tutor',
      theme: AppTheme.light(),
      home: HomeScreen(api: ApiClient()),
    );
  }
}
