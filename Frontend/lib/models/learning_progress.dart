class LearningProgress {
  const LearningProgress({
    required this.completedSituationIds,
    required this.items,
  });

  factory LearningProgress.fromJson(Map<String, dynamic> json) {
    return LearningProgress(
      completedSituationIds:
          (json['completedSituationIds'] as List<dynamic>? ?? const [])
              .map(
                (value) => value is int ? value : int.tryParse('$value') ?? 0,
              )
              .where((value) => value > 0)
              .toSet(),
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LearningProgressItem.fromJson)
          .toList(growable: false),
    );
  }

  final Set<int> completedSituationIds;
  final List<LearningProgressItem> items;
}

class LearningProgressItem {
  const LearningProgressItem({
    required this.islandId,
    required this.situationId,
    required this.currentStep,
    required this.status,
  });

  factory LearningProgressItem.fromJson(Map<String, dynamic> json) {
    int readInt(String key) =>
        json[key] is int ? json[key] as int : int.tryParse('${json[key]}') ?? 0;
    return LearningProgressItem(
      islandId: readInt('islandId'),
      situationId: readInt('situationId'),
      currentStep: readInt('currentStep'),
      status: json['status']?.toString() ?? '',
    );
  }

  final int islandId;
  final int situationId;
  final int currentStep;
  final String status;
}
