class RewardItemModel {
  final int rewardId;
  final int? parentId;
  final String title;
  final String? description;
  final int costPoints;
  final String rewardType;
  final String? iconUrl;
  final bool isActive;

  RewardItemModel({
    required this.rewardId,
    this.parentId,
    required this.title,
    this.description,
    required this.costPoints,
    required this.rewardType,
    this.iconUrl,
    required this.isActive,
  });

  factory RewardItemModel.fromJson(Map<String, dynamic> json) {
    return RewardItemModel(
      rewardId: json['rewardId'] ?? 0,
      parentId: json['parentId'],
      title: json['title'] ?? '',
      description: json['description'],
      costPoints: json['costPoints'] ?? 50,
      rewardType: json['rewardType'] ?? 'Virtual',
      iconUrl: json['iconUrl'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rewardId': rewardId,
      'parentId': parentId,
      'title': title,
      'description': description,
      'costPoints': costPoints,
      'rewardType': rewardType,
      'iconUrl': iconUrl,
      'isActive': isActive,
    };
  }
}

class RewardRedemptionModel {
  final int redemptionId;
  final int rewardId;
  final String rewardTitle;
  final int childId;
  final int pointsSpent;
  final String status;
  final DateTime redeemedAt;

  RewardRedemptionModel({
    required this.redemptionId,
    required this.rewardId,
    required this.rewardTitle,
    required this.childId,
    required this.pointsSpent,
    required this.status,
    required this.redeemedAt,
  });

  factory RewardRedemptionModel.fromJson(Map<String, dynamic> json) {
    return RewardRedemptionModel(
      redemptionId: json['redemptionId'] ?? 0,
      rewardId: json['rewardId'] ?? 0,
      rewardTitle: json['rewardTitle'] ?? '',
      childId: json['childId'] ?? 0,
      pointsSpent: json['pointsSpent'] ?? 0,
      status: json['status'] ?? 'Pending',
      redeemedAt: json['redeemedAt'] != null
          ? DateTime.parse(json['redeemedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'redemptionId': redemptionId,
      'rewardId': rewardId,
      'rewardTitle': rewardTitle,
      'childId': childId,
      'pointsSpent': pointsSpent,
      'status': status,
      'redeemedAt': redeemedAt.toIso8601String(),
    };
  }
}
