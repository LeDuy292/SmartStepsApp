class AppFeedbackEntry {
  const AppFeedbackEntry({
    required this.id,
    required this.source,
    required this.submittedAt,
    required this.experienceRating,
    required this.childEngagementRating,
    required this.effectivenessRating,
    required this.ageFit,
    required this.improvementNote,
  });

  factory AppFeedbackEntry.fromJson(Map<String, dynamic> json) {
    return AppFeedbackEntry(
      id: _readString(json['id']),
      source: _readString(json['source']),
      submittedAt:
          DateTime.tryParse(_readString(json['submittedAt'])) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      experienceRating: _readInt(json['experienceRating'], fallback: 0),
      childEngagementRating: _readInt(
        json['childEngagementRating'],
        fallback: 0,
      ),
      effectivenessRating: _readInt(json['effectivenessRating'], fallback: 0),
      ageFit: _readString(json['ageFit']),
      improvementNote: _readString(json['improvementNote']),
    );
  }

  final String id;
  final String source;
  final DateTime submittedAt;
  final int experienceRating;
  final int childEngagementRating;
  final int effectivenessRating;
  final String ageFit;
  final String improvementNote;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'submittedAt': submittedAt.toIso8601String(),
      'experienceRating': experienceRating,
      'childEngagementRating': childEngagementRating,
      'effectivenessRating': effectivenessRating,
      'ageFit': ageFit,
      'improvementNote': improvementNote,
    };
  }
}

class AppFeedbackPromptState {
  const AppFeedbackPromptState({
    this.hasObservedFirstExit = false,
    this.hasShownFirstExitPrompt = false,
    this.hasSubmittedFeedback = false,
    this.firstExitAt,
    this.firstPromptShownAt,
    this.lastFeedbackAt,
  });

  factory AppFeedbackPromptState.fromJson(Map<String, dynamic> json) {
    return AppFeedbackPromptState(
      hasObservedFirstExit: json['hasObservedFirstExit'] == true,
      hasShownFirstExitPrompt: json['hasShownFirstExitPrompt'] == true,
      hasSubmittedFeedback: json['hasSubmittedFeedback'] == true,
      firstExitAt: DateTime.tryParse(_readString(json['firstExitAt'])),
      firstPromptShownAt: DateTime.tryParse(
        _readString(json['firstPromptShownAt']),
      ),
      lastFeedbackAt: DateTime.tryParse(_readString(json['lastFeedbackAt'])),
    );
  }

  final bool hasObservedFirstExit;
  final bool hasShownFirstExitPrompt;
  final bool hasSubmittedFeedback;
  final DateTime? firstExitAt;
  final DateTime? firstPromptShownAt;
  final DateTime? lastFeedbackAt;

  AppFeedbackPromptState copyWith({
    bool? hasObservedFirstExit,
    bool? hasShownFirstExitPrompt,
    bool? hasSubmittedFeedback,
    DateTime? firstExitAt,
    DateTime? firstPromptShownAt,
    DateTime? lastFeedbackAt,
  }) {
    return AppFeedbackPromptState(
      hasObservedFirstExit: hasObservedFirstExit ?? this.hasObservedFirstExit,
      hasShownFirstExitPrompt:
          hasShownFirstExitPrompt ?? this.hasShownFirstExitPrompt,
      hasSubmittedFeedback: hasSubmittedFeedback ?? this.hasSubmittedFeedback,
      firstExitAt: firstExitAt ?? this.firstExitAt,
      firstPromptShownAt: firstPromptShownAt ?? this.firstPromptShownAt,
      lastFeedbackAt: lastFeedbackAt ?? this.lastFeedbackAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasObservedFirstExit': hasObservedFirstExit,
      'hasShownFirstExitPrompt': hasShownFirstExitPrompt,
      'hasSubmittedFeedback': hasSubmittedFeedback,
      'firstExitAt': firstExitAt?.toIso8601String(),
      'firstPromptShownAt': firstPromptShownAt?.toIso8601String(),
      'lastFeedbackAt': lastFeedbackAt?.toIso8601String(),
    };
  }
}

String _readString(Object? value) {
  return value?.toString().trim() ?? '';
}

int _readInt(Object? value, {required int fallback}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }

  return fallback;
}
