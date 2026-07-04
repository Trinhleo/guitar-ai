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
    this.techniqueHints = const [],
  });

  final double overallScore;
  final double pitchAccuracy;
  final double timingAccuracy;
  final double techniqueScore;
  final List<TechniqueHint> techniqueHints;

  factory EvaluationScores.fromJson(Map<String, dynamic> json) {
    final hints = (json['techniqueHints'] as List<dynamic>? ?? [])
        .map((item) => TechniqueHint.fromJson(item as Map<String, dynamic>))
        .toList();
    return EvaluationScores(
      overallScore: (json['overallScore'] as num).toDouble(),
      pitchAccuracy: (json['pitchAccuracy'] as num).toDouble(),
      timingAccuracy: (json['timingAccuracy'] as num).toDouble(),
      techniqueScore: (json['techniqueScore'] as num).toDouble(),
      techniqueHints: hints,
    );
  }
}

class TechniqueHint {
  TechniqueHint({
    required this.code,
    required this.message,
    required this.severity,
  });

  final String code;
  final String message;
  final String severity;

  factory TechniqueHint.fromJson(Map<String, dynamic> json) {
    return TechniqueHint(
      code: json['code'] as String,
      message: json['message'] as String,
      severity: json['severity'] as String? ?? 'info',
    );
  }
}

class PracticeResults {
  PracticeResults({
    required this.contentTitle,
    required this.contentType,
    required this.overallScore,
    required this.pitchAccuracy,
    required this.timingAccuracy,
    required this.techniqueScore,
    required this.expectedNotes,
    required this.playedNotes,
    required this.techniqueHints,
    required this.createdAt,
  });

  final String contentTitle;
  final String contentType;
  final double? overallScore;
  final double? pitchAccuracy;
  final double? timingAccuracy;
  final double? techniqueScore;
  final List<PracticeNote> expectedNotes;
  final List<PracticeNote> playedNotes;
  final List<TechniqueHint> techniqueHints;
  final String? createdAt;

  factory PracticeResults.fromJson(Map<String, dynamic> json) {
    final metrics = json['metrics'] as Map<String, dynamic>?;
    final session = json['session'] as Map<String, dynamic>?;
    final expected = (json['expectedNotes'] as List<dynamic>? ?? [])
        .map((item) => PracticeNote.fromJson(item as Map<String, dynamic>))
        .toList();
    final played = (json['playedNotes'] as List<dynamic>? ?? [])
        .map((item) => PracticeNote.fromJson(item as Map<String, dynamic>))
        .toList();
    final hints = (json['techniqueHints'] as List<dynamic>? ?? [])
        .map((item) => TechniqueHint.fromJson(item as Map<String, dynamic>))
        .toList();

    return PracticeResults(
      contentTitle: json['contentTitle'] as String? ?? '',
      contentType: json['contentType'] as String? ?? '',
      overallScore: (session?['overall_score'] as num?)?.toDouble(),
      pitchAccuracy: (metrics?['pitch_accuracy'] as num?)?.toDouble(),
      timingAccuracy: (metrics?['timing_accuracy'] as num?)?.toDouble(),
      techniqueScore: (metrics?['technique_score'] as num?)?.toDouble(),
      expectedNotes: expected,
      playedNotes: played,
      techniqueHints: hints,
      createdAt: session?['created_at'] as String?,
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
    required this.trends,
  });

  final int totalSessions;
  final int evaluatedCount;
  final double? averageScore;
  final double? bestScore;
  final List<double> recentScores;
  final Map<String, int> sessionsByType;
  final List<ProgressTrendPoint> trends;

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    final recent = (json['recentScores'] as List<dynamic>? ?? [])
        .map((v) => (v as num).toDouble())
        .toList();
    final byTypeRaw = json['sessionsByType'] as Map<String, dynamic>? ?? {};
    final byType = <String, int>{};
    byTypeRaw.forEach((key, value) {
      byType[key] = value as int;
    });
    final trends = (json['trends'] as List<dynamic>? ?? [])
        .map((item) => ProgressTrendPoint.fromJson(item as Map<String, dynamic>))
        .toList();

