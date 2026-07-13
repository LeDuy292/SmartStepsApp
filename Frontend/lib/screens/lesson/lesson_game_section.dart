part of '../home_screen.dart';

enum LessonPhase {
  introVideo,
  opening,
  inspectObject,
  miniChallenge,
  correctVideo,
  wrongVideo,
  wrong,
  parent,
}

enum ChoiceTone { safe, danger }

class GameColors {
  const GameColors._();

  static const cream = DuoColors.background;
  static const sky = Color(0xFFBFE9FF);
  static const mint = Color(0xFFB9F6D3);
  static const banana = DuoColors.primaryYellow;
  static const coral = Color(0xFFFF8A7A);
  static const safe = DuoColors.success;
  static const danger = Color(0xFFFFB347);
  static const ink = DuoColors.textPrimary;
  static const muted = DuoColors.textSecondary;
  static const paper = DuoColors.card;
}

class LessonAssets {
  const LessonAssets._();

  static const logo = 'assets/images/logo/logo smartstep-01.webp';
  static const islandBackground = 'assets/images/inslandBackground.webp';
  static const rootMapBackground = 'assets/images/land/screen.webp';
  static const landIsland1 = 'assets/images/land/bg-land-1.webp';
  static const landIsland2 = 'assets/images/land/bg-land-2.webp';
  static const landIsland3 = 'assets/images/land/bg-land-3.webp';
  static const rewardBackground = 'assets/images/land/reward.webp';
  static const falseBackground = 'assets/images/land/false.webp';
  static const island1Background = 'assets/images/Insland1_Background.webp';
  static const island2Background = 'assets/images/Insland2_Background.webp';
  static const island3Background = 'assets/images/Insland3_Background.webp';
  static const livingRoom = 'assets/images/living_room.webp';
  static const islandIcon = 'assets/images/Island_Icon.webp';
  static const kid = 'assets/images/kid.webp';
  static const childHappy = 'assets/images/child-happy.webp';
  static const childChoking = 'assets/images/child-choking.webp';
  static const mother = 'assets/images/mother.webp';
  static const ball = 'assets/images/ball.webp';
  static const mascot = 'assets/images/mascot/mascot-cat-happy.webp';
  static const mascotHappyWave =
      'assets/images/mascot/mascot-cat-happy-wave.webp';
  static const mascotSpeaking = 'assets/images/mascot/mascot-cat-speaking.webp';
  static const mascotSinging = 'assets/images/mascot/mascot-cat-singing.webp';
  static const mascotConfident =
      'assets/images/mascot/mascot-cat-confident.webp';
  static const mascotSulking = 'assets/images/mascot/mascot-cat-sulking.webp';
  static const rewardStar = 'assets/images/reward-star.webp';
}

class SafetyLesson {
  const SafetyLesson({
    required this.id,
    required this.situationId,
    required this.islandId,
    required this.islandName,
    required this.title,
    required this.topic,
    required this.ageRange,
    required this.sceneTitle,
    required this.mission,
    required this.openingHint,
    required this.inspectQuestion,
    required this.questionVoice,
    this.openingNarration,
    required this.videoIntro,
    required this.videoCorrect,
    required this.videoWrong,
    required this.wrongTitle,
    required this.wrongExplanation,
    required this.correctTitle,
    required this.correctExplanation,
    required this.learningGoals,
    required this.choices,
    required this.parentNotes,
  });

  final String id;
  final int situationId;
  final int islandId;
  final String islandName;
  final String title;
  final String topic;
  final String ageRange;
  final String sceneTitle;
  final String mission;
  final String openingHint;
  final String inspectQuestion;
  final LessonVoice questionVoice;
  final LessonOpeningNarration? openingNarration;
  final LessonVideoCopy videoIntro;
  final LessonVideoCopy videoCorrect;
  final LessonVideoCopy videoWrong;
  final String wrongTitle;
  final String wrongExplanation;
  final String correctTitle;
  final String correctExplanation;
  final List<String> learningGoals;
  final List<LessonChoice> choices;
  final ParentNotes parentNotes;
}

class LessonVideoCopy {
  const LessonVideoCopy({
    this.asset,
    this.stepId,
    required this.title,
    required this.caption,
    required this.actionLabel,
    required this.skipLabel,
  });

  final String? asset;
  final int? stepId;
  final String title;
  final String caption;
  final String actionLabel;
  final String skipLabel;
}

class LessonVoice {
  const LessonVoice({required this.asset, required this.text});

  final String asset;
  final String text;
}

class LessonOpeningNarration {
  const LessonOpeningNarration({required this.asset, required this.cues});

  final String asset;
  final List<LessonNarrationCue> cues;
}

class LessonNarrationCue {
  const LessonNarrationCue({required this.id, required this.duration});

  final String id;
  final Duration duration;
}

class LessonChoice {
  const LessonChoice({
    required this.id,
    required this.label,
    required this.helper,
    required this.accessibilityLabel,
    required this.imageAsset,
    required this.voice,
    required this.tone,
    required this.isCorrect,
  });

  final String id;
  final String label;
  final String helper;
  final String accessibilityLabel;
  final String imageAsset;
  final LessonVoice voice;
  final ChoiceTone tone;
  final bool isCorrect;
}

class ParentNotes {
  const ParentNotes({
    required this.skill,
    required this.practice,
    required this.risk,
  });

  final String skill;
  final String practice;
  final String risk;
}

SafetyLesson _lessonFromSituation(SituationDetail situation) {
  final introStep = _stepByType(situation, 'Intro');
  final flashcardStep = _stepByType(situation, 'Flashcard');
  final wrongStep = _stepByType(situation, 'Story');
  final correctStep = _stepByType(situation, 'Result');
  final flashcard = situation.flashcard;
  final question =
      flashcard?.question ??
      flashcardStep?.content ??
      situation.intro ??
      situation.title;
  final correctAnswer = flashcard?.correctAnswer.toUpperCase() ?? 'B';
  final choiceAId = correctAnswer == 'A' ? correctChoiceId : 'option-a';
  final choiceBId = correctAnswer == 'B' ? correctChoiceId : 'option-b';
  final skill = situation.skills.isNotEmpty ? situation.skills.first : null;
  final parentReview = situation.parentReview;

  return SafetyLesson(
    id: 'situation-${situation.situationId}',
    situationId: situation.situationId,
    islandId: situation.islandId,
    islandName: situation.islandName,
    title: situation.title,
    topic: skill?.name ?? situation.islandName,
    ageRange: '4-9 tuổi',
    sceneTitle: situation.islandName,
    mission:
        situation.intro ?? _shortCopy(introStep?.content) ?? situation.title,
    openingHint: 'Bấm vào tình huống',
    inspectQuestion: question,
    questionVoice: LessonVoice(
      asset: flashcard?.questionVoiceUrl ?? '',
      text: question,
    ),
    openingNarration: _openingNarrationFor(
      questionVoice: flashcard?.questionVoiceUrl,
      optionAVoice: flashcard?.optionAVoiceUrl,
      optionBVoice: flashcard?.optionBVoiceUrl,
      choiceAId: choiceAId,
      choiceBId: choiceBId,
    ),
    videoIntro: _videoCopyFromStep(
      step: introStep,
      title: 'Cùng xem tình huống',
      caption: introStep?.content ?? situation.intro ?? situation.title,
      actionLabel: 'Bắt đầu intro',
      skipLabel: 'Bỏ qua intro',
    ),
    videoCorrect: _videoCopyFromStep(
      step: correctStep,
      title: 'Cách xử lý an toàn',
      caption: correctStep?.content ?? flashcard?.correctFeedback ?? '',
      actionLabel: 'Xem kết quả đúng',
      skipLabel: 'Bỏ qua clip',
    ),
    videoWrong: _videoCopyFromStep(
      step: wrongStep,
      title: 'Dừng lại và sửa lựa chọn',
      caption: wrongStep?.content ?? flashcard?.wrongFeedback ?? '',
      actionLabel: 'Xem kết quả sai',
      skipLabel: 'Bỏ qua clip',
    ),
    wrongTitle: 'Chưa an toàn!',
    wrongExplanation:
        _kidWarningCopy(flashcard?.wrongFeedback ?? wrongStep?.content) ??
        'Dừng lại. Chọn cách an toàn hơn.',
    correctTitle: 'Con làm đúng rồi!',
    correctExplanation:
        flashcard?.correctFeedback ?? _shortCopy(correctStep?.content) ?? '',
    learningGoals: _learningGoalsFor(situation),
    choices: [
      _choiceFromFlashcard(
        id: choiceAId,
        label: flashcard?.optionA ?? 'Lựa chọn A',
        voiceUrl: flashcard?.optionAVoiceUrl,
        imageAsset: flashcard?.optionAImageUrl,
        isCorrect: correctAnswer == 'A',
      ),
      _choiceFromFlashcard(
        id: choiceBId,
        label: flashcard?.optionB ?? 'Lựa chọn B',
        voiceUrl: flashcard?.optionBVoiceUrl,
        imageAsset: flashcard?.optionBImageUrl,
        isCorrect: correctAnswer == 'B',
      ),
    ],
    parentNotes: ParentNotes(
      skill: skill?.description ?? situation.intro ?? situation.title,
      practice:
          parentReview?.questionText ??
          'Cùng bé nhắc lại lựa chọn an toàn trong tình huống này.',
      risk:
          parentReview?.suggestedActivity ??
          'Quan sát phản ứng của bé và luyện tập lại khi bé còn phân vân.',
    ),
  );
}

SituationStep? _stepByType(SituationDetail situation, String stepType) {
  for (final step in situation.steps) {
    if (step.stepType.toLowerCase() == stepType.toLowerCase()) {
      return step;
    }
  }

  return null;
}

LessonVideoCopy _videoCopyFromStep({
  required SituationStep? step,
  required String title,
  required String caption,
  required String actionLabel,
  required String skipLabel,
}) {
  return LessonVideoCopy(
    stepId: step?.stepId,
    asset: step?.mediaUrl,
    title: title,
    caption: caption,
    actionLabel: actionLabel,
    skipLabel: skipLabel,
  );
}

LessonChoice _choiceFromFlashcard({
  required String id,
  required String label,
  required String? voiceUrl,
  required String? imageAsset,
  required bool isCorrect,
}) {
  return LessonChoice(
    id: id,
    label: label,
    helper: isCorrect ? 'An toàn' : 'Không an toàn',
    accessibilityLabel: '$label. ${isCorrect ? 'An toàn.' : 'Không an toàn.'}',
    imageAsset:
        imageAsset ??
        (isCorrect ? LessonAssets.mother : LessonAssets.childChoking),
    voice: LessonVoice(asset: voiceUrl ?? '', text: label),
    tone: isCorrect ? ChoiceTone.safe : ChoiceTone.danger,
    isCorrect: isCorrect,
  );
}

LessonOpeningNarration? _openingNarrationFor({
  required String? questionVoice,
  required String? optionAVoice,
  required String? optionBVoice,
  required String choiceAId,
  required String choiceBId,
}) {
  final key = [questionVoice, optionAVoice, optionBVoice].join('|');
  final cues = <LessonNarrationCue>[
    LessonNarrationCue(
      id: 'question',
      duration: _combinedQuestionDurationFor(key),
    ),
    LessonNarrationCue(
      id: choiceAId,
      duration: _combinedChoiceADurationFor(key),
    ),
    LessonNarrationCue(
      id: choiceBId,
      duration: _combinedChoiceBDurationFor(key),
    ),
  ];

  return switch (key) {
    'assets/voices/Safety_smallitems/question.mp3|assets/voices/Safety_smallitems/choice-put-mouth.mp3|assets/voices/Safety_smallitems/choice-ask-adult.mp3' =>
      LessonOpeningNarration(
        asset: 'assets/voices/Safety_smallitems/opening-narration.m4a',
        cues: cues,
      ),
    'assets/voices/Safety_stranger/question_l3.mp3|assets/voices/Safety_stranger/wrong_l3.mp3|assets/voices/Safety_stranger/correct_l3.mp3' =>
      LessonOpeningNarration(
        asset: 'assets/voices/Safety_stranger/opening-narration.m4a',
        cues: cues,
      ),
    'assets/voices/Crossroad/Question.mp3|assets/voices/Crossroad/wrong.mp3|assets/voices/Crossroad/correct.mp3' =>
      LessonOpeningNarration(
        asset: 'assets/voices/Crossroad/opening-narration.m4a',
        cues: cues,
      ),
    _ => null,
  };
}

Duration _combinedQuestionDurationFor(String key) {
  return switch (key) {
    'assets/voices/Safety_smallitems/question.mp3|assets/voices/Safety_smallitems/choice-put-mouth.mp3|assets/voices/Safety_smallitems/choice-ask-adult.mp3' =>
      const Duration(milliseconds: 3240),
    'assets/voices/Safety_stranger/question_l3.mp3|assets/voices/Safety_stranger/wrong_l3.mp3|assets/voices/Safety_stranger/correct_l3.mp3' =>
      const Duration(milliseconds: 2660),
    'assets/voices/Crossroad/Question.mp3|assets/voices/Crossroad/wrong.mp3|assets/voices/Crossroad/correct.mp3' =>
      const Duration(milliseconds: 2490),
    _ => _questionFallbackDuration,
  };
}

Duration _combinedChoiceADurationFor(String key) {
  return switch (key) {
    'assets/voices/Safety_smallitems/question.mp3|assets/voices/Safety_smallitems/choice-put-mouth.mp3|assets/voices/Safety_smallitems/choice-ask-adult.mp3' =>
      const Duration(milliseconds: 1370),
    'assets/voices/Safety_stranger/question_l3.mp3|assets/voices/Safety_stranger/wrong_l3.mp3|assets/voices/Safety_stranger/correct_l3.mp3' =>
      const Duration(milliseconds: 3070),
    'assets/voices/Crossroad/Question.mp3|assets/voices/Crossroad/wrong.mp3|assets/voices/Crossroad/correct.mp3' =>
      const Duration(milliseconds: 1630),
    _ => _choiceFallbackDuration,
  };
}

Duration _combinedChoiceBDurationFor(String key) {
  return switch (key) {
    'assets/voices/Safety_smallitems/question.mp3|assets/voices/Safety_smallitems/choice-put-mouth.mp3|assets/voices/Safety_smallitems/choice-ask-adult.mp3' =>
      const Duration(milliseconds: 940),
    'assets/voices/Safety_stranger/question_l3.mp3|assets/voices/Safety_stranger/wrong_l3.mp3|assets/voices/Safety_stranger/correct_l3.mp3' =>
      const Duration(milliseconds: 3580),
    'assets/voices/Crossroad/Question.mp3|assets/voices/Crossroad/wrong.mp3|assets/voices/Crossroad/correct.mp3' =>
      const Duration(milliseconds: 1180),
    _ => _choiceFallbackDuration,
  };
}

List<String> _learningGoalsFor(SituationDetail situation) {
  final goals = situation.skills
      .map((skill) => skill.description ?? skill.name)
      .where((goal) => goal.trim().isNotEmpty)
      .toList(growable: false);

  if (goals.isNotEmpty) {
    return goals;
  }

  return [situation.intro ?? situation.title];
}

String? _shortCopy(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) {
    return null;
  }

  return text.length <= 220 ? text : '${text.substring(0, 217)}...';
}

String? _kidWarningCopy(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) {
    return null;
  }

  final normalized = text.replaceAll(RegExp(r'\s+'), ' ');
  final sentenceEnd = normalized.indexOf(RegExp(r'[.!?。]'));
  final firstSentence = sentenceEnd > 0
      ? normalized.substring(0, sentenceEnd + 1)
      : normalized;
  if (firstSentence.length <= 86) {
    return firstSentence;
  }

  final short = firstSentence.substring(0, 83).trimRight();
  return '$short...';
}

