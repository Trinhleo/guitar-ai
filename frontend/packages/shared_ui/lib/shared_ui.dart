import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color(0xFF6366F1);
  static const secondaryColor = Color(0xFF8B5CF6);
  static const accentColor = Color(0xFFF59E0B);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
    );
  }
}

class ScoreChip extends StatelessWidget {
  const ScoreChip({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: AppTheme.primaryColor,
        child: Text(
          value.round().toString(),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      label: Text('$label: ${value.toStringAsFixed(1)}'),
    );
  }
}

class PitchMeter extends StatelessWidget {
  const PitchMeter({
    super.key,
    required this.pitchAccuracy,
    this.timingAccuracy,
  });

  final double pitchAccuracy;
  final double? timingAccuracy;

  Color _colorForScore(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final pitch = pitchAccuracy.clamp(0, 100) / 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pitch', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pitch,
            minHeight: 10,
            backgroundColor: Colors.grey.shade300,
            color: _colorForScore(pitchAccuracy),
          ),
        ),
        if (timingAccuracy != null) ...[
          const SizedBox(height: 12),
          Text('Timing', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: timingAccuracy!.clamp(0, 100) / 100,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              color: _colorForScore(timingAccuracy!),
            ),
          ),
        ],
      ],
    );
  }
}
