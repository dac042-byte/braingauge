class NeuroLoadScore {
  final double neuroLoadScore;
  final double speechDriftScore;
  final double cognitiveDriftScore;
  final double visualMotorDriftScore;
  final String status;
  final List<String> insights;
  final int weekNumber;

  NeuroLoadScore({
    required this.neuroLoadScore,
    required this.speechDriftScore,
    required this.cognitiveDriftScore,
    required this.visualMotorDriftScore,
    required this.status,
    required this.insights,
    required this.weekNumber,
  });

  factory NeuroLoadScore.fromJson(Map<String, dynamic> json) {
    return NeuroLoadScore(
      neuroLoadScore: json['neuro_load_score'].toDouble(),
      speechDriftScore: json['speech_drift_score'].toDouble(),
      cognitiveDriftScore: json['cognitive_drift_score'].toDouble(),
      visualMotorDriftScore: json['visual_motor_drift_score'].toDouble(),
      status: json['status'],
      insights: List<String>.from(json['insights']),
      weekNumber: json['week_number'],
    );
  }
}

class TrendData {
  final int week;
  final DateTime date;
  final double neuroLoadScore;
  final double speechDrift;
  final double cognitiveDrift;
  final double visualMotorDrift;

  TrendData({
    required this.week,
    required this.date,
    required this.neuroLoadScore,
    required this.speechDrift,
    required this.cognitiveDrift,
    required this.visualMotorDrift,
  });

  factory TrendData.fromJson(Map<String, dynamic> json) {
    return TrendData(
      week: json['week'],
      date: DateTime.parse(json['date']),
      neuroLoadScore: json['neuro_load_score'].toDouble(),
      speechDrift: json['speech_drift'].toDouble(),
      cognitiveDrift: json['cognitive_drift'].toDouble(),
      visualMotorDrift: json['visual_motor_drift'].toDouble(),
    );
  }
}

class WeeklyAssessment {
  final int id;
  final int userId;
  final int weekNumber;
  final DateTime createdAt;
  final double speechDriftScore;
  final double cognitiveDriftScore;
  final double visualMotorDriftScore;
  final double neuroLoadScore;
  final String comparisonText;

  WeeklyAssessment({
    required this.id,
    required this.userId,
    required this.weekNumber,
    required this.createdAt,
    required this.speechDriftScore,
    required this.cognitiveDriftScore,
    required this.visualMotorDriftScore,
    required this.neuroLoadScore,
    required this.comparisonText,
  });

  factory WeeklyAssessment.fromJson(Map<String, dynamic> json) {
    return WeeklyAssessment(
      id: json['id'],
      userId: json['user_id'],
      weekNumber: json['week_number'],
      createdAt: DateTime.parse(json['created_at']),
      speechDriftScore: json['speech_drift_score'].toDouble(),
      cognitiveDriftScore: json['cognitive_drift_score'].toDouble(),
      visualMotorDriftScore: json['visual_motor_drift_score'].toDouble(),
      neuroLoadScore: json['neuro_load_score'].toDouble(),
      comparisonText: json['comparison_text'],
    );
  }
}
