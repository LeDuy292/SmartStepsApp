import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/learning_analysis.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class LearningService {
  LearningService({AuthService? authService, http.Client? client})
    : _authService = authService ?? AuthService(),
      _client = client ?? http.Client();

  final AuthService _authService;
  final http.Client _client;

  String get _baseUrl {
    final configured = AppConstants.apiBaseUrl.trim();
    if (configured.isNotEmpty) {
      return configured.replaceFirst(RegExp(r'/$'), '');
    }
    return kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
  }

  Future<void> startSituation(int situationId) async {
    final session = await _session();
    await _send(
      'POST',
      '/api/progress/start',
      session,
      body: {'situationId': situationId, 'userEmail': session.email},
    );
  }

  Future<void> updateCurrentStep({
    required int situationId,
    required int stepId,
  }) async {
    final session = await _session();
    await _send(
      'PUT',
      '/api/progress/step',
      session,
      body: {
        'situationId': situationId,
        'stepId': stepId,
        'userEmail': session.email,
      },
    );
  }

  Future<void> recordAnswer({
    required int flashcardId,
    required String selectedAnswer,
  }) async {
    final session = await _session();
    await _send(
      'POST',
      '/api/progress/answer',
      session,
      body: {
        'flashcardId': flashcardId,
        'selectedAnswer': selectedAnswer,
        'userEmail': session.email,
      },
    );
  }

  Future<void> completeSituation(int situationId) async {
    final session = await _session();
    await _send(
      'POST',
      '/api/progress/complete',
      session,
      body: {'situationId': situationId, 'userEmail': session.email},
    );
  }

  Future<LearningAnalysis> generateReport() async {
    final session = await _session();
    final response = await _send(
      'POST',
      '/api/learning-analysis/${session.userId}/reports',
      session,
      body: const {},
    );
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw const LearningServiceException('Invalid learning report response.');
    }
    return LearningAnalysis.fromJson(json);
  }

  Future<_LearningSession> _session() async {
    final token = await _authService.getToken();
    final userId = await _authService.getUserId();
    final email = await _authService.getUserEmail();
    if (token == null || userId == null || email == null) {
      throw const LearningServiceException(
        'No authenticated learning session.',
      );
    }
    return _LearningSession(token: token, userId: userId, email: email);
  }

  Future<http.Response> _send(
    String method,
    String path,
    _LearningSession session, {
    Map<String, Object?>? body,
  }) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'))
      ..headers.addAll({
        'Authorization': 'Bearer ${session.token}',
        'Content-Type': 'application/json',
      });
    if (body != null) {
      request.body = jsonEncode(body);
    }
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? serverMessage;
      try {
        final payload = jsonDecode(response.body);
        if (payload is Map<String, dynamic>) {
          serverMessage = payload['message']?.toString().trim();
        }
      } catch (_) {
        // Use the HTTP status when the server did not return JSON.
      }
      throw LearningServiceException(
        serverMessage == null || serverMessage.isEmpty
            ? 'Learning API returned ${response.statusCode}.'
            : 'Learning API returned ${response.statusCode}: $serverMessage',
      );
    }
    return response;
  }
}

class LearningServiceException implements Exception {
  const LearningServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _LearningSession {
  const _LearningSession({
    required this.token,
    required this.userId,
    required this.email,
  });

  final String token;
  final int userId;
  final String email;
}
