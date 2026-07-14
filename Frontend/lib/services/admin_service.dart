import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';
import 'auth_service.dart';

class AdminService {
  AdminService({AuthService? authService})
    : _authService = authService ?? AuthService();
  final AuthService _authService;

  Future<AdminDashboardData> getDashboard() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const AdminServiceException('Phiên đăng nhập đã hết hạn.');
    }
    final configured = AppConstants.apiBaseUrl.trim();
    final baseUrl = configured.isNotEmpty
        ? configured.replaceFirst(RegExp(r'/$'), '')
        : (kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080');
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/dashboard'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AdminServiceException('Admin API returned ${response.statusCode}.');
    }
    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw const AdminServiceException('Dữ liệu dashboard không hợp lệ.');
    }
    return AdminDashboardData.fromJson(payload);
  }
}

class AdminDashboardData {
  const AdminDashboardData({
    required this.users,
    required this.completedLessons,
    required this.activePremium,
    required this.feedbackCount,
    required this.feedback,
  });
  factory AdminDashboardData.fromJson(Map<String, dynamic> json) =>
      AdminDashboardData(
        users: _int(json['users']),
        completedLessons: _int(json['completedLessons']),
        activePremium: _int(json['activePremium']),
        feedbackCount: _int(json['feedbackCount']),
        feedback: (json['feedback'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AdminFeedback.fromJson)
            .toList(growable: false),
      );
  final int users;
  final int completedLessons;
  final int activePremium;
  final int feedbackCount;
  final List<AdminFeedback> feedback;
}

class AdminFeedback {
  const AdminFeedback({
    required this.email,
    required this.experienceRating,
    required this.note,
    required this.submittedAt,
  });
  factory AdminFeedback.fromJson(Map<String, dynamic> json) => AdminFeedback(
    email: json['email']?.toString() ?? '',
    experienceRating: _int(json['experienceRating']),
    note: json['improvementNote']?.toString() ?? '',
    submittedAt: DateTime.tryParse(json['submittedAt']?.toString() ?? ''),
  );
  final String email;
  final int experienceRating;
  final String note;
  final DateTime? submittedAt;
}

int _int(Object? value) => value is int ? value : int.tryParse('$value') ?? 0;

class AdminServiceException implements Exception {
  const AdminServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}
