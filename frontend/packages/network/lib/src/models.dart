class AuthResponse {
  AuthResponse({
    required this.token,
    required this.userId,
    required this.email,
  });

  final String token;
  final String userId;
  final String email;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      userId: json['userId'] as String,
      email: json['email'] as String,
    );
  }
}

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

class PracticeHistoryItem {
  PracticeHistoryItem({
    required this.sessionId,
    required this.contentTitle,
    required this.contentType,
    required this.instrumentId,
    required this.overallScore,
    required this.createdAt,
  });

  final String sessionId;
  final String contentTitle;
  final String contentType;
  final String instrumentId;
  final double? overallScore;
  final String createdAt;

  factory PracticeHistoryItem.fromJson(Map<String, dynamic> json) {
    return PracticeHistoryItem(
      sessionId: json['sessionId'] as String,
      contentTitle: json['contentTitle'] as String,
      contentType: json['contentType'] as String,
      instrumentId: json['instrumentId'] as String,
      overallScore: (json['overallScore'] as num?)?.toDouble(),
      createdAt: json['createdAt'] as String,
    );
  }
}

class PracticeHistoryResponse {
  PracticeHistoryResponse({
    required this.items,
    required this.total,
  });

  final List<PracticeHistoryItem> items;
  final int total;

  factory PracticeHistoryResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((item) => PracticeHistoryItem.fromJson(item as Map<String, dynamic>))
        .toList();
    return PracticeHistoryResponse(
      items: items,
      total: json['total'] as int? ?? items.length,
    );
  }
}

class UserProgress {
  UserProgress({
    required this.totalSessions,
    required this.evaluatedCount,
    required this.averageScore,
    required this.bestScore,
    required this.recentScores,
    required this.sessionsByType,
  });

  final int totalSessions;
  final int evaluatedCount;
  final double? averageScore;
  final double? bestScore;
  final List<double> recentScores;
  final Map<String, int> sessionsByType;

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    final recent = (json['recentScores'] as List<dynamic>? ?? [])
        .map((v) => (v as num).toDouble())
        .toList();
    final byTypeRaw = json['sessionsByType'] as Map<String, dynamic>? ?? {};
    final byType = <String, int>{};
    byTypeRaw.forEach((key, value) {
      byType[key] = value as int;
    });

    return UserProgress(
      totalSessions: json['totalSessions'] as int? ?? 0,
      evaluatedCount: json['evaluatedCount'] as int? ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble(),
      bestScore: (json['bestScore'] as num?)?.toDouble(),
      recentScores: recent,
      sessionsByType: byType,
    );
  }
}

class Achievement {
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
  });

  final String id;
  final String title;
  final String description;
  final bool unlocked;

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      unlocked: json['unlocked'] as bool? ?? false,
    );
  }
}