const correctChoiceId = 'ask-adult';
const _voicePlaybackRate = 0.82;
const _voiceVolume = 0.82;
const _iosWebVoiceVolume = 0.68;
const _lessonVideoVolume = 0.86;
const _iosWebLessonVideoVolume = 0.74;
const _voicePlaybackTimeout = Duration(seconds: 12);
const _voiceStartTimeout = Duration(milliseconds: 4000);
const _voiceSequenceGap = Duration(milliseconds: 360);
const _questionFallbackDuration = Duration(milliseconds: 3600);
const _choiceFallbackDuration = Duration(milliseconds: 2300);
const _voiceCompletionGrace = Duration(milliseconds: 420);
const _iosWebVoiceSequenceGap = Duration(milliseconds: 760);
const _iosWebChoiceFallbackDuration = Duration(milliseconds: 3400);
const _outsidePortraitOrientations = [
  DeviceOrientation.portraitUp,
  DeviceOrientation.portraitDown,
];
const _lessonLandscapeOrientations = [
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];
final _voiceAudioContext = AudioContext(
  android: const AudioContextAndroid(
    contentType: AndroidContentType.speech,
    usageType: AndroidUsageType.media,
    audioFocus: AndroidAudioFocus.none,
  ),
  iOS: AudioContextIOS(
    category: AVAudioSessionCategory.playback,
    options: const {AVAudioSessionOptions.mixWithOthers},
  ),
);

final _mediaResolver = _BackendMediaResolver(SituationService());
Future<Set<String>>? _lessonAssetManifestPaths;

String _voiceAssetPath(String asset) {
  const assetsPrefix = 'assets/';
  return asset.startsWith(assetsPrefix)
      ? asset.substring(assetsPrefix.length)
      : asset;
}

Future<bool> _lessonAssetExists(String asset) async {
  final normalizedAsset = asset.trim();
  if (normalizedAsset.isEmpty) {
    return false;
  }

  final manifestPaths = _lessonAssetManifestPaths ??=
      AssetManifest.loadFromAssetBundle(
        rootBundle,
      ).then((manifest) => manifest.listAssets().toSet());
  return (await manifestPaths).contains(normalizedAsset);
}

class _BackendMediaResolver {
  _BackendMediaResolver(this._situationService);

  final SituationService _situationService;
  final Map<int, SignedMediaUrl> _signedUrlCache = {};
  final Map<String, SignedMediaUrl> _signedVoiceUrlCache = {};

  Future<Uri?> signedVideoUrlFor(LessonVideoCopy copy) async {
    final stepId = copy.stepId;
    if (stepId == null || copy.asset == null || copy.asset!.trim().isEmpty) {
      return null;
    }
    final asset = copy.asset!.trim();
    if (asset.startsWith('assets/')) {
      return null;
    }

    // Direct public URL (e.g. Cloudinary) — no backend signing needed.
    if (asset.startsWith('http://') || asset.startsWith('https://')) {
      return Uri.parse(asset);
    }

    if (!_situationService.isEnabled) {
      throw const MediaConfigurationException(
        'SMARTSTEPS_API_BASE_URL is not configured.',
      );
    }

    final cachedUrl = _signedUrlCache[stepId];
    if (cachedUrl != null && cachedUrl.isFresh) {
      return cachedUrl.uri;
    }

    final signedUrl = await _situationService.createSignedMediaUrl(stepId);
    _signedUrlCache[stepId] = signedUrl;
    return signedUrl.uri;
  }

  Future<Uri?> signedVoiceUrlFor(String asset) async {
    final mediaUrl = asset.trim();
    if (mediaUrl.isEmpty || mediaUrl.startsWith('assets/')) {
      return null;
    }

    if (!_situationService.isEnabled) {
      throw const MediaConfigurationException(
        'SMARTSTEPS_API_BASE_URL is not configured.',
      );
    }

    final cachedUrl = _signedVoiceUrlCache[mediaUrl];
    if (cachedUrl != null && cachedUrl.isFresh) {
      return cachedUrl.uri;
    }

    final signedUrl = await _situationService.createSignedVoiceUrl(mediaUrl);
    _signedVoiceUrlCache[mediaUrl] = signedUrl;
    return signedUrl.uri;
  }
}

class LessonGameScreen extends StatefulWidget {
  const LessonGameScreen({
    super.key,
    required this.lesson,
    this.profileStorage,
    this.onLessonCompleted,
    required this.isLastLesson,
    this.onNextLesson,
    this.onCompleteIsland,
  });

  final SafetyLesson lesson;
  final LocalProfileStorage? profileStorage;
  final ValueChanged<ChildProfile>? onLessonCompleted;
  final bool isLastLesson;
  final VoidCallback? onNextLesson;
  final VoidCallback? onCompleteIsland;

  @override
  State<LessonGameScreen> createState() => _LessonGameScreenState();
}

class _LessonGameScreenState extends State<LessonGameScreen> {
  late LessonPhase _phase;
  String? _selectedChoiceId;
  bool _parentReadingMode = false;
  bool _hasRecordedCompletion = false;
  SmartStepsAudioController? _audioController;

  bool get _usesTemplateLesson => widget.lesson.islandId >= 2;

  LessonChoice? get _selectedChoice {
    for (final choice in widget.lesson.choices) {
      if (choice.id == _selectedChoiceId) {
        return choice;
      }
    }
    return null;
  }

  bool get _isVideoPhase {
    return _phase == LessonPhase.introVideo ||
        _phase == LessonPhase.correctVideo ||
        _phase == LessonPhase.wrongVideo;
  }

  bool get _isResultFocusPhase {
    return _phase == LessonPhase.wrong;
  }

  @override
  void initState() {
    super.initState();
    _phase = _initialLessonPhase;
    unawaited(_enterLessonViewingMode());
  }

  LessonPhase get _initialLessonPhase {
    return _usesTemplateLesson ? LessonPhase.opening : LessonPhase.introVideo;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextAudioController = SmartStepsAudioScope.maybeOf(context);
    if (_audioController == nextAudioController) {
      return;
    }

    _audioController?.restoreMusic();
    _audioController = nextAudioController;
    _audioController?.duckMusic();
  }

  @override
  void dispose() {
    _audioController?.stopCelebration();
    _audioController?.restoreMusic();
    unawaited(_restoreSystemViewingMode());
    super.dispose();
  }

  Future<void> _enterLessonViewingMode() async {
    try {
      if (_usesTemplateLesson) {
        await SystemChrome.setPreferredOrientations(
          _outsidePortraitOrientations,
        );
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } else {
        await SystemChrome.setPreferredOrientations(
          _lessonLandscapeOrientations,
        );
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    } catch (_) {
      // Orientation and fullscreen APIs are unavailable on some test/desktop hosts.
    }
  }

  Future<void> _restoreSystemViewingMode() async {
    try {
      await SystemChrome.setPreferredOrientations(_outsidePortraitOrientations);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (_) {
      // Keep dispose best-effort so platform limitations do not break teardown.
    }
  }

  void _restartLesson() {
    _audioController?.stopCelebration();
    setState(() {
      _selectedChoiceId = null;
      _hasRecordedCompletion = false;
      _phase = _initialLessonPhase;
    });
  }

  void _toggleReadingMode() {
    setState(() {
      _parentReadingMode = !_parentReadingMode;
    });
  }

  void _exitLesson() {
    _audioController?.stopCelebration();
    Navigator.of(context).maybePop();
  }

  void _completeVideo() {
    var shouldPlayWarning = false;
    var shouldShowReward = false;

    setState(() {
      switch (_phase) {
        case LessonPhase.introVideo:
          _phase = LessonPhase.inspectObject;
        case LessonPhase.correctVideo:
          _phase = _usesTemplateLesson
              ? LessonPhase.miniChallenge
              : LessonPhase.parent;
          shouldShowReward = !_usesTemplateLesson;
        case LessonPhase.wrongVideo:
          _phase = LessonPhase.wrong;
          shouldPlayWarning = true;
        case LessonPhase.opening:
        case LessonPhase.inspectObject:
        case LessonPhase.miniChallenge:
        case LessonPhase.wrong:
        case LessonPhase.parent:
          break;
      }
    });

    if (shouldPlayWarning) {
      _audioController?.playWarning();
    }
    if (shouldShowReward) {
      _showReward();
    }
  }

  void _inspectObject() {
    if (_phase != LessonPhase.opening) {
      return;
    }
    setState(() {
      _phase = LessonPhase.inspectObject;
    });
  }

  void _selectChoice(String choiceId) {
    final selectedChoice = widget.lesson.choices.firstWhere(
      (choice) => choice.id == choiceId,
      orElse: () => widget.lesson.choices.last,
    );

    if (!selectedChoice.isCorrect) {
      unawaited(HapticFeedback.mediumImpact());
    }

    setState(() {
      _selectedChoiceId = choiceId;
      _phase = selectedChoice.isCorrect
          ? LessonPhase.correctVideo
          : LessonPhase.wrongVideo;
    });
  }

  void _completeMiniChallenge() {
    setState(() {
      _phase = LessonPhase.parent;
    });
    _showReward();
  }

  void _retryChoice() {
    _audioController?.stopCelebration();
    setState(() {
      _selectedChoiceId = null;
      _phase = LessonPhase.inspectObject;
    });
  }

  void _showReward() {
    _audioController?.stopCelebration();
    if (!_hasRecordedCompletion) {
      _hasRecordedCompletion = true;
      unawaited(_recordLessonCompletion());
    }
    _audioController?.playSuccess();
    _audioController?.playCelebration(maxDuration: const Duration(seconds: 3));
  }

  Future<void> _recordLessonCompletion() async {
    final profileStorage = widget.profileStorage;
    if (profileStorage == null) {
      return;
    }

    try {
      final lesson = widget.lesson;
      final profile = await profileStorage.recordLessonCompletion(
        situationId: lesson.situationId,
        islandId: lesson.islandId,
        islandName: lesson.islandName,
        lessonTitle: lesson.title,
        skillName: lesson.topic,
        skillDescription: lesson.parentNotes.skill,
        practicePrompt: lesson.parentNotes.practice,
        riskAlert: lesson.parentNotes.risk,
      );

      widget.onLessonCompleted?.call(profile);

      // Track lesson completion event in GA4
      AnalyticsService.trackEvent('complete_lesson', {
        'lesson_id': lesson.situationId,
        'lesson_title': lesson.title,
        'lesson_topic': lesson.topic,
        'island_name': lesson.islandName,
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cộng +1 điểm kỹ năng ${lesson.topic}.')),
      );
    } catch (error, stackTrace) {
      debugPrint('SmartSteps lesson completion save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final isFlashcardPhase = _phase == LessonPhase.inspectObject;
    final showFullHeader = !isFlashcardPhase && !_isResultFocusPhase;

    if (_usesTemplateLesson && _phase == LessonPhase.opening) {
      return _TemplateObserveScreen(
        lesson: lesson,
        onBack: _exitLesson,
        onContinue: () {
          setState(() {
            _phase = LessonPhase.introVideo;
          });
        },
      );
    }

    if (_usesTemplateLesson && _phase == LessonPhase.miniChallenge) {
      return _TemplateMiniChallengeScreen(
        lesson: lesson,
        onBack: _exitLesson,
        onContinue: _completeMiniChallenge,
      );
    }

    if (_isVideoPhase) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: _buildStage(lesson)),
            Positioned(
              left: 14,
              top: 14,
              child: SafeArea(child: _LessonExitButton(onPressed: _exitLesson)),
            ),
          ],
        ),
      );
    }

    if (_phase == LessonPhase.parent) {
      return Scaffold(
        body: _LessonRewardCelebration(
          lesson: lesson,
          onContinue: _exitLesson,
          onHome: _exitLesson,
          onReplay: _restartLesson,
          onClose: _exitLesson,
          isLastLesson: widget.isLastLesson,
          onNextLesson: widget.onNextLesson,
          onCompleteIsland: widget.onCompleteIsland,
        ),
      );
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF1B5), GameColors.cream, Color(0xFFE4F7FF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showFullHeader) ...[
                  _GameHeader(
                    lesson: lesson,
                    isParentReadingMode: _parentReadingMode,
                    onToggleReadingMode: _toggleReadingMode,
                    onRestart: _restartLesson,
                    onExit: _exitLesson,
                  ),
                  const SizedBox(height: 10),
                ],
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (!isFlashcardPhase)
                        Positioned.fill(child: _buildStage(lesson)),

                      if (_phase == LessonPhase.wrong)
                        _WrongFeedbackOverlay(
                          title: lesson.wrongTitle,
                          body: lesson.wrongExplanation,
                          actionLabel: 'Thử lại',
                          onAction: _retryChoice,
                          onRestart: _retryChoice,
                          onClose: _exitLesson,
                        ),
                      if (_phase == LessonPhase.inspectObject)
                        _QuestionOverlay(
                          lesson: lesson,
                          selectedChoice: _selectedChoice,
                          isParentReadingMode: _parentReadingMode,
                          onSelectChoice: _selectChoice,
                        ),
                      if (isFlashcardPhase)
                        Positioned(
                          left: 0,
                          top: 0,
                          child: _LessonExitButton(onPressed: _exitLesson),
                        ),

                      if (_isResultFocusPhase && _phase != LessonPhase.wrong)
                        _CompactLessonControls(
                          onRestart: _restartLesson,
                          onExit: _exitLesson,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStage(SafetyLesson lesson) {
    switch (_phase) {
      case LessonPhase.introVideo:
        return _StoryClipStage(
          key: const ValueKey('intro-video'),
          copy: lesson.videoIntro,
          variant: LessonPhase.introVideo,
          onFinished: _completeVideo,
        );
      case LessonPhase.correctVideo:
        return _StoryClipStage(
          key: const ValueKey('correct-video'),
          copy: lesson.videoCorrect,
          variant: LessonPhase.correctVideo,
          onFinished: _completeVideo,
        );
      case LessonPhase.wrongVideo:
        return _StoryClipStage(
          key: const ValueKey('wrong-video'),
          copy: lesson.videoWrong,
          variant: LessonPhase.wrongVideo,
          onFinished: _completeVideo,
        );
      case LessonPhase.opening:
      case LessonPhase.inspectObject:
      case LessonPhase.miniChallenge:
      case LessonPhase.wrong:
      case LessonPhase.parent:
        return _SceneStage(
          lesson: lesson,
          phase: _phase,
          onInspectObject: _inspectObject,
        );
    }
  }
}

class _TemplateObserveItem {
  const _TemplateObserveItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.alignment,
  });

  final String id;
  final String label;
  final IconData icon;
  final Alignment alignment;
}

class _TemplateObserveSceneConfig {
  const _TemplateObserveSceneConfig({
    required this.backgroundAsset,
    required this.items,
  });

  final String backgroundAsset;
  final List<_TemplateObserveItem> items;
}

class _TemplateObserveScreen extends StatefulWidget {
  const _TemplateObserveScreen({
    required this.lesson,
    required this.onBack,
    required this.onContinue,
  });

  final SafetyLesson lesson;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  State<_TemplateObserveScreen> createState() => _TemplateObserveScreenState();
}

