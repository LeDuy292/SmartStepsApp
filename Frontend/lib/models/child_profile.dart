class ChildProfile {
  const ChildProfile({
    required this.childName,
    required this.age,
    required this.gender,
    required this.learningGoals,
    required this.acceptedTerms,
    required this.completedAt,
    this.avatarStoragePath,
    this.skillProgress = const [],
    this.isPremium = false,
    this.premiumCode,
    this.premiumActivatedAt,
  });

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      childName: _readString(json['childName']),
      age: _readString(json['age']),
      gender: _readString(json['gender']),
      learningGoals: _readStringList(json['learningGoals']),
      acceptedTerms: json['acceptedTerms'] == true,
      completedAt:
          DateTime.tryParse(_readString(json['completedAt'])) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      avatarStoragePath: _readNullableString(json['avatarStoragePath']),
      skillProgress: _readSkillProgressList(json['skillProgress']),
      isPremium: json['isPremium'] == true,
      premiumCode: _readNullableString(json['premiumCode']),
      premiumActivatedAt: DateTime.tryParse(
        _readString(json['premiumActivatedAt']),
      ),
    );
  }

  final String childName;
  final String age;
  final String gender;
  final List<String> learningGoals;
  final bool acceptedTerms;
  final DateTime completedAt;
  final String? avatarStoragePath;
  final List<SkillProgress> skillProgress;
  final bool isPremium;
  final String? premiumCode;
  final DateTime? premiumActivatedAt;

  ChildProfile copyWith({
    String? childName,
    String? age,
    String? gender,
    List<String>? learningGoals,
    bool? acceptedTerms,
    DateTime? completedAt,
    String? avatarStoragePath,
    List<SkillProgress>? skillProgress,
    bool? isPremium,
    String? premiumCode,
    DateTime? premiumActivatedAt,
  }) {
    return ChildProfile(
      childName: childName ?? this.childName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      learningGoals: learningGoals ?? this.learningGoals,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      completedAt: completedAt ?? this.completedAt,
      avatarStoragePath: avatarStoragePath ?? this.avatarStoragePath,
      skillProgress: skillProgress ?? this.skillProgress,
      isPremium: isPremium ?? this.isPremium,
      premiumCode: premiumCode ?? this.premiumCode,
      premiumActivatedAt: premiumActivatedAt ?? this.premiumActivatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'childName': childName,
      'age': age,
      'gender': gender,
      'learningGoals': learningGoals,
      'acceptedTerms': acceptedTerms,
      'completedAt': completedAt.toIso8601String(),
      'avatarStoragePath': avatarStoragePath,
      'skillProgress': skillProgress
          .map((progress) => progress.toJson())
          .toList(growable: false),
      'isPremium': isPremium,
      'premiumCode': premiumCode,
      'premiumActivatedAt': premiumActivatedAt?.toIso8601String(),
    };
  }

  String get displayAge {
    final normalizedAge = age.trim();
    if (normalizedAge.isEmpty) {
      return 'Chưa cập nhật';
    }

    return '$normalizedAge tuổi';
  }

  String get primaryGoal {
    if (learningGoals.isEmpty) {
      return 'Chưa cập nhật';
    }

    return learningGoals.first;
  }

  String get planName {
    return isPremium ? 'Premium' : 'Miễn phí';
  }

  int get totalSkillPoints {
    return skillProgress.fold<int>(
      0,
      (total, progress) => total + progress.points,
    );
  }

  int get completedLessonCount {
    return skillProgress.where((progress) => progress.points > 0).length;
  }
}

class SkillProgress {
  const SkillProgress({
    required this.situationId,
    required this.islandId,
    required this.islandName,
    required this.lessonTitle,
    required this.skillName,
    required this.skillDescription,
    required this.practicePrompt,
    required this.riskAlert,
    required this.points,
    required this.completedCount,
    required this.firstCompletedAt,
    required this.lastCompletedAt,
  });

  factory SkillProgress.fromJson(Map<String, dynamic> json) {
    final completedAt =
        DateTime.tryParse(_readString(json['lastCompletedAt'])) ??
        DateTime.tryParse(_readString(json['completedAt'])) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final situationId = _normalizeSituationId(_readInt(json['situationId']));

    return SkillProgress(
      situationId: situationId,
      islandId: _normalizeIslandId(situationId, _readInt(json['islandId'])),
      islandName: _readString(json['islandName']),
      lessonTitle: _readString(json['lessonTitle']),
      skillName: _readString(json['skillName']),
      skillDescription: _readString(json['skillDescription']),
      practicePrompt: _readString(json['practicePrompt']),
      riskAlert: _readString(json['riskAlert']),
      points: _readInt(json['points']),
      completedCount: _readInt(json['completedCount']),
      firstCompletedAt:
          DateTime.tryParse(_readString(json['firstCompletedAt'])) ??
          completedAt,
      lastCompletedAt: completedAt,
    );
  }

  final int situationId;
  final int islandId;
  final String islandName;
  final String lessonTitle;
  final String skillName;
  final String skillDescription;
  final String practicePrompt;
  final String riskAlert;
  final int points;
  final int completedCount;
  final DateTime firstCompletedAt;
  final DateTime lastCompletedAt;

  SkillProgress copyWith({
    String? islandName,
    String? lessonTitle,
    String? skillName,
    String? skillDescription,
    String? practicePrompt,
    String? riskAlert,
    int? points,
    int? completedCount,
    DateTime? firstCompletedAt,
    DateTime? lastCompletedAt,
  }) {
    return SkillProgress(
      situationId: situationId,
      islandId: islandId,
      islandName: islandName ?? this.islandName,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      skillName: skillName ?? this.skillName,
      skillDescription: skillDescription ?? this.skillDescription,
      practicePrompt: practicePrompt ?? this.practicePrompt,
      riskAlert: riskAlert ?? this.riskAlert,
      points: points ?? this.points,
      completedCount: completedCount ?? this.completedCount,
      firstCompletedAt: firstCompletedAt ?? this.firstCompletedAt,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'situationId': situationId,
      'islandId': islandId,
      'islandName': islandName,
      'lessonTitle': lessonTitle,
      'skillName': skillName,
      'skillDescription': skillDescription,
      'practicePrompt': practicePrompt,
      'riskAlert': riskAlert,
      'points': points,
      'completedCount': completedCount,
      'firstCompletedAt': firstCompletedAt.toIso8601String(),
      'lastCompletedAt': lastCompletedAt.toIso8601String(),
    };
  }
}

String _readString(Object? value) {
  return value?.toString().trim() ?? '';
}

String? _readNullableString(Object? value) {
  final text = _readString(value);
  return text.isEmpty ? null : text;
}

List<String> _readStringList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<SkillProgress> _readSkillProgressList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map<String, dynamic>>()
      .map(SkillProgress.fromJson)
      .where((progress) => progress.situationId > 0)
      .toList(growable: false);
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? 0;
  }

  return 0;
}

int _normalizeSituationId(int situationId) {
  return switch (situationId) {
    101 => 1,
    102 => 2,
    103 => 3,
    301 => 4,
    302 => 5,
    303 => 6,
    201 => 7,
    202 => 8,
    203 => 9,
    _ => situationId,
  };
}

int _normalizeIslandId(int situationId, int fallbackIslandId) {
  if (situationId >= 1 && situationId <= 3) {
    return 1;
  }
  if (situationId >= 4 && situationId <= 6) {
    return 2;
  }
  if (situationId >= 7 && situationId <= 9) {
    return 3;
  }
  return fallbackIslandId;
}
