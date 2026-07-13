class IslandSummary {
  const IslandSummary({
    required this.islandId,
    required this.name,
    required this.orderIndex,
    required this.status,
    required this.situationCount,
    this.description,
    this.imageUrl,
  });

  factory IslandSummary.fromJson(Map<String, dynamic> json) {
    return IslandSummary(
      islandId: _readInt(json['islandId']),
      name: _readString(json['name']),
      description: _readNullableString(json['description']),
      imageUrl: _readNullableString(json['imageUrl']),
      orderIndex: _readInt(json['orderIndex']),
      status: _readString(json['status']),
      situationCount: _readInt(json['situationCount']),
    );
  }

  final int islandId;
  final String name;
  final String? description;
  final String? imageUrl;
  final int orderIndex;
  final String status;
  final int situationCount;
}

class SituationSummary {
  const SituationSummary({
    required this.situationId,
    required this.islandId,
    required this.islandName,
    required this.title,
    required this.orderIndex,
    required this.status,
    this.intro,
  });

  factory SituationSummary.fromJson(Map<String, dynamic> json) {
    return SituationSummary(
      situationId: _readInt(json['situationId']),
      islandId: _readInt(json['islandId']),
      islandName: _readString(json['islandName']),
      title: _readString(json['title']),
      intro: _readNullableString(json['intro']),
      orderIndex: _readInt(json['orderIndex']),
      status: _readString(json['status']),
    );
  }

  final int situationId;
  final int islandId;
  final String islandName;
  final String title;
  final String? intro;
  final int orderIndex;
  final String status;
}

class SituationDetail extends SituationSummary {
  const SituationDetail({
    required super.situationId,
    required super.islandId,
    required super.islandName,
    required super.title,
    required super.orderIndex,
    required super.status,
    required this.steps,
    required this.skills,
    super.intro,
    this.flashcard,
    this.parentReview,
  });

  factory SituationDetail.fromJson(Map<String, dynamic> json) {
    return SituationDetail(
      situationId: _readInt(json['situationId']),
      islandId: _readInt(json['islandId']),
      islandName: _readString(json['islandName']),
      title: _readString(json['title']),
      intro: _readNullableString(json['intro']),
      orderIndex: _readInt(json['orderIndex']),
      status: _readString(json['status']),
      steps: _readList(json['steps'], (item) => SituationStep.fromJson(item)),
      flashcard: json['flashcard'] is Map<String, dynamic>
          ? Flashcard.fromJson(json['flashcard'] as Map<String, dynamic>)
          : null,
      skills: _readList(
        json['skills'],
        (item) => SituationSkill.fromJson(item),
      ),
      parentReview: json['parentReview'] is Map<String, dynamic>
          ? ParentReviewQuestion.fromJson(
              json['parentReview'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final List<SituationStep> steps;
  final Flashcard? flashcard;
  final List<SituationSkill> skills;
  final ParentReviewQuestion? parentReview;
}

class SituationStep {
  const SituationStep({
    required this.stepId,
    required this.stepType,
    required this.orderIndex,
    this.content,
    this.mediaUrl,
  });

  factory SituationStep.fromJson(Map<String, dynamic> json) {
    return SituationStep(
      stepId: _readInt(json['stepId']),
      stepType: _readString(json['stepType']),
      orderIndex: _readInt(json['orderIndex']),
      content: _readNullableString(json['content']),
      mediaUrl: _readNullableString(json['mediaUrl']),
    );
  }

  final int stepId;
  final String stepType;
  final int orderIndex;
  final String? content;
  final String? mediaUrl;
}

class Flashcard {
  const Flashcard({
    required this.flashcardId,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.correctAnswer,
    this.questionVoiceUrl,
    this.optionAVoiceUrl,
    this.optionBVoiceUrl,
    this.optionAImageUrl,
    this.optionBImageUrl,
    this.correctFeedback,
    this.wrongFeedback,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      flashcardId: _readInt(json['flashcardId']),
      question: _readString(json['question']),
      optionA: _readString(json['optionA']),
      optionB: _readString(json['optionB']),
      correctAnswer: _readString(json['correctAnswer']),
      questionVoiceUrl: _readNullableString(json['questionVoiceUrl']),
      optionAVoiceUrl: _readNullableString(json['optionAVoiceUrl']),
      optionBVoiceUrl: _readNullableString(json['optionBVoiceUrl']),
      optionAImageUrl: _readNullableString(json['optionAImageUrl']),
      optionBImageUrl: _readNullableString(json['optionBImageUrl']),
      correctFeedback: _readNullableString(json['correctFeedback']),
      wrongFeedback: _readNullableString(json['wrongFeedback']),
    );
  }

  final int flashcardId;
  final String question;
  final String optionA;
  final String optionB;
  final String correctAnswer;
  final String? questionVoiceUrl;
  final String? optionAVoiceUrl;
  final String? optionBVoiceUrl;
  final String? optionAImageUrl;
  final String? optionBImageUrl;
  final String? correctFeedback;
  final String? wrongFeedback;
}

class SituationSkill {
  const SituationSkill({
    required this.skillId,
    required this.name,
    this.description,
  });

  factory SituationSkill.fromJson(Map<String, dynamic> json) {
    return SituationSkill(
      skillId: _readInt(json['skillId']),
      name: _readString(json['name']),
      description: _readNullableString(json['description']),
    );
  }

  final int skillId;
  final String name;
  final String? description;
}

class ParentReviewQuestion {
  const ParentReviewQuestion({
    required this.questionId,
    required this.skillId,
    required this.questionText,
    this.suggestedActivity,
    this.watchOutTip,
  });

  factory ParentReviewQuestion.fromJson(Map<String, dynamic> json) {
    return ParentReviewQuestion(
      questionId: _readInt(json['questionId']),
      skillId: _readInt(json['skillId']),
      questionText: _readString(json['questionText']),
      suggestedActivity: _readNullableString(json['suggestedActivity']),
      watchOutTip: _readNullableString(json['watchOutTip']),
    );
  }

  final int questionId;
  final int skillId;
  final String questionText;
  final String? suggestedActivity;
  final String? watchOutTip;
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

String _readString(Object? value) {
  return value?.toString() ?? '';
}

String? _readNullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

List<T> _readList<T>(
  Object? value,
  T Function(Map<String, dynamic> json) parse,
) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map<String, dynamic>>()
      .map(parse)
      .toList(growable: false);
}