class _MiniChallengeStep {
  const _MiniChallengeStep({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
    this.imagePath,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final Color background;
  final String? imagePath;
}

class _TemplateMiniChallengeScreen extends StatefulWidget {
  const _TemplateMiniChallengeScreen({
    required this.lesson,
    required this.onBack,
    required this.onContinue,
  });

  final SafetyLesson lesson;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  State<_TemplateMiniChallengeScreen> createState() =>
      _TemplateMiniChallengeScreenState();
}

class _TemplateMiniChallengeScreenState
    extends State<_TemplateMiniChallengeScreen> {
  late final List<_MiniChallengeStep> _steps = _miniChallengeStepsFor(
    widget.lesson,
  );
  late final List<_MiniChallengeStep> _options = _miniChallengeOptionsFor(
    _steps,
  );
  final List<String> _selectedIds = <String>[];
  bool _hasChecked = false;
  bool _showHint = false;

  late final AudioPlayer _instructionPlayer;

  @override
  void initState() {
    super.initState();
    _instructionPlayer = AudioPlayer();
    _playInstruction();
  }

  Future<void> _playInstruction() async {
    try {
      await _instructionPlayer.play(AssetSource('voices/voice_intro_minigame_arrange.mp3'));
    } catch (e) {
      debugPrint('Error playing minigame arrange instruction voice: $e');
    }
  }

  @override
  void dispose() {
    _instructionPlayer.dispose();
    super.dispose();
  }

  bool get _canCheck => _selectedIds.length == _steps.length;

  bool get _isCorrect {
    if (!_canCheck) {
      return false;
    }
    for (var index = 0; index < _steps.length; index += 1) {
      if (_selectedIds[index] != _steps[index].id) {
        return false;
      }
    }
    return true;
  }

  void _selectStep(_MiniChallengeStep step) {
    setState(() {
      if (_selectedIds.contains(step.id)) {
        _selectedIds.remove(step.id);
      } else {
        if (_selectedIds.length < _steps.length) {
          _selectedIds.add(step.id);
        }
      }
      _hasChecked = false;
      _showHint = false;
    });
  }

  void _showHintMessage() {
    setState(() {
      _showHint = true;
    });
  }

  void _checkAnswer() {
    if (!_canCheck) {
      _showHintMessage();
      return;
    }
    setState(() {
      _hasChecked = true;
      _showHint = false;
    });
    if (_isCorrect) {
      unawaited(HapticFeedback.lightImpact());
      _playCorrectArrangeVoice();
    } else {
      unawaited(HapticFeedback.mediumImpact());
    }
  }

  Future<void> _playCorrectArrangeVoice() async {
    try {
      await _instructionPlayer.stop();
    } catch (_) {}

    final text = '${widget.lesson.title} ${widget.lesson.mission} ${widget.lesson.topic}'
        .toLowerCase();
    String fileName;
    if (text.contains('người lạ')) {
      fileName = 'voice_correct_arrange_stranger.mp3';
    } else if (text.contains('qua đường') || text.contains('giao thông')) {
      fileName = 'voice_correct_arrange_traffic.mp3';
    } else {
      fileName = 'voice_correct_arrange_default.mp3';
    }

    try {
      await _instructionPlayer.play(AssetSource('voices/$fileName'));
    } catch (e) {
      debugPrint('Error playing correct arrange voice summary: $e');
    }
  }

  void _tryAgain() {
    setState(() {
      _selectedIds.clear();
      _hasChecked = false;
      _showHint = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedbackText = _feedbackText;
    final feedbackColor = _hasChecked && !_isCorrect
        ? const Color(0xFF8B5000)
        : GameColors.ink;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 380;
            final horizontalPadding = compact ? 18.0 : 24.0;
            final isWrong = _hasChecked && !_isCorrect;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TemplateObserveHeader(
                  title: widget.lesson.title,
                  onBack: widget.onBack,
                  progressLabel: '3/5',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      18,
                      horizontalPadding,
                      16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Sắp xếp 3 bước an toàn',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: GameColors.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const SizedBox(height: 18),
                        for (final step in _options) ...[
                          Builder(builder: (context) {
                            final selIndex = _selectedIds.indexOf(step.id);
                            final selectedNumber = selIndex != -1 ? selIndex + 1 : null;
                            
                            final correctIndex = _steps.indexWhere((item) => item.id == step.id);
                            final isCorrectPosition = _hasChecked && selectedNumber != null
                                ? selIndex == correctIndex
                                : null;

                            return _MiniChallengeStepButton(
                              step: step,
                              isSelected: selectedNumber != null,
                              selectedIndex: selectedNumber,
                              isCorrectPosition: isCorrectPosition,
                              onPressed: () => _selectStep(step),
                            );
                          }),
                          const SizedBox(height: 12),
                        ],
                        if (!isWrong)
                          _MiniChallengeFeedback(
                            text: feedbackText,
                            color: feedbackColor,
                            showRetry: false,
                            onRetry: _tryAgain,
                          ),
                      ],
                    ),
                  ),
                ),
                _MiniChallengeActions(
                  canCheck: _canCheck,
                  isCorrect: _hasChecked && _isCorrect,
                  showRetry: isWrong,
                  onRetry: _tryAgain,
                  onHint: _showHintMessage,
                  onCheck: _checkAnswer,
                  onContinue: widget.onContinue,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String get _feedbackText {
    if (_showHint) {
      return 'Gợi ý: bắt đầu bằng việc dừng lại và nhìn cho kỹ.';
    }
    if (!_hasChecked) {
      return _selectedIds.isEmpty
          ? 'Con chọn bước đầu tiên nhé.'
          : 'Tốt rồi, chọn tiếp bước sau.';
    }
    if (_isCorrect) {
      return 'Đúng thứ tự rồi. Con đã sẵn sàng nhận thưởng.';
    }
    return 'Gần đúng rồi. Mình thử sắp xếp lại nhé.';
  }
}

class _MiniChallengeStepButton extends StatelessWidget {
  const _MiniChallengeStepButton({
    required this.step,
    required this.isSelected,
    required this.selectedIndex,
    required this.isCorrectPosition,
    required this.onPressed,
  });

  final _MiniChallengeStep step;
  final bool isSelected;
  final int? selectedIndex;
  final bool? isCorrectPosition;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SmartStepsPressEffect(
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: isCorrectPosition == true
                  ? const Color(0xFFE1F8DD)
                  : isCorrectPosition == false
                  ? const Color(0xFFFFDAD6)
                  : isSelected
                  ? step.background
                  : Colors.white,
              side: BorderSide(
                color: isCorrectPosition == true
                    ? const Color(0xFF006E1C)
                    : isCorrectPosition == false
                    ? const Color(0xFF93000A)
                    : isSelected
                    ? step.color
                    : step.color.withValues(alpha: 0.35),
                width: isSelected ? 3.5 : 2.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 128,
                    color: isSelected ? const Color(0xFFDCDAD0) : step.background,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (step.imagePath != null)
                          Image.asset(
                            step.imagePath!,
                            fit: BoxFit.cover,
                          )
                        else
                          Center(
                            child: Icon(
                              step.icon,
                              color: step.color,
                              size: 40,
                            ),
                          ),
                        if (isCorrectPosition == true)
                          Container(
                            color: const Color(0x1A006E1C),
                          )
                        else if (isCorrectPosition == false)
                          Container(
                            color: const Color(0x1A93000A),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    child: Text(
                      step.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCorrectPosition == true
                            ? const Color(0xFF006E1C)
                            : isCorrectPosition == false
                            ? const Color(0xFF93000A)
                            : step.color,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (selectedIndex != null)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCorrectPosition == true
                    ? const Color(0xFF006E1C)
                    : isCorrectPosition == false
                    ? const Color(0xFF93000A)
                    : step.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$selectedIndex',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniChallengeFeedback extends StatelessWidget {
  const _MiniChallengeFeedback({
    required this.text,
    required this.color,
    required this.showRetry,
    required this.onRetry,
  });

  final String text;
  final Color color;
  final bool showRetry;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4E3DB)),
      ),
      child: Row(
        children: [
          Icon(Icons.tips_and_updates_rounded, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                height: 1.18,
              ),
            ),
          ),
          if (showRetry) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: onRetry, child: const Text('Làm lại')),
          ],
        ],
      ),
    );
  }
}

class _MiniChallengeActions extends StatelessWidget {
  const _MiniChallengeActions({
    required this.canCheck,
    required this.isCorrect,
    required this.showRetry,
    required this.onRetry,
    required this.onHint,
    required this.onCheck,
    required this.onContinue,
  });

  final bool canCheck;
  final bool isCorrect;
  final bool showRetry;
  final VoidCallback onRetry;
  final VoidCallback onHint;
  final VoidCallback onCheck;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF0EEE6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A735C00),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: showRetry
          ? DuoPrimaryButton(
              label: 'Thử lại',
              onPressed: onRetry,
            )
          : Row(
              children: [
                SmartStepsPressEffect(
                  child: OutlinedButton.icon(
                    onPressed: onHint,
                    icon: const Icon(Icons.lightbulb_rounded, size: 20),
                    label: const Text('Gợi ý'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(112, 50),
                      foregroundColor: GameColors.ink,
                      side: BorderSide(
                        color: GameColors.banana.withValues(alpha: 0.45),
                        width: 2,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DuoPrimaryButton(
                    label: isCorrect ? 'Nhận thưởng' : 'Kiểm tra',
                    onPressed: isCorrect ? onContinue : (canCheck ? onCheck : null),
                  ),
                ),
              ],
            ),
    );
  }
}

List<_MiniChallengeStep> _miniChallengeStepsFor(SafetyLesson lesson) {
  final text = '${lesson.title} ${lesson.mission} ${lesson.topic}'
      .toLowerCase();
  if (text.contains('người lạ')) {
    return const [
      _MiniChallengeStep(
        id: 'step-back',
        label: 'Lùi lại',
        icon: Icons.keyboard_backspace_rounded,
        color: Color(0xFF8B5000),
        background: Color(0xFFFFF0D9),
        imagePath: 'assets/images/stranger_step_back.webp',
      ),
      _MiniChallengeStep(
        id: 'say-no',
        label: 'Nói không',
        icon: Icons.record_voice_over_rounded,
        color: Color(0xFF93000A),
        background: Color(0xFFFFDAD6),
        imagePath: 'assets/images/stranger_say_no.webp',
      ),
      _MiniChallengeStep(
        id: 'tell-teacher',
        label: 'Báo cô giáo',
        icon: Icons.school_rounded,
        color: Color(0xFF006E1C),
        background: Color(0xFFE1F8DD),
        imagePath: 'assets/images/stranger_tell_teacher.webp',
      ),
    ];
  }

  if (text.contains('qua đường') || text.contains('giao thông')) {
    return const [
      _MiniChallengeStep(
        id: 'stop',
        label: 'Dừng lại',
        icon: Icons.pan_tool_alt_rounded,
        color: Color(0xFF93000A),
        background: Color(0xFFFFDAD6),
        imagePath: 'assets/images/traffic_stop.webp',
      ),
      _MiniChallengeStep(
        id: 'hold-hand',
        label: 'Nắm tay người lớn',
        icon: Icons.handshake_rounded,
        color: Color(0xFF8B5000),
        background: Color(0xFFFFF0D9),
        imagePath: 'assets/images/traffic_hold_hand.webp',
      ),
      _MiniChallengeStep(
        id: 'wait-safe',
        label: 'Chờ an toàn rồi đi',
        icon: Icons.traffic_rounded,
        color: Color(0xFF006E1C),
        background: Color(0xFFE1F8DD),
        imagePath: 'assets/images/traffic_wait_safe.webp',
      ),
    ];
  }

  return const [
    _MiniChallengeStep(
      id: 'pause',
      label: 'Dừng lại',
      icon: Icons.pause_circle_filled_rounded,
      color: Color(0xFF93000A),
      background: Color(0xFFFFDAD6),
      imagePath: 'assets/images/default_pause.webp',
    ),
    _MiniChallengeStep(
      id: 'safe-choice',
      label: 'Chọn cách an toàn',
      icon: Icons.verified_rounded,
      color: Color(0xFF8B5000),
      background: Color(0xFFFFF0D9),
      imagePath: 'assets/images/default_safe_choice.webp',
    ),
    _MiniChallengeStep(
      id: 'ask-adult',
      label: 'Tìm người lớn',
      icon: Icons.supervisor_account_rounded,
      color: Color(0xFF006E1C),
      background: Color(0xFFE1F8DD),
      imagePath: 'assets/images/default_ask_adult.webp',
    ),
  ];
}

List<_MiniChallengeStep> _miniChallengeOptionsFor(
  List<_MiniChallengeStep> steps,
) {
  if (steps.length < 3) {
    return steps;
  }
  return [steps[1], steps[2], steps[0]];
}

class _TemplateObserveScreenState extends State<_TemplateObserveScreen> {
  final Set<String> _foundIds = <String>{};
  bool _showHint = false;

  late final List<_TemplateObserveItem> _items = _templateObserveItemsFor(
    widget.lesson,
  );

  late final AudioPlayer _instructionPlayer;

  @override
  void initState() {
    super.initState();
    _instructionPlayer = AudioPlayer();
    _playInstruction();
  }

  Future<void> _playInstruction() async {
    try {
      await _instructionPlayer.play(AssetSource('voices/voice_intro_minigame_fidning.mp3'));
    } catch (e) {
      debugPrint('Error playing minigame finding instruction voice: $e');
    }
  }

  @override
  void dispose() {
    _instructionPlayer.dispose();
    super.dispose();
  }

  bool get _canContinue => _foundIds.length == _items.length;

  void _markFound(_TemplateObserveItem item) {
    setState(() {
      _foundIds.add(item.id);
      _showHint = false;
    });
  }

