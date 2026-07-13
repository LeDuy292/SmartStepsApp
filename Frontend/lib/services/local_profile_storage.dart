import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/app_feedback.dart';
import '../models/child_profile.dart';
import 'platform_storage.dart';

class LocalProfileStorage {
  const LocalProfileStorage({Directory? directoryOverride})
    : _directoryOverride = directoryOverride;

  final Directory? _directoryOverride;

  PlatformStorage get _storage => createPlatformStorage(_directoryOverride);

  Future<bool> hasProfile() async {
    final profile = await readProfile();
    return profile != null;
  }

  Future<ChildProfile?> readProfile() async {
    try {
      final content = await _storage.readString('child_profile');
      if (content == null) {
        return null;
      }

      final json = jsonDecode(content);
      if (json is! Map<String, dynamic>) {
        return null;
      }

      return ChildProfile.fromJson(json);
    } catch (error, stackTrace) {
      debugPrint('SmartSteps profile read failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> saveProfile(ChildProfile profile) async {
    const encoder = JsonEncoder.withIndent('  ');
    await _storage.writeString(
      'child_profile',
      encoder.convert(profile.toJson()),
    );
  }

  Future<void> clearProfile() async {
    await _storage.deleteKey('child_profile');
  }

  Future<ChildProfile> activatePremium(String code) async {
    if (code.trim().toUpperCase() != premiumActivationCode) {
      throw const PremiumActivationException('Mã Premium không hợp lệ.');
    }

    final currentProfile = await readProfile();
    if (currentProfile == null) {
      throw const PremiumActivationException(
        'Cần hoàn tất khảo sát ban đầu trước khi nâng cấp.',
      );
    }

    final updatedProfile = currentProfile.copyWith(
      isPremium: true,
      premiumCode: premiumActivationCode,
      premiumActivatedAt: DateTime.now(),
    );
    await saveProfile(updatedProfile);
    return updatedProfile;
  }

  Future<ChildProfile> recordLessonCompletion({
    required int situationId,
    required int islandId,
    required String islandName,
    required String lessonTitle,
    required String skillName,
    required String skillDescription,
    required String practicePrompt,
    required String riskAlert,
    int points = 1,
  }) async {
    final currentProfile = await readProfile();
    if (currentProfile == null) {
      throw const ProfileStorageException(
        'Cần hoàn tất khảo sát ban đầu trước khi lưu tiến độ.',
      );
    }

    final now = DateTime.now();
    final progress = currentProfile.skillProgress.toList(growable: true);
    final existingIndex = progress.indexWhere(
      (item) => item.situationId == situationId,
    );

    if (existingIndex >= 0) {
      final existing = progress[existingIndex];
      progress[existingIndex] = existing.copyWith(
        islandName: islandName,
        lessonTitle: lessonTitle,
        skillName: skillName,
        skillDescription: skillDescription,
        practicePrompt: practicePrompt,
        riskAlert: riskAlert,
        points: existing.points + points,
        completedCount: existing.completedCount + 1,
        lastCompletedAt: now,
      );
    } else {
      progress.add(
        SkillProgress(
          situationId: situationId,
          islandId: islandId,
          islandName: islandName,
          lessonTitle: lessonTitle,
          skillName: skillName,
          skillDescription: skillDescription,
          practicePrompt: practicePrompt,
          riskAlert: riskAlert,
          points: points,
          completedCount: 1,
          firstCompletedAt: now,
          lastCompletedAt: now,
        ),
      );
    }

    progress.sort((a, b) {
      final islandCompare = a.islandId.compareTo(b.islandId);
      if (islandCompare != 0) {
        return islandCompare;
      }

      return a.situationId.compareTo(b.situationId);
    });

    final updatedProfile = currentProfile.copyWith(skillProgress: progress);
    await saveProfile(updatedProfile);
    return updatedProfile;
  }

  Future<List<AppFeedbackEntry>> readAppFeedbackEntries() async {
    try {
      final content = await _storage.readString('app_feedback');
      if (content == null) {
        return const [];
      }

      final json = jsonDecode(content);
      if (json is! List) {
        return const [];
      }

      return json
          .whereType<Map<String, dynamic>>()
          .map(AppFeedbackEntry.fromJson)
          .toList(growable: false);
    } catch (error, stackTrace) {
      debugPrint('SmartSteps feedback read failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const [];
    }
  }

  Future<void> saveAppFeedback(AppFeedbackEntry feedback) async {
    final entries = await readAppFeedbackEntries();
    final updatedEntries = [...entries, feedback];
    const encoder = JsonEncoder.withIndent('  ');
    await _storage.writeString(
      'app_feedback',
      encoder.convert(
        updatedEntries.map((entry) => entry.toJson()).toList(growable: false),
      ),
    );

    final promptState = await readFeedbackPromptState();
    await _saveFeedbackPromptState(
      promptState.copyWith(
        hasSubmittedFeedback: true,
        lastFeedbackAt: feedback.submittedAt,
      ),
    );
  }

  Future<AppFeedbackPromptState> readFeedbackPromptState() async {
    try {
      final content = await _storage.readString('feedback_prompt_state');
      if (content == null) {
        return const AppFeedbackPromptState();
      }

      final json = jsonDecode(content);
      if (json is! Map<String, dynamic>) {
        return const AppFeedbackPromptState();
      }

      return AppFeedbackPromptState.fromJson(json);
    } catch (error, stackTrace) {
      debugPrint('SmartSteps feedback state read failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const AppFeedbackPromptState();
    }
  }

  Future<void> markFirstExitObserved() async {
    final promptState = await readFeedbackPromptState();
    if (promptState.hasObservedFirstExit) {
      return;
    }

    await _saveFeedbackPromptState(
      promptState.copyWith(
        hasObservedFirstExit: true,
        firstExitAt: DateTime.now(),
      ),
    );
  }

  Future<bool> shouldPromptFeedbackAfterFirstExit() async {
    final promptState = await readFeedbackPromptState();
    return promptState.hasObservedFirstExit &&
        !promptState.hasShownFirstExitPrompt &&
        !promptState.hasSubmittedFeedback;
  }

  Future<void> markFirstExitFeedbackPromptShown() async {
    final promptState = await readFeedbackPromptState();
    await _saveFeedbackPromptState(
      promptState.copyWith(
        hasShownFirstExitPrompt: true,
        firstPromptShownAt: DateTime.now(),
      ),
    );
  }

  Future<void> _saveFeedbackPromptState(
    AppFeedbackPromptState promptState,
  ) async {
    const encoder = JsonEncoder.withIndent('  ');
    await _storage.writeString(
      'feedback_prompt_state',
      encoder.convert(promptState.toJson()),
    );
  }
}

const premiumActivationCode = 'PREMIUM';

class PremiumActivationException implements Exception {
  const PremiumActivationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProfileStorageException implements Exception {
  const ProfileStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}
