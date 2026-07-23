class TaskProgressModel {
  final int taskProgressId;
  final int taskId;
  final int childId;
  final String status;
  final String? proofImageUrl;
  final String? note;
  final DateTime? completedAt;
  final DateTime? approvedAt;

  TaskProgressModel({
    required this.taskProgressId,
    required this.taskId,
    required this.childId,
    required this.status,
    this.proofImageUrl,
    this.note,
    this.completedAt,
    this.approvedAt,
  });

  factory TaskProgressModel.fromJson(Map<String, dynamic> json) {
    return TaskProgressModel(
      taskProgressId: json['taskProgressId'] ?? 0,
      taskId: json['taskId'] ?? 0,
      childId: json['childId'] ?? 0,
      status: json['status'] ?? 'Pending',
      proofImageUrl: json['proofImageUrl'],
      note: json['note'],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskProgressId': taskProgressId,
      'taskId': taskId,
      'childId': childId,
      'status': status,
      'proofImageUrl': proofImageUrl,
      'note': note,
      'completedAt': completedAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
    };
  }
}

class ChildTaskModel {
  final int taskId;
  final int parentId;
  final int? childId;
  final String title;
  final String? description;
  final int rewardPoints;
  final String frequency;
  final DateTime? dueDate;
  final String status;
  final DateTime createdAt;
  final TaskProgressModel? latestProgress;

  ChildTaskModel({
    required this.taskId,
    required this.parentId,
    this.childId,
    required this.title,
    this.description,
    required this.rewardPoints,
    required this.frequency,
    this.dueDate,
    required this.status,
    required this.createdAt,
    this.latestProgress,
  });

  factory ChildTaskModel.fromJson(Map<String, dynamic> json) {
    return ChildTaskModel(
      taskId: json['taskId'] ?? 0,
      parentId: json['parentId'] ?? 0,
      childId: json['childId'],
      title: json['title'] ?? '',
      description: json['description'],
      rewardPoints: json['rewardPoints'] ?? 10,
      frequency: json['frequency'] ?? 'Daily',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      status: json['status'] ?? 'Active',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      latestProgress: json['latestProgress'] != null
          ? TaskProgressModel.fromJson(json['latestProgress'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'parentId': parentId,
      'childId': childId,
      'title': title,
      'description': description,
      'rewardPoints': rewardPoints,
      'frequency': frequency,
      'dueDate': dueDate?.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'latestProgress': latestProgress?.toJson(),
    };
  }
}