  void _showNextHint() {
    setState(() {
      _showHint = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final foundCount = _foundIds.length;
    final remainingCount = (_items.length - foundCount).clamp(0, _items.length);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 380;
            final horizontalPadding = compact ? 18.0 : 24.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TemplateObserveHeader(
                  title: lesson.title,
                  onBack: widget.onBack,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    10,
                    horizontalPadding,
                    0,
                  ),
                  child: _TemplatePromptPill(text: _observePromptFor(lesson)),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      16,
                      horizontalPadding,
                      10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _TemplateObserveScene(
                            lesson: lesson,
                            items: _items,
                            foundIds: _foundIds,
                            showHint: _showHint,
                            onFound: _markFound,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _TemplateFoundItems(items: _items, foundIds: _foundIds),
                        const SizedBox(height: 6),
                        Text(
                          remainingCount == 0
                              ? 'Con đã tìm đủ rồi.'
                              : 'Còn $remainingCount điều nữa',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: GameColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _TemplateObserveActions(
                  canContinue: _canContinue,
                  onContinue: widget.onContinue,
                  onHint: _showNextHint,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TemplateObserveHeader extends StatelessWidget {
  const _TemplateObserveHeader({
    required this.title,
    required this.onBack,
    this.progressLabel = '1/5',
  });

  final String title;
  final VoidCallback onBack;
  final String progressLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF0EEE6),
        boxShadow: [
          BoxShadow(
            color: Color(0x1425324B),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _TemplateCircleButton(
            icon: Icons.arrow_back_rounded,
            label: 'Quay lại',
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GameColors.ink,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE4E3DB),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              progressLabel,
              style: const TextStyle(
                color: GameColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _TemplateCircleButton(
            icon: Icons.volume_up_rounded,
            label: 'Nghe lại',
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _TemplateCircleButton extends StatelessWidget {
  const _TemplateCircleButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: SmartStepsPressEffect(
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 24),
          color: GameColors.muted,
          style: IconButton.styleFrom(
            fixedSize: const Size(40, 40),
            backgroundColor: Colors.white.withValues(alpha: 0.72),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}

class _TemplatePromptPill extends StatelessWidget {
  const _TemplatePromptPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4E3DB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1225324B),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle_fill_rounded, color: GameColors.banana),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: GameColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateObserveScene extends StatelessWidget {
  const _TemplateObserveScene({
    required this.lesson,
    required this.items,
    required this.foundIds,
    required this.showHint,
    required this.onFound,
  });

  final SafetyLesson lesson;
  final List<_TemplateObserveItem> items;
  final Set<String> foundIds;
  final bool showHint;
  final ValueChanged<_TemplateObserveItem> onFound;

  @override
  Widget build(BuildContext context) {
    final background = _templateSceneBackgroundFor(lesson);

    return Container(
      constraints: const BoxConstraints(minHeight: 260),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEE6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4E3DB), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A735C00),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            background,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  const Color(0xFF30240A).withValues(alpha: 0.18),
                ],
              ),
            ),
          ),
          for (final item in items)
            Align(
              alignment: item.alignment,
              child: _TemplateHotspot(
                item: item,
                isFound: foundIds.contains(item.id),
                isHinted: showHint && !foundIds.contains(item.id),
                onTap: () => onFound(item),
              ),
            ),
        ],
      ),
    );
  }
}

class _TemplateHotspot extends StatefulWidget {
  const _TemplateHotspot({
    required this.item,
    required this.isFound,
    required this.isHinted,
    required this.onTap,
  });

  final _TemplateObserveItem item;
  final bool isFound;
  final bool isHinted;
  final VoidCallback onTap;

  @override
  State<_TemplateHotspot> createState() => _TemplateHotspotState();
}

class _TemplateHotspotState extends State<_TemplateHotspot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final found = widget.isFound;
    final color = found ? GameColors.safe : GameColors.banana;

    return Semantics(
      button: true,
      label: widget.item.label,
      child: SmartStepsPressEffect(
        enabled: !found,
        child: GestureDetector(
          onTap: found ? null : widget.onTap,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final pulse =
                  1 + math.sin(_controller.value * math.pi * 2) * 0.05;
              return Transform.scale(scale: found ? 1 : pulse, child: child);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: widget.isHinted ? 68 : 58,
                  height: widget.isHinted ? 68 : 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: found ? 0.24 : 0.28),
                    border: Border.all(
                      color: found ? GameColors.safe : Colors.white,
                      width: found ? 4 : 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(
                          alpha: widget.isHinted ? 0.38 : 0.20,
                        ),
                        blurRadius: widget.isHinted ? 22 : 14,
                        spreadRadius: widget.isHinted ? 5 : 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    found ? Icons.check_circle_rounded : widget.item.icon,
                    color: found ? GameColors.safe : GameColors.ink,
                    size: found ? 34 : 28,
                  ),
                ),
                if (found) ...[
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: GameColors.safe,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F25324B),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.item.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateFoundItems extends StatelessWidget {
  const _TemplateFoundItems({required this.items, required this.foundIds});

  final List<_TemplateObserveItem> items;
  final Set<String> foundIds;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: 'Đã tìm thấy: ',
            children: [
              TextSpan(
                text: '${foundIds.length}/${items.length}',
                style: const TextStyle(color: GameColors.safe),
              ),
            ],
          ),
          style: const TextStyle(
            color: GameColors.muted,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              _TemplateFoundChip(
                label: item.label,
                icon: item.icon,
                isFound: foundIds.contains(item.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _TemplateFoundChip extends StatelessWidget {
  const _TemplateFoundChip({
    required this.label,
    required this.icon,
    required this.isFound,
  });

  final String label;
  final IconData icon;
  final bool isFound;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isFound ? const Color(0xFFE5FFE3) : const Color(0xFFE4E3DB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isFound
              ? GameColors.safe.withValues(alpha: 0.28)
              : const Color(0xFFD0C6AE),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFound ? Icons.check_rounded : icon,
            color: isFound ? GameColors.safe : GameColors.muted,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isFound ? const Color(0xFF005313) : GameColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateObserveActions extends StatelessWidget {
  const _TemplateObserveActions({
    required this.canContinue,
    required this.onContinue,
    required this.onHint,
  });

  final bool canContinue;
  final VoidCallback onContinue;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF0EEE6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A735C00),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DuoPrimaryButton(
            label: 'Tiếp tục →',
            onPressed: canContinue ? onContinue : null,
          ),
          const SizedBox(height: 9),
          SmartStepsPressEffect(
            child: OutlinedButton.icon(
              onPressed: onHint,
              icon: const Icon(Icons.lightbulb_rounded, size: 20),
              label: const Text('Gợi ý'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
                foregroundColor: GameColors.ink,
                side: BorderSide(
                  color: GameColors.banana.withValues(alpha: 0.45),
                  width: 2,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

_TemplateObserveSceneConfig _templateObserveSceneConfigFor(
  SafetyLesson lesson,
) {
  if (lesson.situationId == 201) {
    return const _TemplateObserveSceneConfig(
      backgroundAsset: 'assets/images/flashCard/Safety_stranger/step-one.webp',
      items: [
        _TemplateObserveItem(
          id: 'gate',
          label: 'Cổng trường',
          icon: Icons.location_on_rounded,
          alignment: Alignment(-0.16, -0.56),
        ),
        _TemplateObserveItem(
          id: 'safe-adult',
          label: 'Cô giáo',
          icon: Icons.school_rounded,
          alignment: Alignment(-0.08, 0.15),
        ),
        _TemplateObserveItem(
          id: 'stranger',
          label: 'Người lạ',
          icon: Icons.person_search_rounded,
          alignment: Alignment(0.50, 0.15),
        ),
      ],
    );
  }

  if (lesson.situationId == 301) {
    return const _TemplateObserveSceneConfig(
      backgroundAsset: 'assets/images/flashCard/Crossroad/step-one.webp',
      items: [
        _TemplateObserveItem(
          id: 'traffic-light',
          label: 'Đèn giao thông',
          icon: Icons.traffic_rounded,
          alignment: Alignment(-0.79, -0.58),
        ),
        _TemplateObserveItem(
          id: 'car',
          label: 'Xe ô tô',
          icon: Icons.directions_car_rounded,
          alignment: Alignment(-0.20, 0.13),
        ),
        _TemplateObserveItem(
          id: 'waiting-child',
          label: 'Bé đứng chờ',
          icon: Icons.accessibility_new_rounded,
          alignment: Alignment(0.53, 0.20),
        ),
      ],
    );
  }
  return _TemplateObserveSceneConfig(
    backgroundAsset: _defaultTemplateSceneBackgroundFor(lesson),
    items: _defaultTemplateObserveItemsFor(lesson),
  );
}

List<_TemplateObserveItem> _templateObserveItemsFor(SafetyLesson lesson) {
  return _templateObserveSceneConfigFor(lesson).items;
}

List<_TemplateObserveItem> _defaultTemplateObserveItemsFor(
  SafetyLesson lesson,
) {
  final text = '${lesson.title} ${lesson.mission} ${lesson.topic}'
      .toLowerCase();

  if (text.contains('người lạ')) {
    return const [
      _TemplateObserveItem(
        id: 'stranger',
        label: 'Người lạ',
        icon: Icons.person_search_rounded,
        alignment: Alignment(-0.48, -0.24),
      ),
      _TemplateObserveItem(
        id: 'safe-adult',
        label: 'Cô giáo',
        icon: Icons.school_rounded,
        alignment: Alignment(0.52, -0.06),
      ),
      _TemplateObserveItem(
        id: 'gate',
        label: 'Cổng trường',
        icon: Icons.location_on_rounded,
        alignment: Alignment(-0.04, 0.50),
      ),
    ];
  }

  if (text.contains('bạn') || text.contains('thách')) {
    return const [
      _TemplateObserveItem(
        id: 'friends',
        label: 'Nhóm bạn',
        icon: Icons.groups_rounded,
        alignment: Alignment(-0.52, -0.12),
      ),
      _TemplateObserveItem(
        id: 'risk',
        label: 'Việc nguy hiểm',
        icon: Icons.warning_rounded,
        alignment: Alignment(0.48, 0.04),
      ),
      _TemplateObserveItem(
        id: 'adult',
        label: 'Người lớn',
        icon: Icons.record_voice_over_rounded,
        alignment: Alignment(-0.06, 0.56),
      ),
    ];
  }

  if (text.contains('ví') || text.contains('rơi')) {
    return const [
      _TemplateObserveItem(
        id: 'item',
        label: 'Đồ bị rơi',
        icon: Icons.wallet_rounded,
        alignment: Alignment(-0.34, 0.38),
      ),
      _TemplateObserveItem(
        id: 'owner',
        label: 'Người đánh rơi',
        icon: Icons.person_rounded,
        alignment: Alignment(0.46, -0.16),
      ),
      _TemplateObserveItem(
        id: 'staff',
        label: 'Nhân viên',
        icon: Icons.support_agent_rounded,
        alignment: Alignment(-0.58, -0.22),
      ),
    ];
  }

  return const [
    _TemplateObserveItem(
      id: 'danger',
      label: 'Điều nguy hiểm',
      icon: Icons.warning_rounded,
      alignment: Alignment(-0.48, -0.16),
    ),
    _TemplateObserveItem(
      id: 'safe-adult',
      label: 'Người giúp con',
      icon: Icons.record_voice_over_rounded,
      alignment: Alignment(0.50, -0.04),
    ),
    _TemplateObserveItem(
      id: 'place',
      label: 'Nơi đang đứng',
      icon: Icons.place_rounded,
      alignment: Alignment(-0.02, 0.52),
    ),
  ];
}

String _observePromptFor(SafetyLesson lesson) {
  final count = _templateObserveItemsFor(lesson).length;
  return 'Con tìm $count điều cần chú ý nhé!';
}

String _templateSceneBackgroundFor(SafetyLesson lesson) {
  return _templateObserveSceneConfigFor(lesson).backgroundAsset;
}

String _defaultTemplateSceneBackgroundFor(SafetyLesson lesson) {
  return switch (lesson.islandId) {
    2 => LessonAssets.island2Background,
    3 => 'assets/images/flashCard/Crossroad/step-one.webp',
    _ => LessonAssets.island1Background,
  };
}

class _LessonExitButton extends StatelessWidget {
  const _LessonExitButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Thoát bài học',
      child: SmartStepsPressEffect(
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            fixedSize: const Size(48, 48),
            padding: EdgeInsets.zero,
            backgroundColor: Colors.white.withValues(alpha: 0.92),
            foregroundColor: GameColors.ink,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.9),
                width: 3,
              ),
            ),
          ),
          child: const Icon(Icons.close_rounded, size: 26),
        ),
      ),
    );
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({
    required this.lesson,
    required this.isParentReadingMode,
    required this.onToggleReadingMode,
    required this.onRestart,
    required this.onExit,
  });

  final SafetyLesson lesson;
  final bool isParentReadingMode;
  final VoidCallback onToggleReadingMode;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.topic,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF476070),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lesson.title,
                        maxLines: compact ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _CircleIconButton(
                  label: 'Thoát bài học',
                  icon: Icons.close_rounded,
                  onPressed: onExit,
                ),
                const SizedBox(width: 8),
                _CircleIconButton(
                  label: 'Chơi lại màn',
                  icon: Icons.restart_alt_rounded,
                  onPressed: onRestart,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PillButton(
                    label: isParentReadingMode ? 'Phụ huynh đọc' : 'Bé tự nghe',
                    icon: isParentReadingMode
                        ? Icons.family_restroom_rounded
                        : Icons.volume_up_rounded,
                    onPressed: onToggleReadingMode,
                  ),
                ),
                const SizedBox(width: 10),
                _SafetyDots(isActive: false),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _CompactLessonControls extends StatelessWidget {
  const _CompactLessonControls({required this.onRestart, required this.onExit});

  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: SafeArea(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SmallCircleIconButton(
              label: 'Chơi lại màn',
              icon: Icons.restart_alt_rounded,
              onPressed: onRestart,
            ),
            const SizedBox(width: 8),
            _SmallCircleIconButton(
              label: 'Thoát bài học',
              icon: Icons.close_rounded,
              onPressed: onExit,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryClipStage extends StatefulWidget {
  const _StoryClipStage({
    super.key,
    required this.copy,
    required this.variant,
    required this.onFinished,
  });

  final LessonVideoCopy copy;
  final LessonPhase variant;
  final VoidCallback onFinished;

  @override
  State<_StoryClipStage> createState() => _StoryClipStageState();
}

class _StoryClipStageState extends State<_StoryClipStage> {
  VideoPlayerController? _videoController;
  bool _hasStartedPlayback = false;
  bool _hasFinishedVideo = false;
  bool _hasVideoLoadFailed = false;
  String? _videoLoadErrorMessage;

  bool get _isWrong => widget.variant == LessonPhase.wrongVideo;
  bool get _isReady => _videoController?.value.isInitialized ?? false;
  bool get _isPlaying => _videoController?.value.isPlaying ?? false;

  double get _progress {
    final controller = _videoController;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.duration.inMilliseconds == 0) {
      return 0;
    }

    final position = controller.value.position.inMilliseconds;
    final duration = controller.value.duration.inMilliseconds;
    return (position / duration).clamp(0.0, 1.0).toDouble();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_initializeVideoController());
  }

  Future<void> _initializeVideoController() async {
    VideoPlayerController? controller;
    final mediaAsset = widget.copy.asset?.trim();

    if (mediaAsset == null || mediaAsset.isEmpty) {
      if (mounted) {
        setState(() {
          _hasVideoLoadFailed = true;
          _videoLoadErrorMessage =
              'Bài học này chưa có video. Bấm bỏ qua để học phần câu hỏi.';
        });
      }
      return;
    }

    try {
      if (mediaAsset.startsWith('assets/') &&
          !await _lessonAssetExists(mediaAsset)) {
        if (mounted) {
          setState(() {
            _hasVideoLoadFailed = true;
            _videoLoadErrorMessage =
                'Video của bài học chưa có trong assets. Bấm bỏ qua để tiếp tục.';
          });
        }
        return;
      }

      final remoteVideoUrl = await _mediaResolver.signedVideoUrlFor(
        widget.copy,
      );
      controller = mediaAsset.startsWith('assets/')
          ? VideoPlayerController.asset(
              mediaAsset,
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
            )
          : remoteVideoUrl != null
          ? VideoPlayerController.networkUrl(
              remoteVideoUrl,
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
            )
          : throw const MediaConfigurationException(
              'Backend did not return a signed media URL.',
            );

      controller
        ..addListener(_handleVideoTick)
        ..setLooping(false);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _videoController = controller;
      await controller.initialize();

      if (!mounted) {
        return;
      }

      setState(() {});
      await _autoplayClip();

      if (mounted) {
        setState(() {});
      }
    } catch (error, stackTrace) {
      debugPrint('SmartSteps video load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (controller != null) {
        controller.removeListener(_handleVideoTick);
        await controller.dispose();
      }
      if (mounted) {
        setState(() {
          _hasVideoLoadFailed = true;
          _videoLoadErrorMessage =
              'Video chưa phát được trên thiết bị này. Bấm bỏ qua để tiếp tục.';
        });
      }
    }
  }

  @override
  void dispose() {
    final controller = _videoController;
    if (controller != null) {
      controller.removeListener(_handleVideoTick);
      controller.dispose();
    }
    super.dispose();
  }

  void _handleVideoTick() {
    if (!mounted) {
      return;
    }

    final controller = _videoController;
    if (controller == null) {
      return;
    }

    final value = controller.value;
    if (value.isInitialized && !_hasStartedPlayback) {
      unawaited(_autoplayClip());
    }

    final isAtEnd =
        value.isInitialized &&
        value.duration > Duration.zero &&
        value.position >= value.duration - const Duration(milliseconds: 160);

    var shouldFinish = false;
    setState(() {
      shouldFinish = !_hasFinishedVideo && isAtEnd;
      if (shouldFinish) {
        _hasFinishedVideo = true;
      }
    });

    if (shouldFinish) {
      widget.onFinished();
    }
  }

  Future<void> _startClipFromBeginning() async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    _hasFinishedVideo = false;
    await controller.seekTo(Duration.zero);

    try {
      await controller.setVolume(
        smartStepsIsIosWeb ? _iosWebLessonVideoVolume : _lessonVideoVolume,
      );
    } catch (_) {
      // Keep playback usable on platforms that do not expose volume control.
    }

    try {
      await controller.setPlaybackSpeed(1.0);
    } catch (_) {
      // Keep the clip usable even if a platform cannot apply playback speed.
    }

    try {
      await controller.play();
    } catch (_) {
      // Autoplay can be blocked on some hosts; the clip remains visible.
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _autoplayClip() async {
    if (_hasStartedPlayback || !_isReady) {
      return;
    }

    _hasStartedPlayback = true;
    await _startClipFromBeginning();
  }

  Future<void> _skipClip() async {
    final controller = _videoController;
    if (controller != null &&
        controller.value.isInitialized &&
        controller.value.isPlaying) {
      await controller.pause();
    }
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isWrong ? GameColors.danger : GameColors.safe;
    final controller = _videoController;
    final aspectRatio = _isReady && controller != null
        ? controller.value.aspectRatio
        : 16 / 9;

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: ColoredBox(
                color: Colors.black,
                child: _isReady
                    ? VideoPlayer(controller!)
                    : Center(
                        child: _hasVideoLoadFailed
                            ? _VideoLoadErrorBadge(
                                message: _videoLoadErrorMessage,
                              )
                            : const _VideoLoadingBadge(),
                      ),
              ),
            ),
          ),
          _FullscreenClipControls(
            copy: widget.copy,
            isReady: _isReady,
            isPlaying: _isPlaying,
            progress: _progress,
            accent: accent,
            onSkip: _skipClip,
          ),
        ],
      ),
    );
  }
}

class _FullscreenClipControls extends StatelessWidget {
  const _FullscreenClipControls({
    required this.copy,
    required this.isReady,
    required this.isPlaying,
    required this.progress,
    required this.accent,
    required this.onSkip,
  });

  final LessonVideoCopy copy;
  final bool isReady;
  final bool isPlaying;
  final double progress;
  final Color accent;
  final Future<void> Function() onSkip;

  @override
  Widget build(BuildContext context) {
    final statusLabel = isPlaying
        ? 'Đang chiếu'
        : isReady
        ? 'Sẵn sàng'
        : 'Đang chuẩn bị';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.52),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SmartStepsPressEffect(
                      child: TextButton(
                        onPressed: () {
                          unawaited(onSkip());
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.52),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        child: Text(
                          copy.skipLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoLoadingBadge extends StatelessWidget {
  const _VideoLoadingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Đang chuẩn bị video...',
        style: TextStyle(
          color: GameColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _VideoLoadErrorBadge extends StatelessWidget {
  const _VideoLoadErrorBadge({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      constraints: const BoxConstraints(maxWidth: 320),
      child: Text(
        message == null || message!.isEmpty ? 'Không tải được video' : message!,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: GameColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SceneStage extends StatelessWidget {
  const _SceneStage({
    required this.lesson,
    required this.phase,
    required this.onInspectObject,
  });

  final SafetyLesson lesson;
  final LessonPhase phase;
  final VoidCallback onInspectObject;

  bool get _isObjectActive => phase == LessonPhase.opening;
  bool get _isWrong => phase == LessonPhase.wrong;
  bool get _showMother {
    return phase == LessonPhase.parent;
  }

  String get _characterAsset {
    switch (phase) {
      case LessonPhase.wrong:
      case LessonPhase.wrongVideo:
        return LessonAssets.childChoking;
      case LessonPhase.correctVideo:
      case LessonPhase.miniChallenge:
      case LessonPhase.parent:
        return LessonAssets.childHappy;
      case LessonPhase.introVideo:
      case LessonPhase.opening:
      case LessonPhase.inspectObject:
        return LessonAssets.kid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _StageFrame(
      semanticLabel: lesson.sceneTitle,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final compact = width < 430;

          return _WrongScreenShake(
            isActive: _isWrong,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    LessonAssets.livingRoom,
                    fit: BoxFit.cover,
                    alignment: compact
                        ? Alignment.center
                        : Alignment.centerRight,
                  ),
                ),
                const Positioned.fill(child: _WarmSceneOverlay()),
                Positioned(
                  left: compact ? 20 : width * 0.12,
                  bottom: compact ? 26 : 58,
                  child: _HazardSpot(
                    isActive: _isObjectActive,
                    hint: lesson.openingHint,
                    onTap: onInspectObject,
                  ),
                ),
                Positioned(
                  right: compact ? -10 : width * 0.06,
                  bottom: compact ? 2 : 18,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0.08, 0.04),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutBack,
                                ),
                              ),
                          child: child,
                        ),
                      );
                    },
                    child: Image.asset(
                      _characterAsset,
                      key: ValueKey(_characterAsset),
                      width: compact ? width * 0.48 : width * 0.36,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (_showMother)
                  Positioned(
                    right: compact ? width * 0.32 : width * 0.33,
                    bottom: compact ? 10 : 28,
                    child: _FloatingImage(
                      asset: LessonAssets.mother,
                      width: compact ? width * 0.27 : width * 0.22,
                      delay: const Duration(milliseconds: 220),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WrongScreenShake extends StatefulWidget {
  const _WrongScreenShake({required this.isActive, required this.child});

  final bool isActive;
  final Widget child;

  @override
  State<_WrongScreenShake> createState() => _WrongScreenShakeState();
}

class _WrongScreenShakeState extends State<_WrongScreenShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _WrongScreenShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        if (!widget.isActive) {
          return child!;
        }

        final fade = 1 - Curves.easeOutCubic.transform(_controller.value);
        final dx = math.sin(_controller.value * math.pi * 8) * 5 * fade;
        final dy = math.cos(_controller.value * math.pi * 6) * 2 * fade;

        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
    );
  }
}

class _HazardSpot extends StatefulWidget {
  const _HazardSpot({
    required this.isActive,
    required this.hint,
    required this.onTap,
  });

  final bool isActive;
  final String hint;
  final VoidCallback onTap;

  @override
  State<_HazardSpot> createState() => _HazardSpotState();
}

class _HazardSpotState extends State<_HazardSpot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.isActive,
      label: widget.hint,
      child: SmartStepsPressEffect(
        enabled: widget.isActive,
        child: GestureDetector(
          key: const ValueKey('hazard-spot'),
          onTap: widget.isActive ? widget.onTap : null,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final pulse =
                  1 + math.sin(_controller.value * math.pi * 2) * 0.06;
              final lift = math.sin(_controller.value * math.pi * 2) * -5;

              return Transform.translate(
                offset: Offset(0, widget.isActive ? lift : 0),
                child: Transform.scale(
                  scale: widget.isActive ? pulse : 1,
                  child: child,
                ),
              );
            },
            child: SizedBox(
              width: 118,
              height: 132,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  if (widget.isActive)
                    Positioned(
                      bottom: 82,
                      child: _HintBubble(label: widget.hint),
                    ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GameColors.banana.withValues(alpha: 0.26),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.72),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: GameColors.banana.withValues(alpha: 0.32),
                            blurRadius: widget.isActive ? 28 : 12,
                            spreadRadius: widget.isActive ? 8 : 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    child: Image.asset(
                      LessonAssets.ball,
                      width: 65,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const Positioned(
                    right: 18,
                    bottom: 54,
                    child: _Sparkle(size: 11),
                  ),
                  const Positioned(
                    left: 18,
                    bottom: 22,
                    child: _Sparkle(size: 8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HintBubble extends StatelessWidget {
  const _HintBubble({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2425324B),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: GameColors.ink,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
      ),
    );
  }
}

class _QuestionOverlay extends StatefulWidget {
  const _QuestionOverlay({
    required this.lesson,
    required this.selectedChoice,
    required this.isParentReadingMode,
    required this.onSelectChoice,
  });

  final SafetyLesson lesson;
  final LessonChoice? selectedChoice;
  final bool isParentReadingMode;
  final ValueChanged<String> onSelectChoice;

  @override
  State<_QuestionOverlay> createState() => _QuestionOverlayState();
}

class _QuestionOverlayState extends State<_QuestionOverlay> {
  late AudioPlayer _voicePlayer;
  String? _activeNarrationId;
  String? _focusedChoiceId;
  bool _hasPlayedOpeningNarration = false;
  int _openingSequenceId = 0;
  int _voiceRequestId = 0;
  int _voicePlayerGeneration = 0;

  List<({String id, String asset, String text})> get _narrationQueue {
    return [
      (
        id: 'question',
        asset: widget.lesson.questionVoice.asset,
        text: widget.lesson.questionVoice.text,
      ),
      ...widget.lesson.choices.map(
        (choice) =>
            (id: choice.id, asset: choice.voice.asset, text: choice.voice.text),
      ),
    ];
  }

  Duration _fallbackDurationFor(String id) {
    if (id == 'question') {
      return _questionFallbackDuration;
    }

    return smartStepsIsIosWeb
        ? _iosWebChoiceFallbackDuration
        : _choiceFallbackDuration;
  }

  Duration get _sequenceGap =>
      smartStepsIsIosWeb ? _iosWebVoiceSequenceGap : _voiceSequenceGap;

  @override
  void initState() {
    super.initState();
    _activeNarrationId = widget.isParentReadingMode ? null : 'question';
    _voicePlayer = _createVoicePlayer();
    unawaited(_prepareVoicePlayer());
    if (!widget.isParentReadingMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_playOpeningNarrationOnce());
      });
    }
  }

  @override
  void didUpdateWidget(covariant _QuestionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isParentReadingMode == oldWidget.isParentReadingMode) {
      return;
    }

    if (widget.isParentReadingMode) {
      _openingSequenceId++;
      _voiceRequestId++;
      _hasPlayedOpeningNarration = false;
      _activeNarrationId = null;
      _focusedChoiceId = null;
      unawaited(_stopVoicePlayer());
      return;
    }

    _activeNarrationId = 'question';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_playOpeningNarrationOnce());
    });
  }

  @override
  void dispose() {
    _voiceRequestId++;
    unawaited(_stopAndDisposeVoicePlayer());
    super.dispose();
  }

  Future<void> _stopAndDisposeVoicePlayer() async {
    try {
      await _voicePlayer.stop();
    } catch (_) {
      // Audio plugin calls can fail on test/desktop hosts.
    }

    try {
      await _voicePlayer.dispose();
    } catch (_) {
      // Keep teardown best-effort on hosts without audio support.
    }
  }

  Future<void> _stopVoicePlayer() async {
    try {
      await _voicePlayer.stop();
    } catch (error, stackTrace) {
      debugPrint('SmartSteps voice stop failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _prepareVoicePlayer() async {
    try {
      await _voicePlayer.setAudioContext(_voiceAudioContext);
    } catch (error, stackTrace) {
      debugPrint('SmartSteps voice audio context failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    try {
      await _voicePlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _voicePlayer.setReleaseMode(ReleaseMode.stop);
      await _voicePlayer.setVolume(_voiceVolumeForPlatform);
    } catch (error, stackTrace) {
      debugPrint('SmartSteps voice player setup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  double get _voiceVolumeForPlatform =>
      smartStepsIsIosWeb ? _iosWebVoiceVolume : _voiceVolume;

  AudioPlayer _createVoicePlayer() {
    if (!smartStepsIsIosWeb) {
      return AudioPlayer();
    }

    _voicePlayerGeneration += 1;
    return AudioPlayer(
      playerId: 'smartsteps-ios-voice-$_voicePlayerGeneration',
    );
  }

  Future<void> _setVoicePlaybackRate() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _voicePlayer.setPlaybackRate(1.0);
      } catch (_) {}
      return;
    }

    try {
      await _voicePlayer.setPlaybackRate(_voicePlaybackRate);
    } catch (error, stackTrace) {
      debugPrint('SmartSteps voice playback rate failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _precacheNarrationAssets() async {
    for (final item in _narrationQueue) {
      if (!mounted) {
        return;
      }

      if (item.asset.trim().isEmpty) {
        continue;
      }

      final assetPath = _voiceAssetPath(item.asset);
      Uri? remoteVoiceUrl;
      try {
        remoteVoiceUrl = await _mediaResolver.signedVoiceUrlFor(item.asset);
      } catch (error, stackTrace) {
        debugPrint('SmartSteps voice signing failed for $assetPath: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (remoteVoiceUrl != null) {
        debugPrint('SmartSteps voice signed: $assetPath');
        continue;
      }

      if (!item.asset.trim().startsWith('assets/')) {
        continue;
      }

      try {
        await rootBundle.load(item.asset);
        await _voicePlayer.audioCache.loadPath(assetPath);
        debugPrint('SmartSteps voice preloaded: $assetPath');
      } catch (error, stackTrace) {
        debugPrint('SmartSteps voice preload failed for $assetPath: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  Future<void> _playOpeningNarrationOnce() async {
    if (_hasPlayedOpeningNarration || widget.isParentReadingMode) {
      return;
    }

    _hasPlayedOpeningNarration = true;
    final sequenceId = ++_openingSequenceId;

    final openingNarration = widget.lesson.openingNarration;
    if (smartStepsIsIosWeb && openingNarration != null) {
      final didStart = await _playCombinedOpeningNarration(
        openingNarration,
        sequenceId,
      );
      if (didStart) {
        return;
      }
    }

    await _precacheNarrationAssets();

    for (final item in _narrationQueue) {
      if (!mounted || sequenceId != _openingSequenceId) {
        return;
      }

      final didStart = await _playNarrationAsset(
        item.id,
        item.asset,
        text: item.text,
        clearWhenFinished: false,
      );
      if (!mounted || sequenceId != _openingSequenceId) {
        return;
      }

      if (!didStart) {
        await Future<void>.delayed(_fallbackDurationFor(item.id));
      }

      if (!mounted || sequenceId != _openingSequenceId) {
        return;
      }
      await Future<void>.delayed(_sequenceGap);
    }

    if (mounted && sequenceId == _openingSequenceId) {
      setState(() {
        _activeNarrationId = null;
      });
    }
  }

  Future<void> _playNarration(String id, String asset, String text) async {
    if (widget.isParentReadingMode) {
      return;
    }

    _openingSequenceId++;
    await _playNarrationAsset(id, asset, text: text, clearWhenFinished: true);
  }

  Future<bool> _playCombinedOpeningNarration(
    LessonOpeningNarration narration,
    int sequenceId,
  ) async {
    if (narration.cues.isEmpty || widget.isParentReadingMode) {
      return false;
    }

    final requestId = ++_voiceRequestId;
    final assetPath = _voiceAssetPath(narration.asset);

    try {
      await rootBundle.load(narration.asset);
      if (!mounted ||
          sequenceId != _openingSequenceId ||
          requestId != _voiceRequestId) {
        return false;
      }

      setState(() {
        _focusedChoiceId = null;
        _activeNarrationId = narration.cues.first.id;
      });

      await _stopVoicePlayer();
      if (!mounted ||
          sequenceId != _openingSequenceId ||
          requestId != _voiceRequestId) {
        return false;
      }

      final didStart = await _startVoicePlayback(
        asset: narration.asset,
        assetPath: assetPath,
        remoteVoiceUrl: null,
        requestId: requestId,
      );
      if (!didStart) {
        debugPrint('SmartSteps combined voice did not start: $assetPath');
        return false;
      }

      for (final cue in narration.cues) {
        if (!mounted ||
            sequenceId != _openingSequenceId ||
            requestId != _voiceRequestId) {
          return true;
        }

        setState(() {
          _activeNarrationId = cue.id;
        });

        await Future<void>.delayed(cue.duration);
      }

      if (mounted &&
          sequenceId == _openingSequenceId &&
          requestId == _voiceRequestId) {
        setState(() {
          _activeNarrationId = null;
        });
      }
      return true;
    } catch (error, stackTrace) {
      debugPrint('SmartSteps combined voice failed for $assetPath: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (requestId == _voiceRequestId) {
        await _stopVoicePlayer();
      }
      return false;
    }
  }

  void _focusNarration(String id, String asset) {
    if (widget.isParentReadingMode) {
      return;
    }

    unawaited(_playNarration(id, asset, _narrationTextFor(id)));
  }

  void _focusQuestionNarration() {
    if (widget.isParentReadingMode) {
      return;
    }

    setState(() {
      _focusedChoiceId = null;
      _activeNarrationId = 'question';
    });
    _focusNarration('question', widget.lesson.questionVoice.asset);
  }

  void _previewOrSelectChoice(LessonChoice choice) {
    if (_focusedChoiceId == choice.id) {
      _openingSequenceId++;
      _voiceRequestId++;
      unawaited(_stopVoicePlayer());
      widget.onSelectChoice(choice.id);
      return;
    }

    setState(() {
      _focusedChoiceId = choice.id;
      _activeNarrationId = choice.id;
    });
    _focusNarration(choice.id, choice.voice.asset);
  }

  void _clearFocusedNarration() {
    if (_focusedChoiceId == null && _activeNarrationId == null) {
      return;
    }

    _openingSequenceId++;
    _voiceRequestId++;
    setState(() {
      _focusedChoiceId = null;
      _activeNarrationId = null;
    });
    unawaited(_stopVoicePlayer());
  }

  String _narrationTextFor(String id) {
    if (id == 'question') {
      return widget.lesson.questionVoice.text;
    }

    for (final choice in widget.lesson.choices) {
      if (choice.id == id) {
        return choice.voice.text;
      }
    }

    return widget.lesson.questionVoice.text;
  }

  Future<bool> _playNarrationAsset(
    String id,
    String asset, {
    required String text,
    required bool clearWhenFinished,
  }) async {
    if (widget.isParentReadingMode) {
      return false;
    }

    final requestId = ++_voiceRequestId;
    if (asset.trim().isEmpty) {
      setState(() {
        _activeNarrationId = id;
      });
      await Future<void>.delayed(_fallbackDurationFor(id));
      if (mounted && clearWhenFinished && requestId == _voiceRequestId) {
        setState(() {
          _activeNarrationId = null;
        });
      }
      return true;
    }

    final assetPath = _voiceAssetPath(asset);
    try {
      final remoteVoiceUrl = await _mediaResolver.signedVoiceUrlFor(asset);

      setState(() {
        _activeNarrationId = id;
      });

      await _stopVoicePlayer();
      if (!mounted || requestId != _voiceRequestId) {
        return false;
      }

      final didStart = await _startVoicePlayback(
        asset: asset,
        assetPath: assetPath,
        remoteVoiceUrl: remoteVoiceUrl,
        requestId: requestId,
      );
      if (!didStart) {
        debugPrint('SmartSteps voice did not enter playing state: $assetPath');
        return false;
      }
      debugPrint('SmartSteps voice playing: $assetPath');
      final minimumHold = _fallbackDurationFor(id);
      final stopwatch = Stopwatch()..start();
      await Future.any<void>([
        _voicePlayer.onPlayerComplete.first.then<void>((_) {}),
        Future<void>.delayed(minimumHold + _voiceCompletionGrace),
      ]).timeout(_voicePlaybackTimeout, onTimeout: () {});
      stopwatch.stop();
      if (stopwatch.elapsed < minimumHold &&
          mounted &&
          requestId == _voiceRequestId) {
        await Future<void>.delayed(minimumHold - stopwatch.elapsed);
      }
      if (smartStepsIsIosWeb && mounted && requestId == _voiceRequestId) {
        await _resetVoicePlayerForNextClip();
      }
      return true;
    } catch (error, stackTrace) {
      debugPrint('SmartSteps voice playback failed for $assetPath: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (requestId == _voiceRequestId) {
        await _stopVoicePlayer();
      }
      return false;
    } finally {
      if (mounted && requestId == _voiceRequestId) {
        setState(() {
          if (clearWhenFinished) {
            _activeNarrationId = null;
          }
        });
      }
    }
  }

  Future<bool> _startVoicePlayback({
    required String asset,
    required String assetPath,
    required Uri? remoteVoiceUrl,
    required int requestId,
  }) async {
    if (smartStepsIsIosWeb) {
      await _replaceVoicePlayerForNextClip();
      if (!mounted || requestId != _voiceRequestId) {
        return false;
      }

      final source = await _voiceSourceFor(
        asset: asset,
        assetPath: assetPath,
        remoteVoiceUrl: remoteVoiceUrl,
      );
      if (source == null || !mounted || requestId != _voiceRequestId) {
        return false;
      }

      final startedFuture = _voicePlayer.onPlayerStateChanged
          .where((state) => state == PlayerState.playing)
          .first
          .timeout(_voiceStartTimeout, onTimeout: () => _voicePlayer.state);
      await _voicePlayer.play(
        source,
        volume: _voiceVolumeForPlatform,
        ctx: _voiceAudioContext,
        mode: PlayerMode.mediaPlayer,
      );
      final startState = await startedFuture;
      return startState == PlayerState.playing ||
          _voicePlayer.state == PlayerState.playing;
    }

    final source = await _voiceSourceFor(
      asset: asset,
      assetPath: assetPath,
      remoteVoiceUrl: remoteVoiceUrl,
    );
    if (source == null || !mounted || requestId != _voiceRequestId) {
      return false;
    }

    await _voicePlayer.setSource(source);
    if (!mounted || requestId != _voiceRequestId) {
      return false;
    }
    await _setVoicePlaybackRate();
    if (!mounted || requestId != _voiceRequestId) {
      return false;
    }
    final startedFuture = _voicePlayer.onPlayerStateChanged
        .where((state) => state == PlayerState.playing)
        .first
        .timeout(_voiceStartTimeout, onTimeout: () => _voicePlayer.state);
    await _voicePlayer.resume();
    final startState = await startedFuture;
    return startState == PlayerState.playing ||
        _voicePlayer.state == PlayerState.playing;
  }

  Future<Source?> _voiceSourceFor({
    required String asset,
    required String assetPath,
    required Uri? remoteVoiceUrl,
  }) async {
    if (remoteVoiceUrl != null) {
      return UrlSource(
        remoteVoiceUrl.toString(),
        mimeType: _voiceMimeTypeFor(assetPath),
      );
    }

    if (!asset.trim().startsWith('assets/')) {
      debugPrint('SmartSteps voice has no signed URL: $assetPath');
      return null;
    }

    await rootBundle.load(asset);
    return AssetSource(assetPath, mimeType: _voiceMimeTypeFor(assetPath));
  }

  String _voiceMimeTypeFor(String assetPath) {
    return assetPath.toLowerCase().endsWith('.m4a')
        ? 'audio/mp4'
        : 'audio/mpeg';
  }

  Future<void> _resetVoicePlayerForNextClip() async {
    try {
      await _voicePlayer.stop();
      await _voicePlayer.release();
      await _prepareVoicePlayer();
    } catch (error, stackTrace) {
      debugPrint('SmartSteps voice reset failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _replaceVoicePlayerForNextClip() async {
    try {
      await _voicePlayer.stop();
      await _voicePlayer.dispose();
    } catch (_) {
      // Keep replacement best-effort for Safari's stricter audio lifecycle.
    }

    _voicePlayer = _createVoicePlayer();
    await _prepareVoicePlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          return AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                isLandscape ? 68 : 16,
                isLandscape ? 8 : 62,
                isLandscape ? 16 : 16,
                isLandscape ? 12 : 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFFF2B7),
                    GameColors.cream,
                    GameColors.sky.withValues(alpha: 0.82),
                  ],
                ),
              ),
              child: _QuestionPanel(
                lesson: widget.lesson,
                selectedChoice: widget.selectedChoice,
                focusedChoiceId: _focusedChoiceId,
                activeNarrationId: _activeNarrationId,
                isLandscape: isLandscape,
                onQuestionTap: _focusQuestionNarration,
                onChoiceTap: _previewOrSelectChoice,
                onClearFocus: _clearFocusedNarration,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuestionPanel extends StatelessWidget {
  const _QuestionPanel({
    required this.lesson,
    required this.selectedChoice,
    required this.focusedChoiceId,
    required this.activeNarrationId,
    required this.isLandscape,
    required this.onQuestionTap,
    required this.onChoiceTap,
    required this.onClearFocus,
  });

  final SafetyLesson lesson;
  final LessonChoice? selectedChoice;
  final String? focusedChoiceId;
  final String? activeNarrationId;
  final bool isLandscape;
  final VoidCallback onQuestionTap;
  final ValueChanged<LessonChoice> onChoiceTap;
  final VoidCallback onClearFocus;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useHorizontalChoices = constraints.maxWidth >= 620;
        final compactCards =
            constraints.maxHeight < 430 || constraints.maxWidth < 430;
        final choices = lesson.choices.map((choice) {
          final isFocused = focusedChoiceId == choice.id;
          final isNarrating = activeNarrationId == choice.id;
          return _KidChoiceCard(
            choice: choice,
            isSelected: selectedChoice?.id == choice.id,
            isHighlighted: isFocused || isNarrating,
            isNarrating: isNarrating,
            isCompact: compactCards,
            onTap: () => onChoiceTap(choice),
          );
        }).toList();

        final prompt = _SimpleQuestionPrompt(
          lesson: lesson,
          isActive: activeNarrationId == 'question',
          isCompact: compactCards,
          onTap: onQuestionTap,
        );

        final choiceArea = useHorizontalChoices
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: choices.first),
                  const SizedBox(width: 16),
                  Expanded(child: choices.last),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: choices.first),
                  const SizedBox(height: 14),
                  Expanded(child: choices.last),
                ],
              );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onClearFocus,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.fromLTRB(
              isLandscape ? 16 : 18,
              isLandscape ? 12 : 16,
              isLandscape ? 16 : 18,
              isLandscape ? 16 : 18,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.84),
                width: 4,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2625324B),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: prompt,
                  ),
                ),
                SizedBox(height: isLandscape ? 14 : 18),
                Expanded(child: choiceArea),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SimpleQuestionPrompt extends StatelessWidget {
  const _SimpleQuestionPrompt({
    required this.lesson,
    required this.isActive,
    required this.isCompact,
    required this.onTap,
  });

  final SafetyLesson lesson;
  final bool isActive;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isActive ? 1.02 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      child: Material(
        color: Colors.transparent,
        child: SmartStepsPressEffect(
          playSound: false,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                isCompact ? 16 : 22,
                isCompact ? 12 : 16,
                isCompact ? 16 : 22,
                isCompact ? 12 : 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isActive ? GameColors.banana : Colors.white,
                  width: 4,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F25324B),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                lesson.inspectQuestion,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: GameColors.ink,
                  fontSize: isCompact ? 23 : 29,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KidChoiceCard extends StatelessWidget {
  const _KidChoiceCard({
    required this.choice,
    required this.isSelected,
    required this.isHighlighted,
    required this.isNarrating,
    required this.isCompact,
    required this.onTap,
  });

  final LessonChoice choice;
  final bool isSelected;
  final bool isHighlighted;
  final bool isNarrating;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDanger = choice.tone == ChoiceTone.danger;
    final accent = isDanger ? GameColors.danger : GameColors.safe;
    final isEmphasized = isHighlighted || isSelected;
    final highlightColor = isHighlighted ? GameColors.banana : accent;

    return Semantics(
      button: true,
      selected: isSelected,
      label: choice.accessibilityLabel,
      child: AnimatedScale(
        scale: isHighlighted ? 1.09 : (isSelected ? 1.04 : 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: Material(
          color: Colors.transparent,
          child: SmartStepsPressEffect(
            playSound: false,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(30),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isEmphasized ? highlightColor : Colors.white,
                    width: isHighlighted ? 8 : (isSelected ? 6 : 5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: highlightColor.withValues(
                        alpha: isHighlighted ? 0.42 : 0.18,
                      ),
                      blurRadius: isHighlighted ? 34 : 18,
                      spreadRadius: isHighlighted ? 4 : 0,
                      offset: const Offset(0, 12),
                    ),
                    if (isHighlighted)
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.82),
                        blurRadius: 0,
                        spreadRadius: 3,
                      ),
                    const BoxShadow(
                      color: Color(0x2425324B),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      choice.imageAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.10),
                            Colors.black.withValues(alpha: 0.34),
                          ],
                        ),
                      ),
                    ),
                    if (isHighlighted)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: GameColors.banana.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.94),
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: isCompact ? 8 : 12,
                      right: isCompact ? 8 : 12,
                      bottom: isCompact ? 8 : 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.28),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3325324B),
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 10 : 14,
                            vertical: isCompact ? 8 : 10,
                          ),
                          child: Text(
                            choice.label,
                            maxLines: isCompact ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: GameColors.ink,
                              fontSize: isCompact ? 17 : 22,
                              fontWeight: FontWeight.w900,
                              height: 1.08,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isNarrating)
                      Positioned(
                        left: isCompact ? 8 : 12,
                        top: isCompact ? 8 : 12,
                        child: _ListeningIndicator(color: GameColors.banana),
                      ),
                    if (isHighlighted)
                      const Positioned(
                        right: 12,
                        top: 12,
                        child: _CardTapSelectHint(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ListeningIndicator extends StatefulWidget {
  const _ListeningIndicator({required this.color});

  final Color color;

  @override
  State<_ListeningIndicator> createState() => _ListeningIndicatorState();
}

class _ListeningIndicatorState extends State<_ListeningIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withValues(alpha: 0.78),
              width: 4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2025324B),
                blurRadius: 16,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final phase = (_controller.value + index * 0.18) % 1.0;
              final height = 10 + Curves.easeInOutSine.transform(phase) * 17;

              return Container(
                width: 5,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: GameColors.ink,
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _CardTapSelectHint extends StatefulWidget {
  const _CardTapSelectHint();

  @override
  State<_CardTapSelectHint> createState() => _CardTapSelectHintState();
}

class _CardTapSelectHintState extends State<_CardTapSelectHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Nhấn lại để chọn đáp án',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pulse = Curves.easeInOutSine.transform(_controller.value);

          return Transform.scale(
            scale: 1 + pulse * 0.12,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: GameColors.banana,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.92),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: GameColors.banana.withValues(alpha: 0.32),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.touch_app_rounded,
                color: GameColors.ink,
                size: 31,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TapActionPill extends StatelessWidget {
  const _TapActionPill({
    required this.label,
    required this.icon,
    required this.color,
    required this.progress,
  });

  final String label;
  final IconData icon;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final pulse = 1 + math.sin(progress * math.pi * 2) * 0.08;

    return Semantics(
      label: label,
      child: Transform.scale(
        scale: pulse,
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.72), width: 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3325324B),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Icon(icon, color: GameColors.ink, size: 38),
        ),
      ),
    );
  }
}

class _SideFireworksPainter extends CustomPainter {
  const _SideFireworksPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    _paintFirework(
      canvas,
      size,
      fromLeft: true,
      delay: 0.00,
      color: GameColors.banana,
      endY: 0.28,
    );
    _paintFirework(
      canvas,
      size,
      fromLeft: false,
      delay: 0.16,
      color: GameColors.safe,
      endY: 0.24,
    );
    _paintFirework(
      canvas,
      size,
      fromLeft: true,
      delay: 0.38,
      color: GameColors.coral,
      endY: 0.44,
    );
    _paintFirework(
      canvas,
      size,
      fromLeft: false,
      delay: 0.54,
      color: GameColors.sky,
      endY: 0.42,
    );
    _paintFirework(
      canvas,
      size,
      fromLeft: true,
      delay: 0.68,
      color: GameColors.mint,
      endY: 0.18,
    );
    _paintFirework(
      canvas,
      size,
      fromLeft: false,
      delay: 0.76,
      color: GameColors.coral,
      endY: 0.20,
    );
    _paintFirework(
      canvas,
      size,
      fromLeft: true,
      delay: 0.86,
      color: GameColors.safe,
      endY: 0.56,
    );
    _paintFirework(
      canvas,
      size,
      fromLeft: false,
      delay: 0.94,
      color: GameColors.banana,
      endY: 0.58,
    );
  }

  void _paintFirework(
    Canvas canvas,
    Size size, {
    required bool fromLeft,
    required double delay,
    required Color color,
    required double endY,
  }) {
    final local = (progress + delay) % 1.0;
    final launchProgress = (local / 0.34).clamp(0.0, 1.0).toDouble();
    final burstProgress = ((local - 0.30) / 0.70).clamp(0.0, 1.0).toDouble();
    final start = Offset(
      fromLeft ? -18 : size.width + 18,
      size.height * (fromLeft ? 0.76 : 0.72),
    );
    final end = Offset(
      size.width * (fromLeft ? 0.30 : 0.70),
      size.height * endY,
    );
    final rocketPosition = Offset.lerp(
      start,
      end,
      Curves.easeOutCubic.transform(launchProgress),
    )!;

    if (local < 0.36) {
      final trailPaint = Paint()
        ..color = color.withValues(alpha: 0.48)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, rocketPosition, trailPaint);
      canvas.drawCircle(
        rocketPosition,
        7 + math.sin(local * math.pi * 9).abs() * 4,
        Paint()..color = Colors.white.withValues(alpha: 0.86),
      );
      canvas.drawCircle(
        rocketPosition,
        16,
        Paint()..color = color.withValues(alpha: 0.34),
      );
      return;
    }

    if (burstProgress <= 0) {
      return;
    }

    final fade = 1 - Curves.easeInCubic.transform(burstProgress);
    final radius = 24 + Curves.easeOutCubic.transform(burstProgress) * 104;
    final linePaint = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < 24; i++) {
      final angle = (math.pi * 2 / 24) * i + delay * math.pi * 2;
      final distance = radius * (0.70 + (i % 5) * 0.09);
      final particle =
          end + Offset(math.cos(angle), math.sin(angle)) * distance;
      final accent = i.isEven ? color : GameColors.banana;
      linePaint.color = accent.withValues(alpha: 0.44 * fade);
      dotPaint.color = accent.withValues(alpha: 0.90 * fade);

      canvas.drawLine(end, Offset.lerp(end, particle, 0.82)!, linePaint);
      canvas.drawCircle(particle, 4.2 + (i % 4), dotPaint);
    }

    canvas.drawCircle(
      end,
      12 + burstProgress * 16,
      Paint()..color = Colors.white.withValues(alpha: 0.70 * fade),
    );
  }

  @override
  bool shouldRepaint(covariant _SideFireworksPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CenterBurstPainter extends CustomPainter {
  const _CenterBurstPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.47, size.height * 0.45);
    final shortestSide = math.min(size.width, size.height);
    final colors = <Color>[
      GameColors.banana,
      GameColors.safe,
      GameColors.sky,
      GameColors.coral,
    ];

    for (var ring = 0; ring < 3; ring++) {
      final local = (progress + ring * 0.24) % 1.0;
      final eased = Curves.easeOutCubic.transform(local);
      final fade = 1 - Curves.easeInCubic.transform(local);
      final radius = shortestSide * (0.12 + eased * (0.28 + ring * 0.035));
      final stroke = Paint()
        ..strokeWidth = 2.8 - ring * 0.35
        ..strokeCap = StrokeCap.round;
      final dot = Paint()..style = PaintingStyle.fill;

      for (var i = 0; i < 28; i++) {
        final angle =
            (math.pi * 2 / 28) * i + progress * math.pi * (1.2 + ring * 0.25);
        final outer =
            center + Offset(math.cos(angle), math.sin(angle)) * radius;
        final inner =
            center + Offset(math.cos(angle), math.sin(angle)) * (radius * 0.54);
        final accent = colors[(i + ring) % colors.length];
        stroke.color = accent.withValues(alpha: 0.46 * fade);
        dot.color = accent.withValues(alpha: 0.88 * fade);

        canvas.drawLine(inner, outer, stroke);
        canvas.drawCircle(outer, 2.8 + (i % 4) * 0.8, dot);
      }

      canvas.drawCircle(
        center,
        radius * 0.36,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4
          ..color = Colors.white.withValues(alpha: 0.30 * fade),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CenterBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CelebrationRaysPainter extends CustomPainter {
  const _CelebrationRaysPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.48, size.height * 0.53);
    final maxRadius = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final rayPaint = Paint()..style = PaintingStyle.fill;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          maxRadius * 0.48,
          [
            GameColors.banana.withValues(alpha: 0.24),
            GameColors.safe.withValues(alpha: 0.10),
            Colors.transparent,
          ],
          [0, 0.56, 1],
        ),
    );

    for (var i = 0; i < 24; i++) {
      final angle = (math.pi * 2 / 24) * i + progress * math.pi * 0.42;
      final spread = math.pi / 30;
      final opacity = i.isEven ? 0.20 : 0.12;
      rayPaint.color = (i.isEven ? GameColors.banana : GameColors.mint)
          .withValues(alpha: opacity);

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + math.cos(angle - spread) * maxRadius,
          center.dy + math.sin(angle - spread) * maxRadius,
        )
        ..lineTo(
          center.dx + math.cos(angle + spread) * maxRadius,
          center.dy + math.sin(angle + spread) * maxRadius,
        )
        ..close();
      canvas.drawPath(path, rayPaint);
    }

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = Colors.white.withValues(alpha: 0.34);
    final ringPulse = 0.48 + progress * 0.56;
    canvas.drawCircle(center, maxRadius * 0.16 * ringPulse, ringPaint);
    canvas.drawCircle(
      center,
      maxRadius * 0.25 * ((progress + 0.42) % 1),
      ringPaint..color = GameColors.banana.withValues(alpha: 0.26),
    );
    canvas.drawCircle(
      center,
      maxRadius * 0.32 * ((progress + 0.72) % 1),
      ringPaint..color = GameColors.safe.withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(covariant _CelebrationRaysPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _WrongFeedbackOverlay extends StatefulWidget {
  const _WrongFeedbackOverlay({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    required this.onRestart,
    required this.onClose,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback onRestart;
  final VoidCallback onClose;

  @override
  State<_WrongFeedbackOverlay> createState() => _WrongFeedbackOverlayState();
}

class _WrongFeedbackOverlayState extends State<_WrongFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showHintMessage() {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _showHint = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Semantics(
        liveRegion: true,
        label: 'Sai rồi. ${widget.body}',
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _WrongFeedbackBackdrop(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 390;
                  final cardMaxWidth = compact ? constraints.maxWidth : 430.0;

                  return Column(
                    children: [
                      _WrongFeedbackTopBar(
                        onRestart: widget.onRestart,
                        onClose: widget.onClose,
                      ),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              compact ? 18 : 24,
                              88,
                              compact ? 18 : 24,
                              24,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: cardMaxWidth,
                              ),
                              child: _WrongFeedbackCard(
                                animation: _controller,
                                label: 'Sai rồi',
                                title: widget.title,
                                body: widget.body,
                                actionLabel: widget.actionLabel,
                                showHint: _showHint,
                                onAction: widget.onAction,
                                onHint: _showHintMessage,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WrongFeedbackBackdrop extends StatelessWidget {
  const _WrongFeedbackBackdrop();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFBF9F1).withValues(alpha: 0.70),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                LessonAssets.falseBackground,
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.72),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.38),
                      const Color(0xFFFFDAD6).withValues(alpha: 0.30),
                      const Color(0xFFFBF9F1).withValues(alpha: 0.62),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WrongFeedbackTopBar extends StatelessWidget {
  const _WrongFeedbackTopBar({required this.onRestart, required this.onClose});

  final VoidCallback onRestart;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Row(
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26735C00),
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pets_rounded,
                  color: GameColors.danger,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Row(
                  children: List.generate(5, (index) {
                    final active = index < 2;
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: active
                            ? GameColors.danger
                            : const Color(0xFFE4E3DB),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 8),
                const Text(
                  '2/3',
                  style: TextStyle(
                    color: GameColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _WrongTopIconButton(
            icon: Icons.refresh_rounded,
            label: 'Làm lại',
            onPressed: onRestart,
          ),
          const SizedBox(width: 8),
          _WrongTopIconButton(
            icon: Icons.close_rounded,
            label: 'Đóng',
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _WrongTopIconButton extends StatelessWidget {
  const _WrongTopIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: SmartStepsPressEffect(
        child: IconButton.filled(
          onPressed: onPressed,
          icon: Icon(icon, size: 24),
          style: IconButton.styleFrom(
            fixedSize: const Size(46, 46),
            backgroundColor: Colors.white.withValues(alpha: 0.88),
            foregroundColor: GameColors.muted,
            shape: const CircleBorder(),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.72)),
          ),
        ),
      ),
    );
  }
}

class _WrongFeedbackCard extends StatelessWidget {
  const _WrongFeedbackCard({
    required this.animation,
    required this.label,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.showHint,
    required this.onAction,
    required this.onHint,
  });

  final Animation<double> animation;
  final String label;
  final String title;
  final String body;
  final String actionLabel;
  final bool showHint;
  final VoidCallback onAction;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 58),
          padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFF0EEE6), width: 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26735C00),
                blurRadius: 32,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _WrongDecorativeStars(),
              _DockLabel(label),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GameColors.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mình thử cách an toàn hơn nhé.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: GameColors.muted,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.24,
                ),
              ),
              const SizedBox(height: 18),
              _WrongWarningBox(text: showHint ? _hintTextFor(body) : body),
              const SizedBox(height: 22),
              _WrongPrimaryButton(label: actionLabel, onPressed: onAction),
              const SizedBox(height: 14),
              _WrongSecondaryButton(onPressed: onHint),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final bounce = Curves.easeInOutSine.transform(animation.value);
            return Transform.translate(
              offset: Offset(0, -bounce * 8),
              child: child,
            );
          },
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 124,
                height: 60,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(80)),
                ),
              ),
              Image.asset(
                LessonAssets.mascotSulking,
                width: 148,
                height: 148,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _hintTextFor(String fallback) {
    final trimmed = fallback.trim();
    if (trimmed.isEmpty) {
      return 'Con hãy dừng lại và chọn cách nhờ người lớn giúp nhé.';
    }
    return trimmed;
  }
}

class _WrongDecorativeStars extends StatelessWidget {
  const _WrongDecorativeStars();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Icon(Icons.star_rounded, color: Color(0xFFFFDAD6), size: 22),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Icon(Icons.star_rounded, color: Color(0xFFFFD1A7), size: 18),
        ),
      ],
    );
  }
}

class _WrongWarningBox extends StatelessWidget {
  const _WrongWarningBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDAD6).withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFDAD6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_rounded, color: Color(0xFFBA1A1A), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: GameColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WrongPrimaryButton extends StatelessWidget {
  const _WrongPrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SmartStepsPressEffect(
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.refresh_rounded, size: 24),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(58),
          backgroundColor: GameColors.banana,
          foregroundColor: GameColors.ink,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: const BorderSide(color: Color(0xFFEBC23E), width: 3),
          ),
        ),
      ),
    );
  }
}