    return UserProgress(
      totalSessions: json['totalSessions'] as int? ?? 0,
      evaluatedCount: json['evaluatedCount'] as int? ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble(),
      bestScore: (json['bestScore'] as num?)?.toDouble(),
      recentScores: recent,
      sessionsByType: byType,
      trends: trends,
    );
  }
}

class ProgressTrendPoint {
  ProgressTrendPoint({
    required this.sessionId,
    required this.createdAt,
    required this.overallScore,
    required this.pitchAccuracy,
    required this.timingAccuracy,
  });

  final String sessionId;
  final String createdAt;
  final double? overallScore;
  final double? pitchAccuracy;
  final double? timingAccuracy;

  factory ProgressTrendPoint.fromJson(Map<String, dynamic> json) {
    return ProgressTrendPoint(
      sessionId: json['sessionId'] as String,
      createdAt: json['createdAt'] as String,
      overallScore: (json['overallScore'] as num?)?.toDouble(),
      pitchAccuracy: (json['pitchAccuracy'] as num?)?.toDouble(),
      timingAccuracy: (json['timingAccuracy'] as num?)?.toDouble(),
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

class Recommendation {
  Recommendation({
    required this.content,
    required this.reason,
  });

  final MusicalContent content;
  final String reason;

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      content: MusicalContent.fromJson(json['content'] as Map<String, dynamic>),
      reason: json['reason'] as String? ?? '',
    );
  }
}

class LeaderboardEntry {
  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.averageScore,
    required this.bestScore,
    required this.sessionCount,
    required this.isCurrentUser,
  });

  final int rank;
  final String userId;
  final String displayName;
  final double averageScore;
  final double bestScore;
  final int sessionCount;
  final bool isCurrentUser;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int? ?? 0,
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0,
      bestScore: (json['bestScore'] as num?)?.toDouble() ?? 0,
      sessionCount: json['sessionCount'] as int? ?? 0,
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }
}

class LeaderboardResponse {
  LeaderboardResponse({
    required this.items,
    this.instrument,
    this.currentUserRank,
  });

  final List<LeaderboardEntry> items;
  final String? instrument;
  final int? currentUserRank;

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((item) => LeaderboardEntry.fromJson(item as Map<String, dynamic>))
        .toList();
    return LeaderboardResponse(
      items: items,
      instrument: json['instrument'] as String?,
      currentUserRank: json['currentUserRank'] as int?,
    );
  }
}

class PracticeInsight {
  PracticeInsight({
    required this.category,
    required this.message,
    required this.severity,
  });

  final String category;
  final String message;
  final String severity;

  factory PracticeInsight.fromJson(Map<String, dynamic> json) {
    return PracticeInsight(
      category: json['category'] as String? ?? '',
      message: json['message'] as String? ?? '',
      severity: json['severity'] as String? ?? 'info',
    );
  }
}

class PracticeInsightsResponse {
  PracticeInsightsResponse({
    this.weakArea,
    this.pitchAverage,
    this.timingAverage,
    required this.practiceStreak,
    required this.sessionsThisWeek,
    this.scoreImprovement,
    this.topInstrument,
    required this.insights,
  });

  final String? weakArea;
  final double? pitchAverage;
  final double? timingAverage;
  final int practiceStreak;
  final int sessionsThisWeek;
  final double? scoreImprovement;
  final String? topInstrument;
  final List<PracticeInsight> insights;

  factory PracticeInsightsResponse.fromJson(Map<String, dynamic> json) {
    final insights = (json['insights'] as List<dynamic>? ?? [])
        .map((item) => PracticeInsight.fromJson(item as Map<String, dynamic>))
        .toList();
    return PracticeInsightsResponse(
      weakArea: json['weakArea'] as String?,
      pitchAverage: (json['pitchAverage'] as num?)?.toDouble(),
      timingAverage: (json['timingAverage'] as num?)?.toDouble(),
      practiceStreak: json['practiceStreak'] as int? ?? 0,
      sessionsThisWeek: json['sessionsThisWeek'] as int? ?? 0,
      scoreImprovement: (json['scoreImprovement'] as num?)?.toDouble(),
      topInstrument: json['topInstrument'] as String?,
      insights: insights,
    );
  }
}
