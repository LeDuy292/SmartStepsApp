import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AdminApiService {
  static const String baseUrl = 'http://localhost:8080/api/admin';
  final http.Client _client = http.Client();
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Generic GET
  Future<dynamic> get(String endpoint) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
    );
    _checkStatus(response);
    return jsonDecode(response.body);
  }

  // Generic POST
  Future<dynamic> post(String endpoint, [Map<String, dynamic>? body]) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    _checkStatus(response);
    return jsonDecode(response.body);
  }

  // Generic PUT
  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final response = await _client.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    _checkStatus(response);
    return jsonDecode(response.body);
  }

  // Generic DELETE
  Future<dynamic> delete(String endpoint) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
    );
    _checkStatus(response);
    return jsonDecode(response.body);
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode >= 400) {
      String message = 'Lỗi hệ thống';
      try {
        final body = jsonDecode(response.body);
        if (body['message'] != null) {
          message = body['message'];
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  // ---------------------------------------------------------
  // USERS
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> getUsers({int page = 1, int limit = 20, String? search, String? role, String? status}) async {
    var url = '/users?page=$page&limit=$limit';
    if (search != null && search.isNotEmpty) url += '&search=$search';
    if (role != null && role.isNotEmpty) url += '&role=$role';
    if (status != null && status.isNotEmpty) url += '&status=$status';
    return await get(url);
  }

  Future<void> createUser(Map<String, dynamic> data) async => await post('/users', data);
  Future<void> updateUser(int id, Map<String, dynamic> data) async => await put('/users/$id', data);
  Future<void> lockUser(int id, String reason) async => await post('/users/$id/lock', {'reason': reason});
  Future<void> unlockUser(int id) async => await post('/users/$id/unlock');
  Future<void> resetPassword(int id) async => await post('/users/$id/reset-password');
  Future<void> deleteUser(int id) async => await delete('/users/$id');

  // ---------------------------------------------------------
  // DASHBOARD
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> getDashboardMetrics() async => await get('/reports/dashboard');
  Future<List<dynamic>> getRecentAnswers() async => await get('/reports/answers?limit=20');

  // Add more as needed for Islands, Situations, etc.
  // ---------------------------------------------------------
  // ISLANDS
  // ---------------------------------------------------------
  Future<List<dynamic>> getIslands() async => await get('/islands');
  Future<dynamic> getIsland(int id) async => await get('/islands/$id');
  Future<dynamic> createIsland(Map<String, dynamic> data) async => await post('/islands', data);
  Future<dynamic> updateIsland(int id, Map<String, dynamic> data) async => await put('/islands/$id', data);
  Future<dynamic> deleteIsland(int id) async => await delete('/islands/$id');

  // ---------------------------------------------------------
  // SITUATIONS
  // ---------------------------------------------------------
  Future<List<dynamic>> getSituations({int? islandId}) async {
    return await get('/situations${islandId != null ? '?islandId=$islandId' : ''}');
  }
  Future<dynamic> getSituation(int id) async => await get('/situations/$id');
  Future<dynamic> createSituation(Map<String, dynamic> data) async => await post('/situations', data);
  Future<dynamic> updateSituation(int id, Map<String, dynamic> data) async => await put('/situations/$id', data);
  Future<dynamic> deleteSituation(int id) async => await delete('/situations/$id');

  // ---------------------------------------------------------
  // SITUATION STEPS & FLASHCARDS
  // ---------------------------------------------------------
  Future<dynamic> createStep(int situationId, Map<String, dynamic> data) async => await post('/situations/$situationId/steps', data);
  Future<dynamic> updateStep(int stepId, Map<String, dynamic> data) async => await put('/situations/steps/$stepId', data);
  Future<dynamic> deleteStep(int stepId) async => await delete('/situations/steps/$stepId');

  Future<dynamic> createFlashcard(int situationId, Map<String, dynamic> data) async => await post('/situations/$situationId/flashcards', data);
  Future<dynamic> updateFlashcard(int fcId, Map<String, dynamic> data) async => await put('/situations/flashcards/$fcId', data);
  Future<dynamic> deleteFlashcard(int fcId) async => await delete('/situations/flashcards/$fcId');

  // ---------------------------------------------------------
  // SKILLS
  // ---------------------------------------------------------
  Future<List<dynamic>> getSkills() async => await get('/skills');
  Future<dynamic> createSkill(Map<String, dynamic> data) async => await post('/skills', data);
  Future<dynamic> updateSkill(int id, Map<String, dynamic> data) async => await put('/skills/$id', data);
  Future<dynamic> deleteSkill(int id) async => await delete('/skills/$id');
}