class _WrongSecondaryButton extends StatelessWidget {
  const _WrongSecondaryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SmartStepsPressEffect(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.lightbulb_rounded, size: 22),
        label: const Text('Xem gợi ý'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: GameColors.ink,
          side: const BorderSide(color: Color(0xFFD0C6AE), width: 2),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _WrongAnswerScrim extends StatefulWidget {
  const _WrongAnswerScrim({required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<_WrongAnswerScrim> createState() => _WrongAnswerScrimState();
}

class _WrongAnswerScrimState extends State<_WrongAnswerScrim>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _readyTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..repeat(reverse: true);
    _readyTimer = Timer(const Duration(milliseconds: 1200), widget.onFinished);
  }

  @override
  void dispose() {
    _readyTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -14,
      top: -10,
      right: -14,
      bottom: -14,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final flash = Curves.easeInOutSine.transform(_controller.value);

            return CustomPaint(
              painter: _WrongScreenBorderPainter(flash),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

class _WrongScreenBorderPainter extends CustomPainter {
  const _WrongScreenBorderPainter(this.flash);

  final double flash;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(math.min(36, size.shortestSide * 0.08));
    final rrect = RRect.fromRectAndRadius(rect.deflate(8), radius);
    final red = const Color(0xFFFF2424);
    final horizontalDepth = size.width / 3;
    final verticalDepth = size.height / 3;
    final edgeAlpha = 0.22 + flash * 0.36;
    final midAlpha = 0.10 + flash * 0.22;
    final edgeColors = [
      red.withValues(alpha: edgeAlpha),
      red.withValues(alpha: midAlpha),
      red.withValues(alpha: 0),
    ];
    const edgeStops = [0.0, 0.55, 1.0];

    void drawWarningBand(Rect band, Offset start, Offset end) {
      canvas.drawRect(
        band,
        Paint()..shader = ui.Gradient.linear(start, end, edgeColors, edgeStops),
      );
    }

    drawWarningBand(
      Rect.fromLTWH(0, 0, horizontalDepth, size.height),
      Offset.zero,
      Offset(horizontalDepth, 0),
    );
    drawWarningBand(
      Rect.fromLTWH(
        size.width - horizontalDepth,
        0,
        horizontalDepth,
        size.height,
      ),
      Offset(size.width, 0),
      Offset(size.width - horizontalDepth, 0),
    );
    drawWarningBand(
      Rect.fromLTWH(0, 0, size.width, verticalDepth),
      Offset.zero,
      Offset(0, verticalDepth),
    );
    drawWarningBand(
      Rect.fromLTWH(0, size.height - verticalDepth, size.width, verticalDepth),
      Offset(0, size.height),
      Offset(0, size.height - verticalDepth),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 38 + flash * 22
        ..color = red.withValues(alpha: 0.18 + flash * 0.24),
    );

    canvas.drawRRect(
      rrect.deflate(4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13 + flash * 8
        ..color = red.withValues(alpha: 0.56 + flash * 0.34),
    );

    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7 + flash * 4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.34 + flash * 0.34);
    const cornerLength = 76.0;
    const inset = 26.0;

    canvas.drawLine(
      const Offset(inset, inset),
      const Offset(inset + cornerLength, inset),
      cornerPaint,
    );
    canvas.drawLine(
      const Offset(inset, inset),
      const Offset(inset, inset + cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(size.width - inset - cornerLength, inset),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(size.width - inset, inset + cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(inset + cornerLength, size.height - inset),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(inset, size.height - inset - cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - inset, size.height - inset),
      Offset(size.width - inset - cornerLength, size.height - inset),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - inset, size.height - inset),
      Offset(size.width - inset, size.height - inset - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WrongScreenBorderPainter oldDelegate) {
    return oldDelegate.flash != flash;
  }
}

class _WrongAnswerAlert extends StatefulWidget {
  const _WrongAnswerAlert({
    required this.label,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.showRetryButton,
    required this.showTapPrompt,
    required this.onAction,
  });

  final String label;
  final String title;
  final String body;
  final String actionLabel;
  final bool showRetryButton;
  final bool showTapPrompt;
  final VoidCallback onAction;

  @override
  State<_WrongAnswerAlert> createState() => _WrongAnswerAlertState();
}

class _WrongAnswerAlertState extends State<_WrongAnswerAlert>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 980),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      top: 46,
      child: Semantics(
        liveRegion: true,
        label: 'Chưa đúng rồi. ${widget.body}',
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final entrance = Curves.easeOutBack.transform(
              _controller.value.clamp(0.0, 1.0),
            );
            final shakeWindow = 1 - _controller.value.clamp(0.0, 1.0);
            final shake =
                math.sin(_controller.value * math.pi * 12) * 12 * shakeWindow;

            return Opacity(
              opacity: entrance.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(shake, (1 - entrance) * -22),
                child: Transform.scale(
                  scale: 0.90 + entrance * 0.10,
                  child: child,
                ),
              ),
            );
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _GlassPanel(
                        padding: EdgeInsets.all(compact ? 16 : 22),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _WrongAlertIcon(compact: compact),
                            SizedBox(width: compact ? 12 : 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _DockLabel(widget.label),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: GameColors.ink,
                                      fontSize: compact ? 30 : 42,
                                      fontWeight: FontWeight.w900,
                                      height: 0.98,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    widget.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: GameColors.ink,
                                      fontSize: compact ? 20 : 26,
                                      fontWeight: FontWeight.w800,
                                      height: 1.08,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutBack,
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: widget.showRetryButton
                            ? _RetryPromptAction(
                                key: const ValueKey('retry-choice-button'),
                                label: widget.actionLabel,
                                color: GameColors.danger,
                                onPressed: widget.onAction,
                              )
                            : widget.showTapPrompt
                            ? Align(
                                key: const ValueKey('wrong-tap-prompt'),
                                alignment: Alignment.centerRight,
                                child: _TapActionPill(
                                  label: 'Chạm để tiếp tục',
                                  icon: Icons.touch_app_rounded,
                                  color: GameColors.danger,
                                  progress: _controller.value,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RetryPromptAction extends StatefulWidget {
  const _RetryPromptAction({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  State<_RetryPromptAction> createState() => _RetryPromptActionState();
}

class _RetryPromptActionState extends State<_RetryPromptAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: SmartStepsPressEffect(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final pulse = Curves.easeInOutSine.transform(_controller.value);
              final scale = 1 + pulse * 0.11;
              final lift = -pulse * 7;
              final angle = math.sin(_controller.value * math.pi * 2) * 0.16;

              return Transform.translate(
                offset: Offset(0, lift),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: GameColors.ink,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        shadows: [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.92),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                    Transform.rotate(
                      angle: angle,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.color.withValues(alpha: 0.76),
                              width: 5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.color.withValues(alpha: 0.24),
                                blurRadius: 30,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.refresh_rounded,
                            color: GameColors.ink,
                            size: 58,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WrongAlertIcon extends StatefulWidget {
  const _WrongAlertIcon({required this.compact});

  final bool compact;

  @override
  State<_WrongAlertIcon> createState() => _WrongAlertIconState();
}

class _WrongAlertIconState extends State<_WrongAlertIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 76.0 : 98.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.86, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pulse = _controller.value;

          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 1 + pulse * 0.24,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: GameColors.coral.withValues(
                      alpha: 0.10 + pulse * 0.12,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Transform.scale(scale: 1 + pulse * 0.035, child: child),
            ],
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: GameColors.danger,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: GameColors.coral.withValues(alpha: 0.26),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.priority_high_rounded,
            color: GameColors.ink,
            size: 52,
          ),
        ),
      ),
    );
  }
}

class _LessonRewardCelebration extends StatelessWidget {
  const _LessonRewardCelebration({
    required this.lesson,
    required this.onContinue,
    required this.onHome,
    required this.onReplay,
    required this.onClose,
    required this.isLastLesson,
    this.onNextLesson,
    this.onCompleteIsland,
  });

  final SafetyLesson lesson;
  final VoidCallback onContinue;
  final VoidCallback onHome;
  final VoidCallback onReplay;
  final VoidCallback onClose;
  final bool isLastLesson;
  final VoidCallback? onNextLesson;
  final VoidCallback? onCompleteIsland;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Hoàn thành màn chơi. Con đã vượt qua thử thách rất tốt.',
      child: DecoratedBox(
        decoration: const BoxDecoration(color: GameColors.cream),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                LessonAssets.rewardBackground,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                ),
              ),
            ),
            const Positioned.fill(child: _RewardFloatingDecorations()),
            const Positioned.fill(child: _RewardVfxLayer()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 520;
                  final horizontalPadding = compact ? 20.0 : 32.0;

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      compact ? 28 : 36,
                      horizontalPadding,
                      compact ? 18 : 28,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - (compact ? 46 : 64),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _RewardHeader(lesson: lesson, compact: compact),
                          SizedBox(height: compact ? 20 : 26),
                          _RewardCard(lesson: lesson, compact: compact),
                          SizedBox(height: compact ? 16 : 22),
                          _RewardSkillSummary(lesson: lesson),
                          SizedBox(height: compact ? 24 : 34),
                          _RewardActions(
                            onContinue: onContinue,
                            onHome: onHome,
                            onReplay: onReplay,
                            onClose: onClose,
                            isLastLesson: isLastLesson,
                            onNextLesson: onNextLesson,
                            onCompleteIsland: onCompleteIsland,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardHeader extends StatelessWidget {
  const _RewardHeader({required this.lesson, required this.compact});

  final SafetyLesson lesson;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.88, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(scale: value, child: child),
        );
      },
      child: Column(
        children: [
          Text(
            'Hoàn thành màn chơi!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GameColors.banana,
              fontSize: compact ? 34 : 46,
              fontWeight: FontWeight.w900,
              height: 1.05,
              shadows: const [
                Shadow(color: Colors.white, blurRadius: 12),
                Shadow(color: Color(0x3325324B), offset: Offset(0, 3)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Con đã vượt qua thử thách rất tốt',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GameColors.ink,
              fontSize: compact ? 18 : 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            lesson.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: GameColors.muted,
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.lesson, required this.compact});

  final SafetyLesson lesson;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: EdgeInsets.all(compact ? 16 : 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _RewardLine(
            icon: Icons.star_rounded,
            label: '+3 Safety Stars',
            color: GameColors.banana,
            background: Color(0x4DFFD54F),
          ),
          const SizedBox(height: 12),
          const _RewardLine(
            icon: Icons.monetization_on_rounded,
            label: '+20 Xu',
            color: Color(0xFF8B5000),
            background: Color(0x3DFFD1A7),
          ),
          const SizedBox(height: 12),
          _RewardBadge(skillName: lesson.topic),
        ],
      ),
    );
  }
}

class _RewardLine extends StatelessWidget {
  const _RewardLine({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  const _RewardBadge({required this.skillName});

  final String skillName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GameColors.mint.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: GameColors.safe.withValues(alpha: 0.34),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F25324B),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: GameColors.safe,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Huy hiệu mới:',
                  style: TextStyle(
                    color: GameColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  skillName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GameColors.safe,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardSkillSummary extends StatelessWidget {
  const _RewardSkillSummary({required this.lesson});

  final SafetyLesson lesson;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          const Text(
            'Kỹ năng của con',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GameColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RewardSkillTile(
                  icon: Icons.visibility_rounded,
                  label: lesson.topic,
                  color: GameColors.safe,
                  background: GameColors.mint.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RewardSkillTile(
                  icon: Icons.check_circle_rounded,
                  label: 'Chọn đúng',
                  color: const Color(0xFF3C7DD9),
                  background: const Color(0xFFEAF3FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RewardSkillTile(
                  icon: Icons.bolt_rounded,
                  label: 'Phản xạ an toàn',
                  color: const Color(0xFF8B5000),
                  background: const Color(0xFFFFF0D9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardSkillTile extends StatelessWidget {
  const _RewardSkillTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(21),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (_) => Icon(Icons.star_rounded, color: color, size: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardActions extends StatelessWidget {
  const _RewardActions({
    required this.onContinue,
    required this.onHome,
    required this.onReplay,
    required this.onClose,
    required this.isLastLesson,
    this.onNextLesson,
    this.onCompleteIsland,
  });

  final VoidCallback onContinue;
  final VoidCallback onHome;
  final VoidCallback onReplay;
  final VoidCallback onClose;
  final bool isLastLesson;
  final VoidCallback? onNextLesson;
  final VoidCallback? onCompleteIsland;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SmartStepsPressEffect(
          child: FilledButton.icon(
            key: const ValueKey('lesson-reward-continue-button'),
            onPressed: onContinue,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward_rounded, size: 30),
            label: const Text('Tiếp tục'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(62),
              backgroundColor: GameColors.banana,
              foregroundColor: GameColors.ink,
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: const BorderSide(color: Colors.white, width: 4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _RewardActionButton(
                label: 'Về nhà',
                icon: Icons.home_rounded,
                onPressed: onHome,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: _RewardActionButton(
                label: 'Chơi lại',
                icon: Icons.refresh_rounded,
                onPressed: onReplay,
                showLabel: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RewardActionButton(
                label: 'Đóng',
                icon: Icons.close_rounded,
                onPressed: onClose,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RewardActionButton extends StatelessWidget {
  const _RewardActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.showLabel = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: SmartStepsPressEffect(
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 26),
          label: showLabel
              ? Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)
              : const SizedBox.shrink(),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 54),
            padding: EdgeInsets.symmetric(horizontal: showLabel ? 16 : 0),
            backgroundColor: Colors.white.withValues(alpha: 0.92),
            foregroundColor: GameColors.ink,
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(
                color: GameColors.banana.withValues(alpha: 0.50),
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardVfxLayer extends StatefulWidget {
  const _RewardVfxLayer();

  @override
  State<_RewardVfxLayer> createState() => _RewardVfxLayerState();
}

class _RewardVfxLayerState extends State<_RewardVfxLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _CelebrationRaysPainter(progress)),
              CustomPaint(painter: _CenterBurstPainter(progress)),
              CustomPaint(painter: _SideFireworksPainter(progress)),
              CustomPaint(painter: _RewardConfettiPainter(progress)),
              const _RewardGlowWash(),
            ],
          );
        },
      ),
    );
  }
}

class _RewardGlowWash extends StatelessWidget {
  const _RewardGlowWash();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.18),
          radius: 0.82,
          colors: [
            Colors.white.withValues(alpha: 0.22),
            GameColors.banana.withValues(alpha: 0.10),
            Colors.transparent,
          ],
          stops: const [0, 0.44, 1],
        ),
      ),
    );
  }
}

class _RewardConfettiPainter extends CustomPainter {
  const _RewardConfettiPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = <Color>[
      GameColors.banana,
      GameColors.safe,
      GameColors.coral,
      const Color(0xFF3C7DD9),
      GameColors.mint,
    ];
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < 44; i++) {
      final seed = i * 37.0;
      final xBase = ((seed * 19) % 100) / 100;
      final speed = 0.62 + (i % 7) * 0.055;
      final phase = (progress * speed + (i % 11) / 11) % 1.0;
      final drift = math.sin((phase * math.pi * 2) + i) * (12 + (i % 5) * 4);
      final x = xBase * size.width + drift;
      final y = phase * (size.height + 96) - 48;
      final width = 5.0 + (i % 4) * 2.0;
      final height = 9.0 + (i % 5) * 2.2;
      final rotation = progress * math.pi * (1.6 + (i % 6) * 0.22) + i;
      final opacity = phase < 0.08
          ? phase / 0.08
          : phase > 0.86
          ? (1 - phase) / 0.14
          : 1.0;
      paint.color = colors[i % colors.length].withValues(alpha: 0.68 * opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: width,
        height: height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RewardConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _RewardFloatingDecorations extends StatelessWidget {
  const _RewardFloatingDecorations();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: const [
          Positioned(
            left: 34,
            top: 42,
            child: Icon(
              Icons.grade_rounded,
              color: Color(0x99FFD54F),
              size: 42,
            ),
          ),
          Positioned(
            right: 24,
            top: 138,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Color(0x668B5000),
              size: 44,
            ),
          ),
          Positioned(
            right: 58,
            bottom: 128,
            child: Icon(
              Icons.favorite_rounded,
              color: Color(0x6678DC77),
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _StageFrame extends StatelessWidget {
  const _StageFrame({required this.child, this.semanticLabel});

  final Widget child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final frame = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: GameColors.sky,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.74),
          width: 7,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2425324B),
            blurRadius: 34,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );

    if (semanticLabel == null) {
      return frame;
    }

    return Semantics(label: semanticLabel, child: frame);
  }
}

class _WarmSceneOverlay extends StatelessWidget {
  const _WarmSceneOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            GameColors.cream.withValues(alpha: 0.60),
            Colors.white.withValues(alpha: 0.10),
          ],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.54, 0.7),
            radius: 0.55,
            colors: [
              GameColors.banana.withValues(alpha: 0.34),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.76),
              width: 4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2425324B),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final background = color ?? Colors.white.withValues(alpha: 0.78);

    return SmartStepsPressEffect(
      enabled: onPressed != null,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          backgroundColor: background,
          foregroundColor: GameColors.ink,
          disabledBackgroundColor: background.withValues(alpha: 0.58),
          disabledForegroundColor: GameColors.ink.withValues(alpha: 0.48),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.82),
              width: 3,
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: SmartStepsPressEffect(
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size(52, 52),
            fixedSize: const Size(52, 52),
            padding: EdgeInsets.zero,
            backgroundColor: Colors.white.withValues(alpha: 0.82),
            foregroundColor: GameColors.ink,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.82),
                width: 3,
              ),
            ),
          ),
          child: Icon(icon, size: 26),
        ),
      ),
    );
  }
}

class _SmallCircleIconButton extends StatelessWidget {
  const _SmallCircleIconButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: SmartStepsPressEffect(
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size(42, 42),
            fixedSize: const Size(42, 42),
            padding: EdgeInsets.zero,
            backgroundColor: Colors.white.withValues(alpha: 0.88),
            foregroundColor: GameColors.ink,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(21),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.9),
                width: 3,
              ),
            ),
          ),
          child: Icon(icon, size: 23),
        ),
      ),
    );
  }
}

