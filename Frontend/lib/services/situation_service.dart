import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/offline_situation_catalog.dart';
import '../models/situation.dart';
import '../utils/constants.dart';

class SituationService {
  SituationService({String? baseUrl, http.Client? httpClient})
    : _configuredBaseUrl = baseUrl,
      _client = httpClient ?? http.Client();

  final String? _configuredBaseUrl;
  final http.Client _client;

  String get _baseUrl {
    final configured = (_configuredBaseUrl ?? AppConstants.apiBaseUrl).trim();
    if (configured.isNotEmpty) {
      return configured.replaceFirst(RegExp(r'/$'), '');
    }
    return kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
  }

  bool get isEnabled => true;

  Future<List<IslandSummary>> getIslands() async {
    final payload = await _getJsonList('/api/islands');
    return payload.map(IslandSummary.fromJson).toList(growable: false);
  }

  Future<List<SituationSummary>> getSituations() async {
    final payload = await _getJsonList('/api/situations');
    return payload.map(SituationSummary.fromJson).toList(growable: false);
  }

  Future<List<SituationSummary>> getIslandSituations(int islandId) async {
    final payload = await _getJsonList('/api/islands/$islandId/situations');
    return payload.map(SituationSummary.fromJson).toList(growable: false);
  }

  Future<SituationDetail> getSituationDetail(int situationId) async {
    final payload = await _getJson('/api/situations/$situationId');
    final remote = SituationDetail.fromJson(payload);

    // The database owns lesson content and IDs. Bundled artwork remains a
    // presentation fallback until image columns are added to the API schema.
    final bundled = offlineSituationDetailById(situationId);
    if (bundled == null) return remote;
    final flashcard = remote.flashcard;
    final bundledFlashcard = bundled.flashcard;
    return SituationDetail(
      situationId: remote.situationId,
      islandId: remote.islandId,
      islandName: remote.islandName,
      title: remote.title,
      intro: remote.intro,
      orderIndex: remote.orderIndex,
      status: remote.status,
      steps: remote.steps,
      skills: remote.skills,
      flashcard: flashcard == null
          ? null
          : Flashcard(
              flashcardId: flashcard.flashcardId,
              question: flashcard.question,
              optionA: flashcard.optionA,
              optionB: flashcard.optionB,
              correctAnswer: flashcard.correctAnswer,
              questionVoiceUrl: flashcard.questionVoiceUrl,
              optionAVoiceUrl: flashcard.optionAVoiceUrl,
              optionBVoiceUrl: flashcard.optionBVoiceUrl,
              optionAImageUrl: bundledFlashcard?.optionAImageUrl,
              optionBImageUrl: bundledFlashcard?.optionBImageUrl,
              correctFeedback: flashcard.correctFeedback,
              wrongFeedback: flashcard.wrongFeedback,
            ),
      parentReview: remote.parentReview == null
          ? null
          : ParentReviewQuestion(
              questionId: remote.parentReview!.questionId,
              skillId: remote.parentReview!.skillId,
              questionText: remote.parentReview!.questionText,
              suggestedActivity: remote.parentReview!.suggestedActivity,
              watchOutTip: bundled.parentReview?.watchOutTip,
            ),
    );
  }

  Future<SignedMediaUrl> createSignedMediaUrl(int stepId) async {
    final payload = await _postJson('/api/media/signed-url', {
      'stepId': stepId,
    });
    return SignedMediaUrl.fromJson(payload);
  }

  Future<SignedMediaUrl> createSignedVoiceUrl(String mediaUrl) async {
    final payload = await _postJson('/api/media/signed-voice-url', {
      'mediaUrl': mediaUrl,
    });
    return SignedMediaUrl.fromJson(payload);
  }

  Future<List<Map<String, dynamic>>> _getJsonList(String path) async {
    final response = await _client.get(Uri.parse('$_baseUrl$path'));
    final payload = _decodeResponse(response);
    if (payload is! List) {
      throw const SituationServiceException('Invalid list response.');
    }
    return payload.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final response = await _client.get(Uri.parse('$_baseUrl$path'));
    final payload = _decodeResponse(response);
    if (payload is! Map<String, dynamic>) {
      throw const SituationServiceException('Invalid object response.');
    }
    return payload;
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, Object?> body,
  ) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final payload = _decodeResponse(response);
    if (payload is! Map<String, dynamic>) {
      throw const SituationServiceException('Invalid object response.');
    }
    return payload;
  }

  Object? _decodeResponse(http.Response response) {
    Object? payload;
    try {
      payload = jsonDecode(response.body);
    } catch (_) {
      payload = null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload is Map<String, dynamic>
          ? payload['message']?.toString()
          : null;
      throw SituationServiceException(
        message?.trim().isNotEmpty == true
            ? message!.trim()
            : 'Content API returned ${response.statusCode}.',
      );
    }
    return payload;
  }
}

class SituationServiceException implements Exception {
  const SituationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MediaConfigurationException extends SituationServiceException {
  const MediaConfigurationException(super.message);
}

class SignedMediaUrl {
  const SignedMediaUrl({required this.uri, required this.expiresAt});

  factory SignedMediaUrl.fromJson(Map<String, dynamic> json) {
    final url = json['signedUrl']?.toString() ?? '';
    final expiresAt = DateTime.tryParse(json['expiresAtUtc']?.toString() ?? '');
    if (url.isEmpty || expiresAt == null) {
      throw const MediaConfigurationException('Invalid signed media URL.');
    }
    return SignedMediaUrl(uri: Uri.parse(url), expiresAt: expiresAt.toLocal());
  }

  final Uri uri;
  final DateTime expiresAt;

  bool get isFresh {
    return expiresAt.isAfter(DateTime.now().add(const Duration(minutes: 1)));
  }
}
