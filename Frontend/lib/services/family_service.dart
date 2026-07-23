import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';
import 'auth_service.dart';

class FamilyService {
  FamilyService({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  Future<List<Map<String, dynamic>>> getChildren() async =>
      _getList('/api/family/children');

  Future<Map<String, dynamic>> getOverview(int childId) async =>
      _getMap('/api/family/children/$childId/overview');

  Future<List<Map<String, dynamic>>> getProgress(int childId) async =>
      _getList('/api/family/children/$childId/progress');

  Future<Map<String, dynamic>> getReport(int childId) async =>
      _getMap('/api/family/children/$childId/report');

  Future<List<Map<String, dynamic>>> getPendingActivities(int childId) async =>
      _getList('/api/family/children/$childId/activities/pending');

  Future<Map<String, dynamic>> createLinkCode() async {
    final response = await http.post(
      _uri('/api/family/link-codes'),
      headers: await _headers(),
    );
    _ensureSuccess(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> linkChild(String code) async =>
      _send('/api/family/children/link', {'code': code});

  Future<void> createChild(String name, String email, String password) async =>
      _send('/api/family/children', {
        'fullName': name,
        'email': email,
        'password': password,
      });

  Future<void> confirmActivity(
    int childId,
    int situationId,
    String note,
  ) async => _send('/api/family/children/$childId/activities', {
    'situationId': situationId,
    'note': note,
  });

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final response = await http.get(_uri(path), headers: await _headers());
    _ensureSuccess(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _getMap(String path) async {
    final response = await http.get(_uri(path), headers: await _headers());
    _ensureSuccess(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> _send(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      _uri(path),
      headers: await _headers(json: true),
      body: jsonEncode(body),
    );
    _ensureSuccess(response);
  }

  Uri _uri(String path) {
    final configured = AppConstants.apiBaseUrl.trim();
    final base = configured.isNotEmpty
        ? configured.replaceFirst(RegExp(r'/$'), '')
        : (kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080');
    return Uri.parse('$base$path');
  }

  Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await _authService.getToken();
    if (token == null)
      throw const FamilyServiceException('Phiên đăng nhập đã hết hạn.');
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    var message = 'Không thể xử lý yêu cầu (${response.statusCode}).';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['message'] != null) {
        message = body['message'].toString();
      }
    } catch (_) {}
    throw FamilyServiceException(message);
  }
}

class FamilyServiceException implements Exception {
  const FamilyServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}
