class LearningAnalysis {
  const LearningAnalysis({
    required this.hasEnoughData,
    required this.message,
    required this.childId,
    required this.totalLessons,
    required this.completedLessons,
    required this.completionRate,
    required this.totalAnswers,
    required this.correctAnswers,
    required this.correctRate,
    required this.activeDays,
    required this.summary,
    required this.skills,
    required this.recommendations,
    required this.parentAdvice,
    required this.narrativeSource,
    this.reportId,
  });

  factory LearningAnalysis.fromJson(Map<String, dynamic> json) {
    return LearningAnalysis(
      hasEnoughData: json['hasEnoughData'] == true,
      message: _string(json['message']),
      reportId: _nullableInt(json['reportId']),
      childId: _int(json['childId']),
      totalLessons: _int(json['totalLessons']),
      completedLessons: _int(json['completedLessons']),
      completionRate: _double(json['completionRate']),
      totalAnswers: _int(json['totalAnswers']),
      correctAnswers: _int(json['correctAnswers']),
      correctRate: _double(json['correctRate']),
      activeDays: _int(json['activeDays']),
      summary: _string(json['summary']),
      skills: _list(json['skills'], LearningSkillAssessment.fromJson),
      recommendations: _list(
        json['recommendations'],
        LearningRecommendation.fromJson,
      ),
      parentAdvice: (json['parentAdvice'] as List<dynamic>? ?? const [])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      narrativeSource: _string(json['narrativeSource']),
    );
  }

  final bool hasEnoughData;
  final String message;
  final int? reportId;
  final int childId;
  final int totalLessons;
  final int completedLessons;
  final double completionRate;
  final int totalAnswers;
  final int correctAnswers;
  final double correctRate;
  final int activeDays;
  final String summary;
  final List<LearningSkillAssessment> skills;
  final List<LearningRecommendation> recommendations;
  final List<String> parentAdvice;
  final String narrativeSource;
}

class LearningSkillAssessment {
  const LearningSkillAssessment({
    required this.skillId,
    required this.skillName,
    required this.totalAttempts,
    required this.correctAttempts,
    required this.correctRate,
    required this.masteryLevel,
  });

  factory LearningSkillAssessment.fromJson(Map<String, dynamic> json) {
    return LearningSkillAssessment(
      skillId: _int(json['skillId']),
      skillName: _string(json['skillName']),
      totalAttempts: _int(json['totalAttempts']),
      correctAttempts: _int(json['correctAttempts']),
      correctRate: _double(json['correctRate']),
      masteryLevel: _string(json['masteryLevel']),
    );
  }

  final int skillId;
  final String skillName;
  final int totalAttempts;
  final int correctAttempts;
  final double correctRate;
  final String masteryLevel;
}

class LearningRecommendation {
  const LearningRecommendation({
    required this.recommendationId,
    required this.situationId,
    required this.situationTitle,
    required this.recommendationType,
    required this.reason,
    required this.priority,
  });

  factory LearningRecommendation.fromJson(Map<String, dynamic> json) {
    return LearningRecommendation(
      recommendationId: _int(json['recommendationId']),
      situationId: _int(json['situationId']),
      situationTitle: _string(json['situationTitle']),
      recommendationType: _string(json['recommendationType']),
      reason: _string(json['reason']),
      priority: _int(json['priority']),
    );
  }

  final int recommendationId;
  final int situationId;
  final String situationTitle;
  final String recommendationType;
  final String reason;
  final int priority;
}

List<T> _list<T>(Object? value, T Function(Map<String, dynamic>) parse) {
  if (value is! List) {
    return const [];
  }
  return value
      .whereType<Map<String, dynamic>>()
      .map(parse)
      .toList(growable: false);
}

String _string(Object? value) => value?.toString().trim() ?? '';

int _int(Object? value) => _nullableInt(value) ?? 0;

int? _nullableInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
