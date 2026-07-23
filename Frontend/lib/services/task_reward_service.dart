import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reward_model.dart';
import '../models/task_model.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class TaskRewardService {
  TaskRewardService({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  Uri _uri(String unencodedPath, [Map<String, String>? queryParameters]) {
    final baseUrl = AppConstants.apiBaseUrl;
    final parsed = Uri.parse(baseUrl);
    return parsed.replace(
      path: '${parsed.path}$unencodedPath'.replaceAll('//', '/'),
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // --- Task APIs ---
  Future<List<ChildTaskModel>> getTasksForChild(int childId) async {
    try {
      final response = await http.get(
        _uri('/api/tasks/child/$childId'),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final list = data.map((e) => ChildTaskModel.fromJson(e)).toList();
        if (list.isNotEmpty) return list;
      }
      
      final fallbackResponse = await http.get(
        _uri('/api/tasks'),
        headers: await _headers(),
      );
      if (fallbackResponse.statusCode == 200) {
        final List<dynamic> data = jsonDecode(fallbackResponse.body);
        return data.map((e) => ChildTaskModel.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error getTasksForChild: $e');
    }
    return [];
  }

  Future<ChildTaskModel?> createTask({
    required int parentId,
    int? childId,
    required String title,
    String? description,
    int rewardPoints = 10,
    String frequency = 'Daily',
    DateTime? dueDate,
  }) async {
    final response = await http.post(
      _uri('/api/tasks'),
      headers: await _headers(),
      body: jsonEncode({
        'parentId': parentId,
        'childId': childId,
        'title': title,
        'description': description,
        'rewardPoints': rewardPoints,
        'frequency': frequency,
        'dueDate': dueDate?.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      return ChildTaskModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<TaskProgressModel?> completeTask({
    required int taskId,
    required int childId,
    String? proofImageUrl,
    String? note,
  }) async {
    final response = await http.post(
      _uri('/api/tasks/$taskId/complete'),
      headers: await _headers(),
      body: jsonEncode({
        'childId': childId,
        'proofImageUrl': proofImageUrl,
        'note': note,
      }),
    );

    if (response.statusCode == 200) {
      return TaskProgressModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<bool> approveTask(int progressId) async {
    final response = await http.post(
      _uri('/api/tasks/progress/$progressId/approve'),
      headers: await _headers(),
    );
    return response.statusCode == 200;
  }

  Future<bool> approveTaskDirect(int taskId) async {
    final response = await http.post(
      _uri('/api/tasks/$taskId/approve'),
      headers: await _headers(),
    );
    return response.statusCode == 200;
  }

  Future<bool> updateTask({
    required int taskId,
    required String title,
    String? description,
    required int rewardPoints,
  }) async {
    final response = await http.put(
      _uri('/api/tasks/$taskId'),
      headers: await _headers(),
      body: jsonEncode({
        'title': title,
        'description': description,
        'rewardPoints': rewardPoints,
      }),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteTask(int taskId) async {
    final response = await http.delete(
      _uri('/api/tasks/$taskId'),
      headers: await _headers(),
    );
    return response.statusCode == 200;
  }

  // --- Reward APIs ---
  Future<List<RewardItemModel>> getRewards({int? parentId}) async {
    try {
      final response = await http.get(
        _uri('/api/rewards', parentId != null ? {'parentId': parentId.toString()} : null),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => RewardItemModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<RewardItemModel?> createReward({
    int? parentId,
    required String title,
    String? description,
    int costPoints = 50,
    String rewardType = 'Virtual',
    String? iconUrl,
  }) async {
    final response = await http.post(
      _uri('/api/rewards'),
      headers: await _headers(),
      body: jsonEncode({
        'parentId': parentId,
        'title': title,
        'description': description,
        'costPoints': costPoints,
        'rewardType': rewardType,
        'iconUrl': iconUrl,
      }),
    );

    if (response.statusCode == 200) {
      return RewardItemModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<RewardRedemptionModel?> redeemReward({
    required int rewardId,
    required int childId,
  }) async {
    final response = await http.post(
      _uri('/api/rewards/$rewardId/redeem'),
      headers: await _headers(),
      body: jsonEncode({'childId': childId}),
    );

    if (response.statusCode == 200) {
      return RewardRedemptionModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<List<RewardRedemptionModel>> getRedemptions({int? childId}) async {
    try {
      final response = await http.get(
        _uri('/api/rewards/redemptions', childId != null ? {'childId': childId.toString()} : null),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => RewardRedemptionModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> approveRedemption(int redemptionId) async {
    final response = await http.post(
      _uri('/api/rewards/redemptions/$redemptionId/approve'),
      headers: await _headers(),
    );
    return response.statusCode == 200;
  }

  Future<bool> rejectRedemption(int redemptionId) async {
    final response = await http.post(
      _uri('/api/rewards/redemptions/$redemptionId/reject'),
      headers: await _headers(),
    );
    return response.statusCode == 200;
  }
}