class _SafetyDots extends StatelessWidget {
  const _SafetyDots({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.80),
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F25324B),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SafetyDot(
            color: const Color(0xFFFF6B6B),
            isActive: isActive,
            delay: 0,
          ),
          const SizedBox(width: 8),
          _SafetyDot(color: GameColors.safe, isActive: isActive, delay: 100),
          const SizedBox(width: 8),
          _SafetyDot(color: GameColors.banana, isActive: isActive, delay: 200),
        ],
      ),
    );
  }
}

class _SafetyDot extends StatefulWidget {
  const _SafetyDot({
    required this.color,
    required this.isActive,
    required this.delay,
  });

  final Color color;
  final bool isActive;
  final int delay;

  @override
  State<_SafetyDot> createState() => _SafetyDotState();
}

class _SafetyDotState extends State<_SafetyDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );
    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dy = widget.isActive ? -3 * _controller.value : 0.0;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x2425324B),
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockLabel extends StatelessWidget {
  const _DockLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF476070),
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.7,
        height: 1,
      ),
    );
  }
}

class _Sparkle extends StatefulWidget {
  const _Sparkle({required this.size});

  final double size;

  @override
  State<_Sparkle> createState() => _SparkleState();
}

class _SparkleState extends State<_Sparkle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.7 + _controller.value * 0.55,
          child: Opacity(
            opacity: 0.42 + _controller.value * 0.55,
            child: child,
          ),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7A8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFF7A8).withValues(alpha: 0.30),
              blurRadius: 9,
              spreadRadius: 5,
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingImage extends StatefulWidget {
  const _FloatingImage({
    required this.asset,
    required this.width,
    required this.delay,
  });

  final String asset;
  final double width;
  final Duration delay;

  @override
  State<_FloatingImage> createState() => _FloatingImageState();
}

class _FloatingImageState extends State<_FloatingImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    Future<void>.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dy = math.sin(_controller.value * math.pi) * -5;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: Image.asset(
        widget.asset,
        width: widget.width,
        fit: BoxFit.contain,
      ),
    );
  }
}
