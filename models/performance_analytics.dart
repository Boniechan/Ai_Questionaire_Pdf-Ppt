class SubjectPerformance {
  final String subject;
  final int totalQuestions;
  final int correctAnswers;
  final double percentage;
  final int quizzesTaken;
  final DateTime lastActivity;

  SubjectPerformance({
    required this.subject,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.percentage,
    required this.quizzesTaken,
    required this.lastActivity,
  });

  bool get isStrength => percentage >= 70.0;
  bool get isWeakness => percentage < 70.0;

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'percentage': percentage,
      'quizzesTaken': quizzesTaken,
      'lastActivity': lastActivity.millisecondsSinceEpoch,
    };
  }

  factory SubjectPerformance.fromJson(Map<String, dynamic> json) {
    return SubjectPerformance(
      subject: json['subject'],
      totalQuestions: json['totalQuestions'],
      correctAnswers: json['correctAnswers'],
      percentage: json['percentage'].toDouble(),
      quizzesTaken: json['quizzesTaken'],
      lastActivity: DateTime.fromMillisecondsSinceEpoch(json['lastActivity']),
    );
  }
}

class PerformanceAnalytics {
  final String userId;
  final List<SubjectPerformance> subjectPerformances;
  final int totalQuizzes;
  final int totalQuestions;
  final int totalCorrectAnswers;
  final double overallPercentage;
  final Duration totalStudyTime;
  final DateTime lastUpdated;

  PerformanceAnalytics({
    required this.userId,
    required this.subjectPerformances,
    required this.totalQuizzes,
    required this.totalQuestions,
    required this.totalCorrectAnswers,
    required this.overallPercentage,
    required this.totalStudyTime,
    required this.lastUpdated,
  });

  List<SubjectPerformance> get strengths =>
      subjectPerformances.where((sp) => sp.isStrength).toList();

  List<SubjectPerformance> get weaknesses =>
      subjectPerformances.where((sp) => sp.isWeakness).toList();

  SubjectPerformance? getSubjectPerformance(String subject) {
    try {
      return subjectPerformances.firstWhere((sp) => sp.subject == subject);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'subjectPerformances': subjectPerformances
          .map((sp) => sp.toJson())
          .toList(),
      'totalQuizzes': totalQuizzes,
      'totalQuestions': totalQuestions,
      'totalCorrectAnswers': totalCorrectAnswers,
      'overallPercentage': overallPercentage,
      'totalStudyTime': totalStudyTime.inMilliseconds,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  factory PerformanceAnalytics.fromJson(Map<String, dynamic> json) {
    return PerformanceAnalytics(
      userId: json['userId'],
      subjectPerformances:
          (json['subjectPerformances'] as List<dynamic>?)
              ?.map(
                (sp) => SubjectPerformance.fromJson(sp as Map<String, dynamic>),
              )
              .toList() ??
          [],
      totalQuizzes: json['totalQuizzes'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      totalCorrectAnswers: json['totalCorrectAnswers'] ?? 0,
      overallPercentage: (json['overallPercentage'] ?? 0.0).toDouble(),
      totalStudyTime: Duration(milliseconds: json['totalStudyTime'] ?? 0),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        json['lastUpdated'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  PerformanceAnalytics copyWith({
    String? userId,
    List<SubjectPerformance>? subjectPerformances,
    int? totalQuizzes,
    int? totalQuestions,
    int? totalCorrectAnswers,
    double? overallPercentage,
    Duration? totalStudyTime,
    DateTime? lastUpdated,
  }) {
    return PerformanceAnalytics(
      userId: userId ?? this.userId,
      subjectPerformances: subjectPerformances ?? this.subjectPerformances,
      totalQuizzes: totalQuizzes ?? this.totalQuizzes,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      totalCorrectAnswers: totalCorrectAnswers ?? this.totalCorrectAnswers,
      overallPercentage: overallPercentage ?? this.overallPercentage,
      totalStudyTime: totalStudyTime ?? this.totalStudyTime,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
