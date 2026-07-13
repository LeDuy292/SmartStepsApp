import '../data/offline_situation_catalog.dart';
import '../models/situation.dart';

class SituationService {
  SituationService({String? baseUrl, Object? httpClient});

  bool get isEnabled => true;

  Future<List<IslandSummary>> getIslands() async {
    return offlineIslandSummaries;
  }

  Future<List<SituationSummary>> getSituations() async {
    return offlineSituationSummaries();
  }

  Future<List<SituationSummary>> getIslandSituations(int islandId) async {
    return offlineSituationSummariesForIsland(islandId);
  }

  Future<SituationDetail> getSituationDetail(int situationId) async {
    final detail = offlineSituationDetailById(situationId);
    if (detail == null) {
      throw StateError('Offline lesson $situationId was not found.');
    }

    return detail;
  }

  Future<SignedMediaUrl> createSignedMediaUrl(int stepId) async {
    throw const MediaConfigurationException(
      'Offline catalog uses bundled video assets.',
    );
  }

  Future<SignedMediaUrl> createSignedVoiceUrl(String mediaUrl) async {
    throw const MediaConfigurationException(
      'Offline catalog uses bundled voice assets.',
    );
  }
}

class MediaConfigurationException implements Exception {
  const MediaConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SignedMediaUrl {
  const SignedMediaUrl({required this.uri, required this.expiresAt});

  final Uri uri;
  final DateTime expiresAt;

  bool get isFresh {
    return expiresAt.isAfter(DateTime.now().add(const Duration(minutes: 1)));
  }
}
