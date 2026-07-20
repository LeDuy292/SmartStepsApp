import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smartsteps/main.dart';
import 'package:smartsteps/models/child_profile.dart';
import 'package:smartsteps/models/learning_analysis.dart';
import 'package:smartsteps/models/situation.dart';
import 'package:smartsteps/services/auth_service.dart';
import 'package:smartsteps/services/local_profile_storage.dart';
import 'package:smartsteps/services/learning_service.dart';
import 'package:smartsteps/services/situation_service.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

void main() {
  late _FakeVideoPlayerPlatform fakeVideoPlatform;
  late LocalProfileStorage profileStorage;

  setUp(() {
    fakeVideoPlatform = _FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = fakeVideoPlatform;
    profileStorage = _MemoryProfileStorage();
  });

  testWidgets('safe lesson flow uses injected lesson data', (tester) async {
    _setPhoneViewport(tester);
    final situationService = _FakeSituationService();
    expect(await profileStorage.hasProfile(), isFalse);

    await tester.pumpWidget(
      SmartStepsApp(
        situationService: situationService,
        profileStorage: profileStorage,
        authGateway: _FakeAuthGateway(),
        learningGateway: _FakeLearningGateway(),
        showPremiumOfferAfterLogin: false,
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await _login(tester);
    await _completeRegistration(tester);

    expect(situationService.detailCalls, 0);
    expect(find.byKey(const ValueKey('island-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('island-2')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('island-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const ValueKey('situation-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('situation-2')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('situation-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(situationService.detailCalls, 1);
    expect(find.text(_fakeSummary.title), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('situation-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('Bỏ qua intro'), findsOneWidget);
    expect(fakeVideoPlatform.playCalls, 0);

    await tester.tap(find.text('Bỏ qua intro'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text(_fakeFlashcard.question), findsOneWidget);

    await tester.tap(find.text(_fakeFlashcard.optionB));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Bỏ qua clip'), findsNothing);

    await tester.tap(find.text(_fakeFlashcard.optionB));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Bỏ qua clip'), findsOneWidget);

    await tester.tap(find.text('Bỏ qua clip'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Hoàn thành màn chơi!'), findsOneWidget);
    expect(find.text('+3 Safety Stars'), findsOneWidget);
    expect(find.text('+20 Xu'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('lesson-reward-continue-button')),
      findsOneWidget,
    );
    expect(find.text('Kid knows API safety! +1 Safety Star'), findsNothing);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('parent report shows skills and practice questions', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final situationService = _FakeSituationService();
    expect(await profileStorage.hasProfile(), isFalse);

    await tester.pumpWidget(
      SmartStepsApp(
        situationService: situationService,
        profileStorage: profileStorage,
        authGateway: _FakeAuthGateway(),
        learningGateway: _FakeLearningGateway(),
        showPremiumOfferAfterLogin: false,
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await _login(tester);
    await _completeRegistration(tester);

    expect(situationService.detailCalls, 0);

    await tester.tap(find.byKey(const ValueKey('learn-tab-button')));
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('parent-report-page')),
    );

    expect(find.byKey(const ValueKey('parent-report-page')), findsOneWidget);
    expect(situationService.detailCalls, 3);
    expect(find.textContaining('API Skill'), findsWidgets);

    await tester.drag(
      find.byKey(const ValueKey('parent-report-page')),
      const Offset(0, -900),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('What should the kid do?'), findsWidgets);
    expect(
      find.textContaining('Practice from API', findRichText: true),
      findsWidgets,
    );
    expect(
      find.textContaining('Risk from API', findRichText: true),
      findsWidgets,
    );
  });

  testWidgets('profile screen is shown from child tab only', (tester) async {
    _setPhoneViewport(tester);
    final situationService = _FakeSituationService();
    expect(await profileStorage.hasProfile(), isFalse);

    await tester.pumpWidget(
      SmartStepsApp(
        situationService: situationService,
        profileStorage: profileStorage,
        authGateway: _FakeAuthGateway(),
        learningGateway: _FakeLearningGateway(),
        showPremiumOfferAfterLogin: false,
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await _login(tester);
    await _completeRegistration(tester);

    await tester.tap(find.byKey(const ValueKey('learn-tab-button')));
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('parent-report-page')),
    );

    expect(find.byKey(const ValueKey('parent-report-page')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-screen')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('profile-tab-button')));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const ValueKey('profile-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('parent-report-page')), findsNothing);
    expect(find.text('Bé An'), findsWidgets);
    expect(find.text('6 tuổi'), findsWidgets);
    expect(find.text('Nam'), findsWidgets);
    expect(find.textContaining('Biết quan sát'), findsWidgets);
    expect(find.byKey(const ValueKey('profile-avatar-image')), findsOneWidget);
  });

  testWidgets('premium offer close button appears after delay', (tester) async {
    _setPhoneViewport(tester);
    final situationService = _FakeSituationService();
    expect(await profileStorage.hasProfile(), isFalse);

    await tester.pumpWidget(
      SmartStepsApp(
        situationService: situationService,
        profileStorage: profileStorage,
        authGateway: _FakeAuthGateway(),
        learningGateway: _FakeLearningGateway(),
        showPremiumOfferAfterLogin: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await _login(tester);
    await _completeRegistration(tester);

    final gateQuestion = tester.widget<Text>(
      find.byKey(const ValueKey('parental-gate-question')),
    );
    final factors = RegExp(
      r'(\d+)\s*x\s*(\d+)',
    ).firstMatch(gateQuestion.data ?? '');
    expect(factors, isNotNull);
    final answer = int.parse(factors!.group(1)!) * int.parse(factors.group(2)!);
    await tester.enterText(
      find.byKey(const ValueKey('parental-gate-answer-field')),
      '$answer',
    );
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    expect(find.text('SMARTSTEPS\nPREMIUM'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('premium-offer-close-button')),
      findsNothing,
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('premium-offer-close-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('premium-offer-close-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('island-1')), findsOneWidget);
  });
}

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _login(WidgetTester tester) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'child@example.com');
  await tester.enterText(fields.at(1), 'password123');
  await tester.tap(find.byKey(const ValueKey('login-submit-button')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}

Future<void> _completeRegistration(WidgetTester tester) async {
  expect(find.byKey(const ValueKey('registration-wizard')), findsOneWidget);
  await tester.enterText(
    find.byKey(const ValueKey('registration-name-field')),
    'Bé An',
  );
  await _tapRegistrationPrimary(tester);
  await tester.tap(find.byKey(const ValueKey('registration-age-6')));
  await _tapRegistrationPrimary(tester);
  await tester.tap(find.byKey(const ValueKey('registration-gender-Nam')));
  await _tapRegistrationPrimary(tester);
  await tester.tap(
    find.byKey(
      const ValueKey('registration-goal-Biết quan sát và đặt câu hỏi'),
    ),
  );
  await _tapRegistrationPrimary(tester);
  await tester.tap(
    find.byKey(const ValueKey('registration-avatar-avatars/cat.webp')),
  );
  await _tapRegistrationPrimary(tester);
  final termsToggle = find.byKey(const ValueKey('registration-terms-toggle'));
  await tester.ensureVisible(termsToggle);
  await tester.pump();
  await tester.tap(termsToggle);
  await tester.tap(find.text('Hoàn tất').last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _tapRegistrationPrimary(WidgetTester tester) async {
  await tester.tap(find.text('Tiếp tục').last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

final _fakeSummary = SituationSummary(
  situationId: 1,
  islandId: 1,
  islandName: 'API Island',
  title: 'API Lesson',
  intro: 'Loaded from backend API',
  orderIndex: 1,
  status: 'Published',
);

final _fakeIsland = IslandSummary(
  islandId: 1,
  name: 'API Island',
  orderIndex: 1,
  status: 'Active',
  situationCount: 2,
);

final _otherIsland = IslandSummary(
  islandId: 2,
  name: 'Another Island',
  orderIndex: 2,
  status: 'Active',
  situationCount: 1,
);

final _secondSummary = SituationSummary(
  situationId: 2,
  islandId: 1,
  islandName: 'API Island',
  title: 'Second API Lesson',
  intro: 'Same island lesson',
  orderIndex: 2,
  status: 'Published',
);

final _otherIslandSummary = SituationSummary(
  situationId: 3,
  islandId: 2,
  islandName: 'Another Island',
  title: 'Other Island Lesson',
  intro: 'Another island lesson',
  orderIndex: 1,
  status: 'Published',
);

final _fakeFlashcard = Flashcard(
  flashcardId: 1,
  question: 'What should the kid do?',
  optionA: 'Unsafe choice',
  optionB: 'Ask an adult',
  correctAnswer: 'B',
  correctFeedback: 'Correct from API',
  wrongFeedback: 'Wrong from API',
);

final _fakeDetail = SituationDetail(
  situationId: _fakeSummary.situationId,
  islandId: _fakeSummary.islandId,
  islandName: _fakeSummary.islandName,
  title: _fakeSummary.title,
  intro: _fakeSummary.intro,
  orderIndex: _fakeSummary.orderIndex,
  status: _fakeSummary.status,
  steps: const [
    SituationStep(
      stepId: 1,
      stepType: 'Intro',
      orderIndex: 1,
      content: 'Intro content from API.',
    ),
    SituationStep(
      stepId: 2,
      stepType: 'Flashcard',
      orderIndex: 2,
      content: 'Flashcard content from API.',
    ),
    SituationStep(
      stepId: 3,
      stepType: 'Story',
      orderIndex: 3,
      content: 'Wrong content from API.',
    ),
    SituationStep(
      stepId: 4,
      stepType: 'Result',
      orderIndex: 4,
      content:
          'Good outcome from API. Reward: Kid knows API safety! +1 Safety Star.',
    ),
  ],
  flashcard: _fakeFlashcard,
  skills: const [
    SituationSkill(
      skillId: 1,
      name: 'API Skill',
      description: 'API skill description',
    ),
  ],
  parentReview: const ParentReviewQuestion(
    questionId: 1,
    skillId: 1,
    questionText: 'Practice from API',
    suggestedActivity: 'Risk from API',
  ),
);

class _FakeSituationService extends SituationService {
  _FakeSituationService() : super(baseUrl: 'http://api.test');

  int detailCalls = 0;

  @override
  Future<List<IslandSummary>> getIslands() async => [_fakeIsland, _otherIsland];

  @override
  Future<List<SituationSummary>> getIslandSituations(int islandId) async {
    return switch (islandId) {
      1 => [_fakeSummary, _secondSummary],
      2 => [_otherIslandSummary],
      _ => const [],
    };
  }

  @override
  Future<SituationDetail> getSituationDetail(int situationId) async {
    detailCalls += 1;
    return _fakeDetail;
  }
}

class _FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  int _nextPlayerId = 1;
  int playCalls = 0;
  final Map<int, StreamController<VideoEvent>> _eventControllers = {};
  final Map<int, Duration> _positions = {};

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final playerId = _nextPlayerId++;
    final controller = StreamController<VideoEvent>.broadcast();
    _eventControllers[playerId] = controller;
    _positions[playerId] = Duration.zero;

    return playerId;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    scheduleMicrotask(() {
      _eventControllers[playerId]?.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 3),
          size: const Size(16, 9),
        ),
      );
    });

    return _eventControllers[playerId]!.stream;
  }

  @override
  Future<void> dispose(int playerId) async {
    await _eventControllers.remove(playerId)?.close();
    _positions.remove(playerId);
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {
    playCalls += 1;
    _eventControllers[playerId]?.add(
      VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: true,
      ),
    );
  }

  @override
  Future<void> pause(int playerId) async {
    _eventControllers[playerId]?.add(
      VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: false,
      ),
    );
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    _positions[playerId] = position;
  }

  @override
  Future<Duration> getPosition(int playerId) async {
    return _positions[playerId] ?? Duration.zero;
  }

  @override
  Widget buildViewWithOptions(VideoViewOptions options) {
    return ColoredBox(
      key: ValueKey('fake-video-${options.playerId}'),
      color: Colors.black,
    );
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
}

class _FakeAuthGateway implements AuthGateway {
  @override
  Future<void> ensureGoogleSignInInitialized() async {}

  @override
  Stream<GoogleSignInAccount?> get onGoogleUserChanged => const Stream.empty();

  @override
  Future<String?> processGoogleUser(GoogleSignInAccount googleUser) async =>
      null;

  @override
  Future<String?> login(String email, String password) async => null;

  @override
  Future<String?> loginWithGoogle() async => null;

  @override
  Future<void> logout() async {}

  @override
  Future<String?> getUserRole() async => 'Child';

  @override
  Future<bool> forgotPassword(String email) async => true;
}

class _FakeLearningGateway implements LearningGateway {
  @override
  Future<LearningAnalysis?> getLatestReport() {
    throw const LearningServiceException('Use local report data in tests.');
  }

  @override
  Future<LearningAnalysis> generateReport() {
    throw const LearningServiceException('Use local report data in tests.');
  }

  @override
  Future<void> completeSituation(int situationId) async {}

  @override
  Future<List<LearningRecommendation>> getRecommendations() async => const [];
}

class _MemoryProfileStorage extends LocalProfileStorage {
  ChildProfile? _profile;

  @override
  Future<bool> hasProfile() async => _profile != null;

  @override
  Future<ChildProfile?> readProfile() async => _profile;

  @override
  Future<void> saveProfile(ChildProfile profile) async {
    _profile = profile;
  }

  @override
  Future<bool> shouldPromptFeedbackAfterFirstExit() async => false;

  @override
  Future<void> markFirstExitObserved() async {}

  @override
  Future<void> markFirstExitFeedbackPromptShown() async {}

  @override
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
    final current = _profile;
    if (current == null) {
      throw const ProfileStorageException('Profile is required.');
    }

    final now = DateTime.now();
    final progress = SkillProgress(
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
    );
    _profile = current.copyWith(
      skillProgress: [...current.skillProgress, progress],
    );
    return _profile!;
  }
}
