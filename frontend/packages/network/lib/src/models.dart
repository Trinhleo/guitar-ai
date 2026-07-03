class Instrument {
  Instrument({
    required this.id,
    required this.name,
    required this.family,
  });

  final String id;
  final String name;
  final String family;

  factory Instrument.fromJson(Map<String, dynamic> json) {
    return Instrument(
      id: json['id'] as String,
      name: json['name'] as String,
      family: json['family'] as String,
    );
  }
}

class MusicalContent {
  MusicalContent({
    required this.id,
    required this.type,
    required this.title,
    required this.instrumentId,
    required this.difficultyLevel,
    required this.expectedNotes,
  });

  final String id;
  final String type;
  final String title;
  final String instrumentId;
  final int difficultyLevel;
  final List<PracticeNote> expectedNotes;

  factory MusicalContent.fromJson(Map<String, dynamic> json) {
    final notes = (json['expected_notes'] as List<dynamic>? ?? [])
        .map((item) => PracticeNote.fromJson(item as Map<String, dynamic>))
        .toList();

    return MusicalContent(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      instrumentId: json['instrument_id'] as String,
      difficultyLevel: json['difficulty_level'] as int,
      expectedNotes: notes,
    );
  }
}

class PracticeNote {
  PracticeNote({
    required this.note,
    required this.startMs,
    required this.durationMs,
  });

  final String note;
  final int startMs;
  final int durationMs;

  factory PracticeNote.fromJson(Map<String, dynamic> json) {
    return PracticeNote(
      note: json['note'] as String,
      startMs: json['startMs'] as int,
      durationMs: json['durationMs'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'note': note,
        'startMs': startMs,
        'durationMs': durationMs,
      };
}

class EvaluationScores {
  EvaluationScores({
    required this.overallScore,
    required this.pitchAccuracy,
    required this.timingAccuracy,
    required this.techniqueScore,
  });

  final double overallScore;
  final double pitchAccuracy;
  final double timingAccuracy;
  final double techniqueScore;

  factory EvaluationScores.fromJson(Map<String, dynamic> json) {
    return EvaluationScores(
      overallScore: (json['overallScore'] as num).toDouble(),
      pitchAccuracy: (json['pitchAccuracy'] as num).toDouble(),
      timingAccuracy: (json['timingAccuracy'] as num).toDouble(),
      techniqueScore: (json['techniqueScore'] as num).toDouble(),
    );
  }
}

class PracticeResults {
  PracticeResults({
    required this.overallScore,
    required this.pitchAccuracy,
    required this.timingAccuracy,
  });

  final double? overallScore;
  final double? pitchAccuracy;
  final double? timingAccuracy;

  factory PracticeResults.fromJson(Map<String, dynamic> json) {
    final metrics = json['metrics'] as Map<String, dynamic>?;
    final session = json['session'] as Map<String, dynamic>?;
    return PracticeResults(
      overallScore: (session?['overall_score'] as num?)?.toDouble(),
      pitchAccuracy: (metrics?['pitch_accuracy'] as num?)?.toDouble(),
      timingAccuracy: (metrics?['timing_accuracy'] as num?)?.toDouble(),
    );
  }
}
