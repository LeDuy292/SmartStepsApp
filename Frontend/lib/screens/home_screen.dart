import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:smartsteps/models/child_profile.dart';
import 'package:smartsteps/models/situation.dart';
import 'package:smartsteps/services/situation_service.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/supabase_config.dart';
import '../services/app_audio_controller.dart';
import '../services/local_profile_storage.dart';
import '../services/learning_service.dart';
import '../services/premium_service.dart';
import '../services/registration_avatar_service.dart';
import '../services/analytics_service.dart';
import '../theme/duo_theme.dart';
import '../utils/platform_environment.dart';
import '../widgets/duo_components.dart';
import '../widgets/smartsteps_press_effect.dart';
import '../services/auth_service.dart';
import '../view_models/registration_view_model.dart';
import 'app_feedback_dialog.dart';
import 'learn_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'quick_review_screen.dart';
import 'register_screen.dart';

part 'lesson/lesson_game_section.dart';

Future<void> runSmartStepsApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(_outsidePortraitOrientations);
  await initializeSupabaseIfConfigured();
  await _configureGlobalAudio();
  _configureImageCache();
  runApp(const _SmartStepsBootstrapApp());
}

Future<void> _configureGlobalAudio() async {
  try {
    await AudioPlayer.global.setAudioContext(_voiceAudioContext);
  } catch (error, stackTrace) {
    debugPrint('SmartSteps voice global audio context failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

void _configureImageCache() {
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSize = math.max(imageCache.maximumSize, 180);
  imageCache.maximumSizeBytes = math.max(
    imageCache.maximumSizeBytes,
    128 * 1024 * 1024,
  );
}

class _SmartStepsBootstrapApp extends StatefulWidget {
  const _SmartStepsBootstrapApp();

  @override
  State<_SmartStepsBootstrapApp> createState() =>
      _SmartStepsBootstrapAppState();
}

class _SmartStepsBootstrapAppState extends State<_SmartStepsBootstrapApp> {
  Future<void>? _preloadFuture;
  double _loadingProgress = 0.0;
  bool _isPreloadingDone = false;
  bool _showSplash = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _preloadFuture ??= _preloadImageAssets();
  }

  Future<void> _preloadImageAssets() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final imageAssets = manifest
        .listAssets()
        .where(_isPreloadableImageAsset)
        .toList(growable: false);

    if (imageAssets.isEmpty) {
      if (mounted) {
        setState(() {
          _loadingProgress = 1.0;
          _isPreloadingDone = true;
        });
      }
      return;
    }

    final startTime = DateTime.now();
    int loaded = 0;
    for (final asset in imageAssets) {
      if (!mounted) {
        return;
      }

      try {
        await precacheImage(AssetImage(asset), context);
      } catch (error, stackTrace) {
        debugPrint('SmartSteps image preload failed for $asset: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      loaded++;

      // Delay slightly between each asset to spacing out the loading CPU spike
      // and ensure a smooth visual experience of about 2 - 2.5 seconds
      await Future.delayed(const Duration(milliseconds: 55));

      if (mounted) {
        setState(() {
          _loadingProgress = loaded / imageAssets.length;
        });
      }
    }

    // Ensure it shows for at least 2.5s
    final elapsed = DateTime.now().difference(startTime);
    const minDuration = Duration(milliseconds: 2500);
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }

    if (mounted) {
      setState(() {
        _isPreloadingDone = true;
      });
    }
  }

  bool _isPreloadableImageAsset(String asset) {
    final lower = asset.toLowerCase();
    return lower.startsWith('assets/images/') &&
        (lower.endsWith('.webp') ||
            lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.webp'));
  }

  @override
  Widget build(BuildContext context) {
    if (!_showSplash) {
      return SmartStepsApp(enableAudio: true);
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartSteps',
      theme: DuoTheme.light,
      home: _SmartStepsBootSplash(
        progress: _loadingProgress,
        isDone: _isPreloadingDone,
        onFinished: () {
          if (mounted) {
            setState(() {
              _showSplash = false;
            });
          }
        },
      ),
    );
  }
}

class _SmartStepsBootSplash extends StatefulWidget {
  const _SmartStepsBootSplash({
    required this.progress,
    required this.isDone,
    required this.onFinished,
  });

  final double progress;
  final bool isDone;
  final VoidCallback onFinished;

  @override
  State<_SmartStepsBootSplash> createState() => _SmartStepsBootSplashState();
}

class _SmartStepsBootSplashState extends State<_SmartStepsBootSplash> {
  late Timer _textTimer;
  int _textIndex = 0;
  bool _hasCalledFinished = false;

  final List<String> _loadingTexts = [
    'Đang nạp năng lượng tự lập cho bé...',
    'Cùng thắt dây an toàn để chuẩn bị xuất phát nào...',
    'Các bạn nhỏ ngoan ngoãn đang đợi bé đó...',
    'Đang chuẩn bị trang phục siêu anh hùng nhí...',
    'Dọn dẹp đồ chơi gọn gàng để sẵn sàng phiêu lưu nhé...',
    'Bé hãy nhớ đi bộ trên vạch kẻ đường an toàn nhé...',
    'Nhặt rác bỏ vào thùng để bảo vệ hành tinh xanh của chúng ta...',
  ];

  @override
  void initState() {
    super.initState();
    _textTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _textIndex = (_textIndex + 1) % _loadingTexts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _textTimer.cancel();
    super.dispose();
  }

  void _checkFinished(double currentVal) {
    if (currentVal >= 0.99 && widget.isDone && !_hasCalledFinished) {
      _hasCalledFinished = true;
      // Small delay at 100% so child can see the superhero badge
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          widget.onFinished();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7), // Soft cream white background
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 620,
                    minHeight: constraints.maxHeight - 40,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Header
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: DuoColors.primaryYellow.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: DuoColors.primaryYellow.withValues(
                                    alpha: 0.4,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                              child: const Text(
                                'HÀNH TRÌNH SIÊU ANH HÙNG NHÍ',
                                style: TextStyle(
                                  color: DuoColors.tactileShadow,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'SmartSteps',
                              style: TextStyle(
                                color: DuoColors.textPrimary,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),

                        // Middle: Loading Road Path
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0.0,
                            end: widget.progress,
                          ),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          onEnd: () {
                            _checkFinished(widget.progress);
                          },
                          builder: (context, val, child) {
                            // Run the finished check if progress updates to 1.0 but animation hasn't ended
                            if (val >= 0.99) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _checkFinished(val);
                              });
                            }

                            return LayoutBuilder(
                              builder: (context, roadConstraints) {
                                final parentWidth = roadConstraints.maxWidth;
                                final roadStartX = 32.0;
                                final roadEndX = parentWidth - 32.0;
                                final roadWidth = roadEndX - roadStartX;

                                // Mascot bounce and tilt
                                final bounceFactor = math
                                    .sin(val * math.pi * 20)
                                    .abs();
                                final yBounce = val >= 0.99
                                    ? 0.0
                                    : -bounceFactor * 12.0;
                                final tiltAngle = val >= 0.99
                                    ? 0.0
                                    : math.sin(val * math.pi * 20) * 0.08;

                                return SizedBox(
                                  height: 180,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Road background
                                      Positioned(
                                        left: roadStartX,
                                        right: 32.0,
                                        bottom: 50,
                                        child: Container(
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: DuoColors.lockedGray,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.04,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Active/completed road path
                                      Positioned(
                                        left: roadStartX,
                                        bottom: 50,
                                        child: Container(
                                          height: 16,
                                          width: roadWidth * val,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(
                                                  0xFF4ADE80,
                                                ), // Tailwind green-400
                                                Color(
                                                  0xFF22C55E,
                                                ), // Tailwind green-500
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Milestone 1 (25%): Self-care Bed
                                      _buildMilestone(
                                        left:
                                            roadStartX + roadWidth * 0.25 - 23,
                                        bottom: 35,
                                        isActive: val >= 0.25,
                                        icon: Icons.bed_rounded,
                                        color: Colors.blue,
                                        label: 'Tự lập',
                                      ),

                                      // Milestone 2 (50%): Road Safety
                                      _buildMilestone(
                                        left:
                                            roadStartX + roadWidth * 0.50 - 23,
                                        bottom: 35,
                                        isActive: val >= 0.50,
                                        icon: Icons.traffic_rounded,
                                        color: Colors.orange,
                                        label: 'An toàn',
                                      ),

                                      // Milestone 3 (75%): Environment Trash
                                      _buildMilestone(
                                        left:
                                            roadStartX + roadWidth * 0.75 - 23,
                                        bottom: 35,
                                        isActive: val >= 0.75,
                                        icon: Icons.recycling_rounded,
                                        color: Colors.green,
                                        label: 'Môi trường',
                                      ),

                                      // Milestone 4 (100%): Superhero Badge
                                      _buildMilestone(
                                        left: roadStartX + roadWidth * 1.0 - 23,
                                        bottom: 35,
                                        isActive: val >= 0.99,
                                        icon: Icons.workspace_premium_rounded,
                                        color: Colors.amber,
                                        label: 'Anh hùng',
                                        isFinish: true,
                                      ),

                                      // Moving Mascot Cat
                                      Positioned(
                                        left:
                                            roadStartX + (roadWidth * val) - 40,
                                        bottom: 60, // Sits above the road
                                        child: Transform.translate(
                                          offset: Offset(0, yBounce),
                                          child: Transform.rotate(
                                            angle: tiltAngle,
                                            child: SizedBox(
                                              width: 80,
                                              height: 80,
                                              child: Image.asset(
                                                'assets/images/mascot/mascot-cat-happy-wave.webp',
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        // Bottom: Custom Copywriting & Progress Bubble
                        Column(
                          children: [
                            // Text Bubble
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: DuoColors.border.withValues(
                                    alpha: 0.6,
                                  ),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                                child: Text(
                                  _loadingTexts[_textIndex],
                                  key: ValueKey<int>(_textIndex),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: DuoColors.textSecondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),

                            // Progress Percentage
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: DuoColors.softYellow,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                'Đang tải: ${(widget.progress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: DuoColors.darkYellow,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMilestone({
    required double left,
    required double bottom,
    required bool isActive,
    required IconData icon,
    required Color color,
    required String label,
    bool isFinish = false,
  }) {
    final activeColor = isFinish ? const Color(0xFFFACC15) : color;

    return Positioned(
      left: left,
      bottom: bottom,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            width: isActive ? 46 : 40,
            height: isActive ? 46 : 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? activeColor : DuoColors.lockedGray,
                width: isActive ? 3.0 : 2.0,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Icon(
                icon,
                color: isActive
                    ? activeColor
                    : DuoColors.textSecondary.withValues(alpha: 0.6),
                size: isActive ? 24 : 20,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? DuoColors.textPrimary
                  : DuoColors.textSecondary.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SmartStepsApp extends StatefulWidget {
  SmartStepsApp({
    super.key,
    SituationService? situationService,
    LocalProfileStorage? profileStorage,
    AuthGateway? authGateway,
    this.learningGateway,
    this.showPremiumOfferAfterLogin = false,
    this.showInitialSurveyAfterLogin = true,
    this.enableAudio = false,
  }) : situationService = situationService ?? SituationService(),
       profileStorage = profileStorage ?? const LocalProfileStorage(),
       authGateway = authGateway ?? AuthService();

  final SituationService situationService;
  final LocalProfileStorage profileStorage;
  final AuthGateway authGateway;
  final LearningGateway? learningGateway;
  final bool showPremiumOfferAfterLogin;
  final bool showInitialSurveyAfterLogin;
  final bool enableAudio;

  @override
  State<SmartStepsApp> createState() => _SmartStepsAppState();
}

class _SmartStepsAppState extends State<SmartStepsApp> {
  final SmartStepsAudioController _audioController =
      SmartStepsAudioController();
  bool _hasCompletedInitialSurvey = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.enableAudio && !kIsWeb) {
        unawaited(_audioController.startBackgroundMusic());
      }
    });
  }

  @override
  void dispose() {
    _audioController.dispose();
    super.dispose();
  }

  void _openCatalog(NavigatorState navigator) {
    navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SmartStepsCatalogPage(
          situationService: widget.situationService,
          profileStorage: widget.profileStorage,
          showPremiumOffer: widget.showPremiumOfferAfterLogin,
          onLogout: _handleLogout,
          learningGateway: widget.learningGateway,
        ),
      ),
    );
  }

  void _handleLogin(BuildContext context) {
    if (widget.enableAudio) {
      unawaited(_audioController.ensureBackgroundMusicPlaying());
    }
    unawaited(_handleLoginAsync(Navigator.of(context)));
  }

  void _handleRegistrationCompleted(BuildContext context) {
    if (widget.enableAudio) {
      unawaited(_audioController.ensureBackgroundMusicPlaying());
    }
    _openCatalog(Navigator.of(context));
  }

  Future<void> _handleLoginAsync(NavigatorState navigator) async {
    final hasProfile = await widget.profileStorage.hasProfile();
    if (!mounted) {
      return;
    }

    final shouldShowOnboarding =
        widget.showInitialSurveyAfterLogin &&
        !_hasCompletedInitialSurvey &&
        !hasProfile;
    if (!shouldShowOnboarding) {
      _openCatalog(navigator);
      return;
    }

    navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: (registrationContext) => RegisterScreen(
          profileStorage: widget.profileStorage,
          viewModel: RegistrationViewModel(
            profileStorage: widget.profileStorage,
            isSurveyOnly: true,
          ),
          onRegistrationCompleted: (context) {
            _hasCompletedInitialSurvey = true;
            _openCatalog(Navigator.of(registrationContext));
          },
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    _hasCompletedInitialSurvey = false;
    await widget.authGateway.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(
          profileStorage: widget.profileStorage,
          onLogin: _handleLogin,
          onRegistrationCompleted: _handleRegistrationCompleted,
          authGateway: widget.authGateway,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartSteps',
      theme: DuoTheme.light,
      home: LoginScreen(
        profileStorage: widget.profileStorage,
        onLogin: _handleLogin,
        onRegistrationCompleted: _handleRegistrationCompleted,
        authGateway: widget.authGateway,
      ),
    );

    if (!widget.enableAudio) {
      return app;
    }

    return SmartStepsAudioScope(controller: _audioController, child: app);
  }
}

class SmartStepsCatalogPage extends StatefulWidget {
  const SmartStepsCatalogPage({
    super.key,
    required this.situationService,
    required this.profileStorage,
    required this.onLogout,
    this.learningGateway,
    this.showPremiumOffer = false,
  });

  final SituationService situationService;
  final LocalProfileStorage profileStorage;
  final void Function(BuildContext context) onLogout;
  final LearningGateway? learningGateway;
  final bool showPremiumOffer;

  @override
  State<SmartStepsCatalogPage> createState() => _SmartStepsCatalogPageState();
}

class _SmartStepsCatalogPageState extends State<SmartStepsCatalogPage>
    with WidgetsBindingObserver {
  List<_IslandCatalogEntry> _islands = _fallbackIslandEntries;
  List<SituationSummary> _situations = const [];
  int? _selectedIslandId;
  int _selectedTabIndex = 0;
  SafetyLesson? _activeLesson;
  bool _isLoadingCatalog = false;
  bool _isLoadingIslandSituations = false;
  int? _loadingSituationId;
  String? _catalogError;
  ChildProfile? _profile;
  Set<int> _serverCompletedSituationIds = const {};
  Map<int, int> _serverCurrentSteps = const {};
  bool _isFeedbackPromptOpen = false;

  SituationService get _situationService => widget.situationService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_enterCatalogViewingMode());
    unawaited(_loadProfileAndPaymentReturn());
    unawaited(_loadCatalog());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          SmartStepsAudioScope.maybeOf(context)?.ensureBackgroundMusicPlaying(),
        );
        unawaited(_showStartupPrompts());
      }
    });
  }

  Future<void> _showStartupPrompts() async {
    if (widget.showPremiumOffer) {
      await _showPremiumOfferIfNeeded();
    }

    await _maybeShowFeedbackAfterFirstExit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(widget.profileStorage.markFirstExitObserved());
    }

    if (state == AppLifecycleState.resumed) {
      unawaited(_maybeShowFeedbackAfterFirstExit());
    }
  }

  Future<void> _maybeShowFeedbackAfterFirstExit() async {
    if (_isFeedbackPromptOpen) {
      return;
    }

    final shouldPrompt = await widget.profileStorage
        .shouldPromptFeedbackAfterFirstExit();
    if (!mounted || !shouldPrompt) {
      return;
    }

    _isFeedbackPromptOpen = true;
    await widget.profileStorage.markFirstExitFeedbackPromptShown();
    if (!mounted) {
      _isFeedbackPromptOpen = false;
      return;
    }

    final submitted = await showAppFeedbackDialog(
      context,
      profileStorage: widget.profileStorage,
      source: 'after_first_exit',
    );

    _isFeedbackPromptOpen = false;
    if (!mounted || submitted != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu đánh giá. Cảm ơn phản hồi của bạn.'),
      ),
    );
  }

  Future<void> _loadProfile() async {
    var profile = await widget.profileStorage.readProfile();
    Set<int> completed = const {};
    Map<int, int> currentSteps = const {};
    try {
      final progressFuture = LearningService().getProgress();
      final premiumFuture = PremiumService().getStatus();
      final progress = await progressFuture;
      final premium = await premiumFuture;
      completed = progress.completedSituationIds;
      currentSteps = <int, int>{
        for (final item in progress.items) item.situationId: item.currentStep,
      };
      if (profile != null && profile.isPremium != premium.hasPremium) {
        profile = profile.copyWith(
          isPremium: premium.hasPremium,
          premiumCode: premium.planCode,
          premiumActivatedAt: premium.hasPremium ? DateTime.now() : null,
        );
        await widget.profileStorage.saveProfile(profile);
      }
    } catch (error) {
      debugPrint('SmartSteps account state sync failed: $error');
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _profile = profile;
      _serverCompletedSituationIds = completed;
      _serverCurrentSteps = currentSteps;
    });
  }

  Future<void> _loadProfileAndPaymentReturn() async {
    await _loadProfile();
    if (!kIsWeb || !mounted) return;

    final query = Uri.base.queryParameters;
    final paymentResult = query['premiumPayment'];
    final orderCode = int.tryParse(query['orderCode'] ?? '');
    if (paymentResult == null) return;

    if (paymentResult == 'cancel') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn đã hủy thanh toán Premium.')),
      );
      return;
    }

    if (paymentResult != 'success' || orderCode == null) return;

    try {
      final status = await PremiumService().confirmPayment(orderCode);
      if (!status.hasPremium) {
        throw const PremiumServiceException(
          'PayOS chưa xác nhận giao dịch. Vui lòng thử lại sau ít phút.',
        );
      }

      final current = await widget.profileStorage.readProfile();
      if (current == null || !mounted) return;
      final profile = current.copyWith(
        isPremium: true,
        premiumCode: status.planCode,
        premiumActivatedAt: DateTime.now(),
      );
      await widget.profileStorage.saveProfile(profile);
      if (!mounted) return;
      setState(() => _profile = profile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanh toán thành công. Đã mở khóa Premium!')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chưa xác nhận được thanh toán: $error')),
      );
    }
  }

  Future<void> _showPremiumOfferIfNeeded() async {
    final profile = _profile ?? await widget.profileStorage.readProfile();
    if (!mounted || (profile?.isPremium ?? false)) {
      return;
    }

    await _showPremiumOffer();
  }

  Future<void> _showPremiumOffer() async {
    // 1. Hiển thị popup toán học bảo vệ trước
    final isParent = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Bắt buộc phải nhập hoặc bấm hủy
      builder: (_) => const _ParentalGateDialog(),
    );

    // 2. Nếu trả lời sai hoặc bấm Hủy thì dừng lại, không hiện form nhập mã
    if (isParent != true) {
      return;
    }

    if (!mounted) return;

    // 3. Nếu đúng, tiếp tục hiển thị popup Premium Offer ban đầu
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PremiumOfferDialog(
        profileStorage: widget.profileStorage,
        onPremiumActivated: (profile) {
          setState(() {
            _profile = profile;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã nâng cấp lên Premium.')),
          );
        },
      ),
    );
  }

  void _showPremiumRequired(SituationSummary summary) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${summary.title} cần Premium. Nhập mã PREMIUM để mở khóa.',
        ),
      ),
    );
    unawaited(_showPremiumOffer());
  }

  Future<void> _enterCatalogViewingMode() async {
    try {
      await SystemChrome.setPreferredOrientations(_outsidePortraitOrientations);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (_) {
      // Some desktop/test hosts do not expose system chrome controls.
    }
  }

  Future<void> _loadCatalog() async {
    if (!_situationService.isEnabled) {
      setState(() {
        _islands = _fallbackIslandEntries;
        _situations = const [];
        _selectedIslandId = null;
        _activeLesson = null;
        _isLoadingCatalog = false;
        _isLoadingIslandSituations = false;
        _catalogError = null;
      });
      return;
    }

    setState(() {
      _isLoadingCatalog = true;
      _isLoadingIslandSituations = false;
      _catalogError = null;
      _activeLesson = null;
      _loadingSituationId = null;
    });

    try {
      final islands = await _situationService.getIslands();
      if (!mounted) {
        return;
      }

      setState(() {
        _islands = islands.isEmpty
            ? _fallbackIslandEntries
            : islands
                  .map(_IslandCatalogEntry.fromSummary)
                  .toList(growable: false);
        _situations = const [];
        _selectedIslandId = null;
        _activeLesson = null;
        _isLoadingCatalog = false;
        _catalogError = null;
      });
    } catch (error, stackTrace) {
      debugPrint('SmartSteps situation catalog failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }

      setState(() {
        _islands = _fallbackIslandEntries;
        _situations = const [];
        _selectedIslandId = null;
        _activeLesson = null;
        _isLoadingCatalog = false;
        _isLoadingIslandSituations = false;
        _catalogError = null;
      });
    }
  }

  void _selectIsland(_IslandCatalogEntry island) {
    setState(() {
      _selectedIslandId = island.islandId;
      _situations = const [];
      _activeLesson = null;
      _loadingSituationId = null;
      _catalogError = null;
      _isLoadingIslandSituations = true;
    });
    unawaited(_loadIslandSituations(island));
  }

  Future<void> _loadIslandSituations(_IslandCatalogEntry island) async {
    try {
      final situations = await _situationService.getIslandSituations(
        island.islandId,
      );
      if (!mounted || _selectedIslandId != island.islandId) {
        return;
      }

      setState(() {
        _situations = situations;
        _isLoadingIslandSituations = false;
        _catalogError = null;
      });
    } catch (error, stackTrace) {
      debugPrint('SmartSteps island situations failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted || _selectedIslandId != island.islandId) {
        return;
      }

      setState(() {
        _situations = const [];
        _activeLesson = null;
        _isLoadingIslandSituations = false;
        _catalogError = 'Không tải được tình huống của đảo';
      });
    }
  }

  void _showIslands() {
    setState(() {
      _selectedIslandId = null;
      _situations = const [];
      _activeLesson = null;
      _loadingSituationId = null;
      _catalogError = null;
      _isLoadingIslandSituations = false;
    });
  }

  Future<void> _selectSituation(SituationSummary summary) async {
    if (_loadingSituationId == summary.situationId) {
      return;
    }

    if (!_isSituationUnlocked(summary, _profile?.isPremium ?? false)) {
      _showPremiumRequired(summary);
      return;
    }

    setState(() {
      _loadingSituationId = summary.situationId;
      _catalogError = null;
    });

    try {
      final detail = await _situationService.getSituationDetail(
        summary.situationId,
      );
      final lesson = _lessonFromSituation(detail);
      if (!mounted) {
        return;
      }

      setState(() {
        _activeLesson = lesson;
      });
    } catch (error, stackTrace) {
      debugPrint('SmartSteps situation detail failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }

      setState(() {
        _catalogError = 'Không tải được bài học';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingSituationId = null;
        });
      }
    }
  }

  Future<void> _openLesson() async {
    final lesson = _activeLesson;
    if (lesson == null) {
      return;
    }

    final currentIdx = _situations.indexWhere(
      (s) => s.situationId == lesson.situationId,
    );
    final isLastLesson =
        currentIdx != -1 && currentIdx == _situations.length - 1;
    final nextSituation =
        (currentIdx != -1 && currentIdx < _situations.length - 1)
        ? _situations[currentIdx + 1]
        : null;

    final currentIslandIndex = _islands.indexWhere(
      (i) => i.islandId == lesson.islandId,
    );
    final nextIsland =
        (currentIslandIndex != -1 && currentIslandIndex < _islands.length - 1)
        ? _islands[currentIslandIndex + 1]
        : null;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LessonGameScreen(
          lesson: lesson,
          initialStepId: _serverCurrentSteps[lesson.situationId],
          profileStorage: widget.profileStorage,
          isLastLesson: isLastLesson,
          onLessonCompleted: (profile) {
            if (mounted) {
              setState(() {
                _profile = profile;
              });
            }
          },
          onNextLesson: nextSituation != null
              ? () async {
                  Navigator.of(context).pop();
                  final isUnlocked = _isSituationUnlocked(
                    nextSituation,
                    _profile?.isPremium ?? false,
                  );
                  if (isUnlocked) {
                    await _selectSituation(nextSituation);
                    await _openLesson();
                  } else {
                    unawaited(_showPremiumOffer());
                  }
                }
              : null,
          onCompleteIsland: isLastLesson
              ? () async {
                  Navigator.of(context).pop();
                  final currentIsland = _islandById(_islands, lesson.islandId);
                  if (currentIsland != null) {
                    await _showIslandCompletionDialog(
                      currentIsland,
                      nextIsland,
                    );
                  }
                }
              : null,
        ),
      ),
    );

    if (mounted) {
      unawaited(_enterCatalogViewingMode());
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIsland = _selectedIslandId == null
        ? null
        : _islandById(_islands, _selectedIslandId!);
    final selectedSituations = selectedIsland == null
        ? const <SituationSummary>[]
        : _situations;
    final canStartLesson =
        _activeLesson != null &&
        !_isLoadingCatalog &&
        !_isLoadingIslandSituations &&
        _loadingSituationId == null;
    final completedSituationIds = <int>{
      ..._serverCompletedSituationIds,
      ...(_profile?.skillProgress
              .where((p) => p.points > 0)
              .map((p) => p.situationId)
              .toSet() ??
          const <int>{}),
    };

    return Scaffold(
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          selectedIsland == null
              ? _IslandHomeMapTab(
                  profile: _profile,
                  audioController: SmartStepsAudioScope.maybeOf(context),
                  islands: _islands,
                  isLoading: _isLoadingCatalog && _islands.isEmpty,
                  error: _catalogError,
                  onSelected: _selectIsland,
                )
              : _IslandLessonMapTab(
                  island: selectedIsland,
                  situations: selectedSituations,
                  isLoadingSituations: _isLoadingIslandSituations,
                  isPremium: _profile?.isPremium ?? false,
                  activeLessonId: _activeLesson?.id,
                  loadingSituationId: _loadingSituationId,
                  hasActiveLesson: _activeLesson != null,
                  canStartLesson: canStartLesson,
                  completedSituationIds: completedSituationIds,
                  onBack: _showIslands,
                  onLocked: _showPremiumRequired,
                  onSelected: (summary) {
                    unawaited(_selectSituation(summary));
                  },
                  onStartLesson: () {
                    unawaited(_openLesson());
                  },
                ),
          ParentReportPage(
            situationService: _situationService,
            profileStorage: widget.profileStorage,
            isActive: _selectedTabIndex == 1,
            onStartLesson: (situationId, islandId) {
              unawaited(_startSuggestedLesson(situationId, islandId));
            },
            learningGateway: widget.learningGateway,
          ),
          const _PracticeTabPage(),
          ProfileScreen(
            profileStorage: widget.profileStorage,
            onLogout: widget.onLogout,
          ),
        ],
      ),
      bottomNavigationBar: _SmartStepsBottomNavigation(
        currentIndex: _selectedTabIndex,
        onSelected: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
      ),
    );
  }

  Future<void> _startSuggestedLesson(int situationId, int islandId) async {
    final island = _islandById(_islands, islandId);
    if (island != null) {
      _selectIsland(island);
    }

    setState(() {
      _selectedTabIndex = 0;
      _loadingSituationId = situationId;
    });

    try {
      final detail = await _situationService.getSituationDetail(situationId);
      final lesson = _lessonFromSituation(detail);
      if (!mounted) return;

      setState(() {
        _activeLesson = lesson;
      });

      await _openLesson();
    } catch (error) {
      debugPrint('Failed to start suggested lesson: $error');
    } finally {
      if (mounted) {
        setState(() {
          _loadingSituationId = null;
        });
      }
    }
  }

  Future<void> _showIslandCompletionDialog(
    _IslandCatalogEntry completedIsland,
    _IslandCatalogEntry? nextIsland,
  ) async {
    bool allLessonsCompleted = false;
    if (_profile != null) {
      allLessonsCompleted = _profile!.completedLessonCount >= 9;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _IslandCompletionDialog(
          completedIsland: completedIsland,
          nextIsland: nextIsland,
          allLessonsCompleted: allLessonsCompleted,
          onExploreNext: () {
            Navigator.of(context).pop();
            if (nextIsland != null) {
              _selectIsland(nextIsland);
            }
          },
          onBackHome: () {
            Navigator.of(context).pop();
            _showIslands();
          },
        );
      },
    );
  }
}

class _IslandCompletionDialog extends StatefulWidget {
  const _IslandCompletionDialog({
    required this.completedIsland,
    this.nextIsland,
    required this.allLessonsCompleted,
    required this.onExploreNext,
    required this.onBackHome,
  });

  final _IslandCatalogEntry completedIsland;
  final _IslandCatalogEntry? nextIsland;
  final bool allLessonsCompleted;
  final VoidCallback onExploreNext;
  final VoidCallback onBackHome;

  @override
  State<_IslandCompletionDialog> createState() =>
      _IslandCompletionDialogState();
}

class _IslandCompletionDialogState extends State<_IslandCompletionDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final next = widget.nextIsland;
    final hasNext = next != null && !widget.allLessonsCompleted;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = _controller.value;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Rotating celebration rays behind the dialog
              Positioned(
                width: 600,
                height: 600,
                child: CustomPaint(painter: _CelebrationRaysPainter(progress)),
              ),
              // Fireworks overlay
              Positioned(
                width: 500,
                height: 500,
                child: CustomPaint(painter: _SideFireworksPainter(progress)),
              ),
              Positioned(
                width: 400,
                height: 400,
                child: CustomPaint(painter: _CenterBurstPainter(progress)),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: math.min(size.width - 32, 400),
                  maxHeight: size.height - 40,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Material(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF8BC34A), Color(0xFF4CAF50)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x1A000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.emoji_events_rounded,
                                  color: Color(0xFFFFB300),
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                            child: Column(
                              children: [
                                Text(
                                  widget.allLessonsCompleted
                                      ? 'HOÀN THÀNH XUẤT SẮC!'
                                      : 'HOÀN THÀNH rẢO!',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  widget.allLessonsCompleted
                                      ? 'Chúc mừng bé đã hoàn thành xuất sắc tất cả các bài học! Bé thật tuyệt vời!'
                                      : 'Chúc mừng bé đã hoàn thành xuất sắc các bài học tại',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: DuoColors.textSecondary,
                                      ),
                                ),
                                if (!widget.allLessonsCompleted) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.completedIsland.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: DuoColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                Image.asset(
                                  'assets/images/mascot/mascot-cat-happy-wave.webp',
                                  width: 130,
                                  height: 130,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 24),
                                if (hasNext) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F8E9),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFDCEDC8),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Đảo tiếp theo gợi ý cho bé:',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          next.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF33691E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: DuoPrimaryButton(
                                      label: 'Khám phá ngay',
                                      icon: Icons.arrow_forward_rounded,
                                      backgroundColor: DuoColors.success,
                                      onPressed: widget.onExploreNext,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                SizedBox(
                                  width: double.infinity,
                                  child: DuoPrimaryButton(
                                    label: hasNext
                                        ? 'Về trang chủ'
                                        : 'Tuyệt vời, về trang chủ',
                                    icon: Icons.home_rounded,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    onPressed: widget.onBackHome,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PracticeTabPage extends StatelessWidget {
  const _PracticeTabPage();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: DuoColors.background),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            DuoCard(
              color: DuoColors.primaryYellow,
              borderColor: DuoColors.darkYellow,
              child: Row(
                children: [
                  Image.asset(LessonAssets.mascotSinging, width: 82),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Luyện tập',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ôn lại các kỹ năng an toàn đã học.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DuoAchievementCard(
              icon: Icons.replay_rounded,
              title: 'Ôn bài nhanh',
              subtitle: '5 câu hỏi ngắn để ghi nhớ lâu hơn',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const QuickReviewScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            const DuoAchievementCard(
              icon: Icons.shield_rounded,
              title: 'Tình huống an toàn',
              subtitle: 'Chọn cách xử lý đúng trong đời sống',
            ),
            const SizedBox(height: 12),
            const DuoAchievementCard(
              icon: Icons.lock_rounded,
              title: 'Thử thách nâng cao',
              subtitle: 'Mở khóa khi hoàn thành thêm bài học',
              isUnlocked: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumOfferDialog extends StatefulWidget {
  const _PremiumOfferDialog({
    required this.profileStorage,
    required this.onPremiumActivated,
  });

  final LocalProfileStorage profileStorage;
  final ValueChanged<ChildProfile> onPremiumActivated;

  @override
  State<_PremiumOfferDialog> createState() => _PremiumOfferDialogState();
}

class _PremiumOfferDialogState extends State<_PremiumOfferDialog> {
  bool _canDismiss = false;
  bool _isSubmitting = false;
  bool _showSuccess = false;
  String? _errorText;
  int? _pendingOrderCode;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _canDismiss = true;
      });
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  Future<void> _activatePremium() async {
    if (_isSubmitting || _showSuccess) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    // 1. Loading effect for 1 second
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) {
      return;
    }

    try {
      // Redeem on the authenticated account first, then refresh local UI state.
      final status = await PremiumService().redeemCode('PREMIUM');
      if (!status.hasPremium) {
        throw const PremiumServiceException('Máy chủ chưa kích hoạt Premium.');
      }
      final current = await widget.profileStorage.readProfile();
      if (current == null) {
        throw const PremiumServiceException('Bạn cần hoàn tất hồ sơ trước.');
      }
      final profile = current.copyWith(
        isPremium: true,
        premiumCode: status.planCode ?? 'PREMIUM',
        premiumActivatedAt: DateTime.now(),
      );
      await widget.profileStorage.saveProfile(profile);
      if (!mounted) {
        return;
      }

      // Notify parent to rebuild workspace and unlock premium features
      widget.onPremiumActivated(profile);

      // 3. Show success pop-up
      setState(() {
        _isSubmitting = false;
        _showSuccess = true;
      });
    } on PremiumServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = error.message;
        _isSubmitting = false;
      });
    } catch (error, stackTrace) {
      debugPrint('SmartSteps premium activation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = 'Chưa nâng cấp được Premium. Vui lòng thử lại.';
        _isSubmitting = false;
      });
    }
  }

  Future<void> _purchasePremium() async {
    if (_isSubmitting || _showSuccess) return;
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      final service = PremiumService();
      final payment = await service.createPayment('PRO_MONTHLY');
      if (payment.checkoutUrl.isEmpty) {
        throw const PremiumServiceException(
          'Máy chủ không trả về trang thanh toán.',
        );
      }
      final launched = await launchUrl(
        Uri.parse(payment.checkoutUrl),
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
      if (!launched) {
        throw const PremiumServiceException(
          'Không thể mở trang thanh toán PayOS.',
        );
      }
      if (!mounted) return;
      setState(() {
        _pendingOrderCode = payment.orderCode;
        _isSubmitting = false;
        _errorText =
            'Sau khi thanh toán, hãy quay lại và bấm “Kiểm tra thanh toán”.';
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorText = 'Không tạo được thanh toán: $error';
        });
      }
    }
  }

  Future<void> _checkPayment() async {
    final orderCode = _pendingOrderCode;
    if (_isSubmitting || orderCode == null) return;
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      final status = await PremiumService().confirmPayment(orderCode);
      if (status.hasPremium) {
        final current = await widget.profileStorage.readProfile();
        if (current != null) {
          final profile = current.copyWith(
            isPremium: true,
            premiumCode: status.planCode,
            premiumActivatedAt: DateTime.now(),
          );
          await widget.profileStorage.saveProfile(profile);
          widget.onPremiumActivated(profile);
        }
        if (mounted) {
          setState(() {
            _showSuccess = true;
            _isSubmitting = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorText =
              'PayOS chưa xác nhận giao dịch. Hãy hoàn tất thanh toán rồi thử lại.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorText = 'Không kiểm tra được thanh toán: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: math.min(size.width - 32, 436),
          maxHeight: size.height - 44,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Material(
            color: Colors.white,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    height: 14,
                    color: _showSuccess
                        ? const Color(0xFF8BC34A)
                        : DuoColors.primaryYellow,
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 34, 24, 26),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showSuccess
                        ? _buildSuccessContent(context)
                        : _buildOfferContent(context),
                  ),
                ),
                Positioned(
                  top: 18,
                  right: 14,
                  child: (_canDismiss && !_showSuccess)
                      ? Tooltip(
                          message: 'Đóng',
                          child: IconButton.filled(
                            key: const ValueKey('premium-offer-close-button'),
                            onPressed: () => Navigator.of(context).pop(),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFF5F5F5),
                              foregroundColor: DuoColors.textPrimary,
                            ),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfferContent(BuildContext context) {
    return Column(
      key: const ValueKey('offer-content'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'SMARTSTEPS\nPREMIUM',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF8BC34A),
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1.18,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF1B8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: Color(0xFFFF8F00),
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Mở khóa toàn bộ hành trình học tập',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _PremiumBenefitRow('AI gợi ý bài học mỗi ngày'),
        const _PremiumBenefitRow('Không giới hạn màn chơi'),
        const _PremiumBenefitRow('Huy hiệu và phần thưởng đặc biệt'),
        const _PremiumBenefitRow('Theo dõi tiến bộ của bé'),
        const _PremiumBenefitRow('Chế độ luyện tập nâng cao'),
        if (_errorText != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorText!,
            style: const TextStyle(color: Color(0xFFBA1A1A), fontSize: 14),
          ),
        ],
        const SizedBox(height: 24),
        SmartStepsPressEffect(
          enabled: !_isSubmitting,
          child: FilledButton.icon(
            key: const ValueKey('premium-code-submit-button'),
            onPressed: _isSubmitting ? null : _activatePremium,
            icon: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFF7A1A),
              size: 24,
            ),
            label: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: Colors.black,
                    ),
                  )
                : const Text('Kích hoạt Premium'),
            style: FilledButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFFFFE99C),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 56),
              textStyle: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _isSubmitting
              ? null
              : (_pendingOrderCode == null ? _purchasePremium : _checkPayment),
          icon: Icon(
            _pendingOrderCode == null
                ? Icons.qr_code_rounded
                : Icons.refresh_rounded,
          ),
          label: Text(
            _pendingOrderCode == null
                ? 'Thanh toán gói 1 tháng'
                : 'Kiểm tra thanh toán',
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent(BuildContext context) {
    return Column(
      key: const ValueKey('success-content'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF9C4),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: Color(0xFFFFB300),
            size: 52,
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'SMARTSTEPS PREMIUM',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFFF9100),
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'NÂNG CẤP THÀNH CÔNG!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Chúc mừng bé đã mở khóa toàn bộ hành trình và các tính năng đặc quyền!',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: DuoColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Image.asset(
          'assets/images/mascot/mascot-cat-happy-wave.webp',
          width: 140,
          height: 140,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: DuoPrimaryButton(
            label: 'Bắt đầu trải nghiệm!',
            icon: Icons.rocket_launch_rounded,
            backgroundColor: DuoColors.primaryYellow,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }
}

class _PremiumBenefitRow extends StatelessWidget {
  const _PremiumBenefitRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_rounded, color: Color(0xFF2CB34A), size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: DuoColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartStepsBottomNavigation extends StatelessWidget {
  const _SmartStepsBottomNavigation({
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFEF8),
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Container(
          height: 72,
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFEF8),
            border: const Border(
              top: BorderSide(color: Color(0xFFEEE4C7), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF25324B).withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Row(
            children: [
              _SmartStepsBottomNavigationItem(
                key: const ValueKey('home-tab-button'),
                icon: Icons.home_rounded,
                label: 'Trang chủ',
                isSelected: currentIndex == 0,
                onTap: () => onSelected(0),
              ),
              _SmartStepsBottomNavigationItem(
                key: const ValueKey('learn-tab-button'),
                icon: Icons.map_rounded,
                label: 'Tiến bộ',
                isSelected: currentIndex == 1,
                onTap: () {
                  onSelected(1);
                  AnalyticsService.trackEvent('view_progress_tab');
                },
              ),
              _SmartStepsBottomNavigationItem(
                key: const ValueKey('practice-tab-button'),
                icon: Icons.bolt_rounded,
                label: 'Luyện tập',
                isSelected: currentIndex == 2,
                onTap: () => onSelected(2),
              ),
              _SmartStepsBottomNavigationItem(
                key: const ValueKey('profile-tab-button'),
                icon: Icons.face_rounded,
                label: 'Bé',
                isSelected: currentIndex == 3,
                onTap: () => onSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmartStepsBottomNavigationItem extends StatelessWidget {
  const _SmartStepsBottomNavigationItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: isSelected,
        button: true,
        label: label,
        child: SmartStepsPressEffect(
          child: InkResponse(
            onTap: onTap,
            containedInkWell: true,
            highlightShape: BoxShape.rectangle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFF0B8)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFECC55A)
                      : Colors.transparent,
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? const Color(0xFFC88A00)
                        : DuoColors.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? DuoColors.textPrimary
                          : DuoColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
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

class _IslandHomeMapTab extends StatelessWidget {
  const _IslandHomeMapTab({
    required this.profile,
    required this.audioController,
    required this.islands,
    required this.isLoading,
    required this.error,
    required this.onSelected,
  });

  final ChildProfile? profile;
  final SmartStepsAudioController? audioController;
  final List<_IslandCatalogEntry> islands;
  final bool isLoading;
  final String? error;
  final ValueChanged<_IslandCatalogEntry> onSelected;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DuoColors.primaryYellow,
      child: Stack(
        children: [
          Positioned.fill(
            child: _IslandMapStage(
              profile: profile,
              islands: islands,
              isLoading: isLoading,
              error: error,
              onSelected: onSelected,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _IslandHomeHeader(
              profile: profile,
              audioController: audioController,
            ),
          ),
        ],
      ),
    );
  }
}

class _IslandHomeHeader extends StatelessWidget {
  const _IslandHomeHeader({
    required this.profile,
    required this.audioController,
  });

  final ChildProfile? profile;
  final SmartStepsAudioController? audioController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showAudioControls =
            audioController != null && constraints.maxWidth >= 430;

        return SafeArea(
          bottom: false,
          child: Container(
            height: 72,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E6).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.70),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B5C18).withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1B8),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFF3D46A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: Color(0xFF8A5A00),
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '0 ngày',
                          style: TextStyle(
                            color: Color(0xFF8A5A00),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showAudioControls) ...[
                          _AudioToggleCluster(controller: audioController!),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            'Chào ${_catalogChildName(profile)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: GameColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: _catalogChildName(profile),
                          child: _KidProfileAvatar(size: 40, profile: profile),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IslandMapStage extends StatefulWidget {
  const _IslandMapStage({
    required this.profile,
    required this.islands,
    required this.isLoading,
    required this.error,
    required this.onSelected,
  });

  final ChildProfile? profile;
  final List<_IslandCatalogEntry> islands;
  final bool isLoading;
  final String? error;
  final ValueChanged<_IslandCatalogEntry> onSelected;

  @override
  State<_IslandMapStage> createState() => _IslandMapStageState();
}

class _IslandMapStageState extends State<_IslandMapStage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        final mapHeight = math.max(
          viewport.height + 560,
          viewport.width * 2.75,
        );
        final orderedIslands = [...widget.islands]
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        final visibleIslandCount = math.min(orderedIslands.length, 3);
        final showActionPanel =
            !widget.isLoading && widget.error == null && visibleIslandCount > 0;

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _IslandMapParallaxBackground(
                controller: _scrollController,
                viewportWidth: viewport.width,
                viewportHeight: viewport.height,
                mapHeight: mapHeight,
                bottomPadding: showActionPanel ? 96 : 0,
              ),
              SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.only(bottom: showActionPanel ? 96 : 0),
                child: SizedBox(
                  height: mapHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.05),
                              Colors.white.withValues(alpha: 0.0),
                              const Color(0xFF5D8F5A).withValues(alpha: 0.20),
                            ],
                          ),
                        ),
                      ),
                      for (
                        var index = 0;
                        index < _islandMapSlots.length;
                        index++
                      )
                        if (index < visibleIslandCount)
                          _IslandMapNodePositioner(
                            viewport: viewport,
                            mapHeight: mapHeight,
                            slot: _islandMapSlots[index],
                            child: _IslandMapNode(
                              key: ValueKey(
                                'island-${orderedIslands[index].islandId}',
                              ),
                              title: _islandMapTitle(
                                orderedIslands[index],
                                index,
                              ),
                              lessonCount: orderedIslands[index].lessonCount,
                              slot: _islandMapSlots[index],
                              onTap: () =>
                                  widget.onSelected(orderedIslands[index]),
                            ),
                          )
                        else
                          _IslandMapNodePositioner(
                            viewport: viewport,
                            mapHeight: mapHeight,
                            slot: _islandMapSlots[index],
                            child: _HiddenIslandMapNode(
                              title: _hiddenIslandMapTitle(index),
                              slot: _islandMapSlots[index],
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              if (showActionPanel)
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 10,
                  child: _IslandHomeActionPanel(
                    profile: widget.profile,
                    island: orderedIslands.first,
                    islandTitle: _islandMapTitle(orderedIslands.first, 0),
                    onPressed: () => widget.onSelected(orderedIslands.first),
                  ),
                ),
              if (widget.isLoading)
                const _IslandMapStatusOverlay(
                  icon: Icons.sync_rounded,
                  title: 'Đang tải dữ liệu',
                  body: 'SmartSteps đang mở bản đồ đảo.',
                )
              else if (widget.error != null)
                _IslandMapStatusOverlay(
                  icon: Icons.cloud_off_rounded,
                  title: 'Không tải được dữ liệu',
                  body: widget.error!,
                )
              else if (orderedIslands.isEmpty)
                const _IslandMapStatusOverlay(
                  icon: Icons.map_outlined,
                  title: 'Chưa có đảo',
                  body: 'Chưa có bài học đã xuất bản.',
                ),
            ],
          ),
        );
      },
    );
  }
}

class _IslandMapParallaxBackground extends StatelessWidget {
  const _IslandMapParallaxBackground({
    required this.controller,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.mapHeight,
    required this.bottomPadding,
  });

  final ScrollController controller;
  final double viewportWidth;
  final double viewportHeight;
  final double mapHeight;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final scrollRange = math.max(
      0.0,
      mapHeight + bottomPadding - viewportHeight,
    );
    final parallaxExtent = math.min(260.0, math.max(80.0, scrollRange * 0.22));

    return Positioned.fill(
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: viewportHeight + parallaxExtent,
          maxHeight: viewportHeight + parallaxExtent,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final offset = controller.hasClients ? controller.offset : 0.0;
              final dy = -math.min(parallaxExtent, offset * 0.28);

              return Transform.translate(offset: Offset(0, dy), child: child);
            },
            child: SizedBox(
              height: viewportHeight + parallaxExtent,
              width: viewportWidth,
              child: Image.asset(
                LessonAssets.rootMapBackground,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IslandMapNodePositioner extends StatelessWidget {
  const _IslandMapNodePositioner({
    required this.viewport,
    required this.mapHeight,
    required this.slot,
    required this.child,
  });

  final Size viewport;
  final double mapHeight;
  final _IslandMapSlot slot;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final nodeWidth = (viewport.width * slot.widthFactor)
        .clamp(slot.minWidth, slot.maxWidth)
        .toDouble();
    final nodeHeight = nodeWidth * 0.74 + 44;
    final left = (viewport.width * slot.anchor.dx - nodeWidth / 2)
        .clamp(10.0, math.max(10.0, viewport.width - nodeWidth - 10))
        .toDouble();
    final top = (mapHeight * slot.anchor.dy - nodeHeight / 2)
        .clamp(12.0, math.max(12.0, mapHeight - nodeHeight - 12))
        .toDouble();

    return Positioned(left: left, top: top, width: nodeWidth, child: child);
  }
}

class _IslandMapNode extends StatelessWidget {
  const _IslandMapNode({
    super.key,
    required this.title,
    required this.lessonCount,
    required this.slot,
    required this.onTap,
  });

  final String title;
  final int lessonCount;
  final _IslandMapSlot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: SmartStepsPressEffect(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            splashColor: DuoColors.primaryYellow.withValues(alpha: 0.18),
            highlightColor: DuoColors.primaryYellow.withValues(alpha: 0.10),
            onTap: onTap,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: _IslandMapArt(asset: slot.asset, isLocked: false),
                ),
                Positioned(
                  left: 18,
                  bottom: 34,
                  child: _IslandMapLabel(
                    title: title,
                    lessonCount: lessonCount,
                    onTap: onTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HiddenIslandMapNode extends StatelessWidget {
  const _HiddenIslandMapNode({required this.title, required this.slot});

  final String title;
  final _IslandMapSlot slot;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.58,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: _IslandMapArt(asset: slot.asset, isLocked: true),
            ),
            Positioned(
              left: 18,
              bottom: 34,
              child: _IslandMapLockedLabel(title: title),
            ),
          ],
        ),
      ),
    );
  }
}

class _IslandMapArt extends StatelessWidget {
  const _IslandMapArt({required this.asset, required this.isLocked});

  final String asset;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(asset, fit: BoxFit.cover);

    return AspectRatio(
      aspectRatio: 1.36,
      child: CustomPaint(
        painter: const _IslandMapBlobShadowPainter(),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: ClipPath(
            clipper: const _IslandMapBlobClipper(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                isLocked
                    ? ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.white.withValues(alpha: 0.48),
                          BlendMode.srcATop,
                        ),
                        child: image,
                      )
                    : image,
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.25, -0.28),
                      radius: 0.95,
                      colors: [
                        Colors.white.withValues(alpha: isLocked ? 0.24 : 0.14),
                        Colors.transparent,
                        const Color(
                          0xFF58CC02,
                        ).withValues(alpha: isLocked ? 0.10 : 0.18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IslandMapBlobClipper extends CustomClipper<Path> {
  const _IslandMapBlobClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.13, h * 0.58)
      ..cubicTo(w * 0.02, h * 0.37, w * 0.12, h * 0.14, w * 0.34, h * 0.10)
      ..cubicTo(w * 0.48, h * 0.00, w * 0.72, h * 0.07, w * 0.86, h * 0.24)
      ..cubicTo(w * 1.02, h * 0.42, w * 0.91, h * 0.73, w * 0.70, h * 0.83)
      ..cubicTo(w * 0.49, h * 0.99, w * 0.24, h * 0.86, w * 0.13, h * 0.58)
      ..close();
  }

  @override
  bool shouldReclip(covariant _IslandMapBlobClipper oldClipper) => false;
}

class _IslandMapBlobShadowPainter extends CustomPainter {
  const _IslandMapBlobShadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final clipper = const _IslandMapBlobClipper();
    final inset = 7.0;
    final innerSize = Size(size.width - inset * 2, size.height - inset * 2);
    final path = clipper.getClip(innerSize).shift(Offset(inset, inset));
    canvas.drawShadow(path, const Color(0x6625324B), 14, true);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.white.withValues(alpha: 0.82);
    canvas.drawPath(path, borderPaint);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..color = const Color(0x6658CC02);
    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _IslandMapBlobShadowPainter oldDelegate) {
    return false;
  }
}

class _IslandHomeActionPanel extends StatelessWidget {
  const _IslandHomeActionPanel({
    required this.profile,
    required this.island,
    required this.islandTitle,
    required this.onPressed,
  });

  final ChildProfile? profile;
  final _IslandCatalogEntry island;
  final String islandTitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final completedLessons = profile?.completedLessonCount ?? 0;
    final totalPoints = profile?.totalSkillPoints ?? 0;
    final progress = (completedLessons / 9).clamp(0, 1).toDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.88),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF25324B).withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 370;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!isCompact) ...[
                    _KidProfileAvatar(size: 44, profile: profile),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Học tiếp · $islandTitle',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: GameColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completedLessons/9 bài · $totalPoints điểm · ${island.lessonCount} bài trên đảo',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DuoColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 7),
                        DuoProgressBar(value: progress, height: 7),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _CompactMapButton(onPressed: onPressed, compact: isCompact),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CompactMapButton extends StatelessWidget {
  const _CompactMapButton({required this.onPressed, this.compact = false});

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = compact ? 'Học' : 'Học tiếp';

    return SmartStepsPressEffect(
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          fixedSize: Size(compact ? 76 : 112, compact ? 40 : 42),
          padding: EdgeInsets.zero,
          backgroundColor: GameColors.banana,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, size: 20),
            const SizedBox(width: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _IslandMapLabel extends StatelessWidget {
  const _IslandMapLabel({
    required this.title,
    required this.lessonCount,
    required this.onTap,
  });

  final String title;
  final int lessonCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: SmartStepsPressEffect(
        child: _IslandMapGlassPill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              splashColor: DuoColors.primaryYellow.withValues(alpha: 0.14),
              highlightColor: DuoColors.primaryYellow.withValues(alpha: 0.08),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF2F6818),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$lessonCount bài học',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF5D7568),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
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

class _IslandMapLockedLabel extends StatelessWidget {
  const _IslandMapLockedLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return _IslandMapGlassPill(
      opacity: 0.74,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF466055),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Sắp mở khóa',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF7D8D84),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IslandMapGlassPill extends StatelessWidget {
  const _IslandMapGlassPill({required this.child, this.opacity = 0.84});

  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 214),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.82),
                width: 1.4,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2425324B),
                  blurRadius: 16,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _IslandMapStatusOverlay extends StatelessWidget {
  const _IslandMapStatusOverlay({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: _GlassPanel(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: GameColors.ink, size: 40),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IslandMapSlot {
  const _IslandMapSlot({
    required this.anchor,
    required this.widthFactor,
    required this.minWidth,
    required this.maxWidth,
    required this.asset,
    required this.icon,
  });

  final Offset anchor;
  final double widthFactor;
  final double minWidth;
  final double maxWidth;
  final String asset;
  final IconData icon;
}

const _islandMapSlots = [
  _IslandMapSlot(
    anchor: Offset(0.62, 0.21),
    widthFactor: 0.62,
    minWidth: 205,
    maxWidth: 275,
    asset: LessonAssets.landIsland1,
    icon: Icons.card_giftcard_rounded,
  ),
  _IslandMapSlot(
    anchor: Offset(0.32, 0.39),
    widthFactor: 0.66,
    minWidth: 215,
    maxWidth: 290,
    asset: LessonAssets.landIsland2,
    icon: Icons.star_rounded,
  ),
  _IslandMapSlot(
    anchor: Offset(0.66, 0.57),
    widthFactor: 0.66,
    minWidth: 215,
    maxWidth: 290,
    asset: LessonAssets.landIsland3,
    icon: Icons.beach_access_rounded,
  ),
  _IslandMapSlot(
    anchor: Offset(0.24, 0.74),
    widthFactor: 0.58,
    minWidth: 190,
    maxWidth: 252,
    asset: LessonAssets.landIsland1,
    icon: Icons.explore_rounded,
  ),
  _IslandMapSlot(
    anchor: Offset(0.72, 0.90),
    widthFactor: 0.58,
    minWidth: 190,
    maxWidth: 252,
    asset: LessonAssets.landIsland2,
    icon: Icons.flag_rounded,
  ),
];

String _islandMapTitle(_IslandCatalogEntry island, int slotIndex) {
  return switch (slotIndex) {
    0 => 'Đảo An Toàn',
    1 => 'Đảo Tình Bạn',
    2 => 'Đảo Trường Học',
    _ => island.name,
  };
}

String _hiddenIslandMapTitle(int slotIndex) {
  return switch (slotIndex) {
    3 => 'Đảo Khám Phá',
    4 => 'Đảo Sáng Tạo',
    _ => 'Đảo sắp mở',
  };
}

class _IslandLessonMapTab extends StatelessWidget {
  const _IslandLessonMapTab({
    required this.island,
    required this.situations,
    required this.isLoadingSituations,
    required this.isPremium,
    required this.activeLessonId,
    required this.loadingSituationId,
    required this.hasActiveLesson,
    required this.canStartLesson,
    required this.completedSituationIds,
    required this.onBack,
    required this.onLocked,
    required this.onSelected,
    required this.onStartLesson,
  });

  final _IslandCatalogEntry island;
  final List<SituationSummary> situations;
  final bool isLoadingSituations;
  final bool isPremium;
  final String? activeLessonId;
  final int? loadingSituationId;
  final bool hasActiveLesson;
  final bool canStartLesson;
  final Set<int> completedSituationIds;
  final VoidCallback onBack;
  final ValueChanged<SituationSummary> onLocked;
  final ValueChanged<SituationSummary> onSelected;
  final VoidCallback onStartLesson;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DuoColors.primaryYellow,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _IslandLessonHeader(island: island, onBack: onBack),
          ),
          Expanded(
            child: _IslandLessonMapStage(
              island: island,
              situations: situations,
              isLoadingSituations: isLoadingSituations,
              isPremium: isPremium,
              activeLessonId: activeLessonId,
              loadingSituationId: loadingSituationId,
              hasActiveLesson: hasActiveLesson,
              canStartLesson: canStartLesson,
              completedSituationIds: completedSituationIds,
              onLocked: onLocked,
              onSelected: onSelected,
              onStartLesson: onStartLesson,
            ),
          ),
        ],
      ),
    );
  }
}

class _IslandLessonHeader extends StatelessWidget {
  const _IslandLessonHeader({required this.island, required this.onBack});

  final _IslandCatalogEntry island;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 14 : 20,
            isCompact ? 8 : 12,
            isCompact ? 14 : 20,
            isCompact ? 10 : 14,
          ),
          child: SizedBox(
            height: isCompact ? 56 : 64,
            child: Row(
              children: [
                _CircleIconButton(
                  label: 'Quay lại bản đồ đảo',
                  icon: Icons.arrow_back_rounded,
                  onPressed: onBack,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _islandLessonTitle(island),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isCompact ? 24 : 30,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.route_rounded,
                        color: DuoColors.darkYellow,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${island.lessonCount} bài',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: GameColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IslandLessonMapStage extends StatelessWidget {
  const _IslandLessonMapStage({
    required this.island,
    required this.situations,
    required this.isLoadingSituations,
    required this.isPremium,
    required this.activeLessonId,
    required this.loadingSituationId,
    required this.hasActiveLesson,
    required this.canStartLesson,
    required this.completedSituationIds,
    required this.onLocked,
    required this.onSelected,
    required this.onStartLesson,
  });

  final _IslandCatalogEntry island;
  final List<SituationSummary> situations;
  final bool isLoadingSituations;
  final bool isPremium;
  final String? activeLessonId;
  final int? loadingSituationId;
  final bool hasActiveLesson;
  final bool canStartLesson;
  final Set<int> completedSituationIds;
  final ValueChanged<SituationSummary> onLocked;
  final ValueChanged<SituationSummary> onSelected;
  final VoidCallback onStartLesson;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _islandLessonBackgroundAsset(island.islandId),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF003848).withValues(alpha: 0.12),
                  Colors.transparent,
                  const Color(0xFF003848).withValues(alpha: 0.18),
                ],
              ),
            ),
          ),
          if (isLoadingSituations && situations.isEmpty)
            const _IslandMapStatusOverlay(
              icon: Icons.sync_rounded,
              title: 'Đang tải',
              body: 'Đang mở bản đồ bài học.',
            )
          else if (situations.isEmpty)
            const _IslandMapStatusOverlay(
              icon: Icons.auto_stories_outlined,
              title: 'Chưa có bài học',
              body: 'Đảo này chưa có bài học đã xuất bản.',
            )
          else
            _IslandLessonPathOverlay(
              islandId: island.islandId,
              situations: situations,
              isPremium: isPremium,
              activeLessonId: activeLessonId,
              loadingSituationId: loadingSituationId,
              completedSituationIds: completedSituationIds,
              onLocked: onLocked,
              onSelected: onSelected,
              onStartLesson: onStartLesson,
            ),
        ],
      ),
    );
  }
}

class _IslandLessonPathOverlay extends StatelessWidget {
  const _IslandLessonPathOverlay({
    required this.islandId,
    required this.situations,
    required this.isPremium,
    required this.activeLessonId,
    required this.loadingSituationId,
    required this.completedSituationIds,
    required this.onLocked,
    required this.onSelected,
    required this.onStartLesson,
  });

  final int islandId;
  final List<SituationSummary> situations;
  final bool isPremium;
  final String? activeLessonId;
  final int? loadingSituationId;
  final Set<int> completedSituationIds;
  final ValueChanged<SituationSummary> onLocked;
  final ValueChanged<SituationSummary> onSelected;
  final VoidCallback onStartLesson;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pathPoints = _lessonPathPoints(
          islandId: islandId,
          count: situations.length,
        );
        final stageSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _IslandLessonPathPainter(points: pathPoints),
              ),
            ),
            for (var index = 0; index < situations.length; index++)
              _IslandLessonPathNodePositioner(
                stageSize: stageSize,
                point: pathPoints[index],
                child: _IslandLessonPathNode(
                  situation: situations[index],
                  isSelected:
                      activeLessonId ==
                      'situation-${situations[index].situationId}',
                  isCompleted: completedSituationIds.contains(
                    situations[index].situationId,
                  ),
                  isLoading:
                      loadingSituationId == situations[index].situationId,
                  isUnlocked: _isSituationUnlocked(
                    situations[index],
                    isPremium,
                  ),
                  onTap: () {
                    if (_isSituationUnlocked(situations[index], isPremium)) {
                      final isCurrentSelected =
                          activeLessonId ==
                          'situation-${situations[index].situationId}';
                      if (isCurrentSelected) {
                        onStartLesson();
                      } else {
                        onSelected(situations[index]);
                      }
                    } else {
                      onLocked(situations[index]);
                    }
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _IslandLessonPathNodePositioner extends StatelessWidget {
  const _IslandLessonPathNodePositioner({
    required this.stageSize,
    required this.point,
    required this.child,
  });

  final Size stageSize;
  final Offset point;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const nodeWidth = 176.0;
    const nodeHeight = 150.0;
    final left = (stageSize.width * point.dx - nodeWidth / 2)
        .clamp(8.0, math.max(8.0, stageSize.width - nodeWidth - 8))
        .toDouble();
    final top = (stageSize.height * point.dy - 48)
        .clamp(8.0, math.max(8.0, stageSize.height - nodeHeight - 8))
        .toDouble();

    return Positioned(left: left, top: top, width: nodeWidth, child: child);
  }
}

class _IslandLessonPathNode extends StatelessWidget {
  const _IslandLessonPathNode({
    required this.situation,
    required this.isSelected,
    required this.isCompleted,
    required this.isLoading,
    required this.isUnlocked,
    required this.onTap,
  });

  final SituationSummary situation;
  final bool isSelected;
  final bool isCompleted;
  final bool isLoading;
  final bool isUnlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? GameColors.safe
        : isUnlocked
        ? DuoColors.primaryYellow
        : const Color(0xFFD7DCE2);
    final foreground = isUnlocked ? GameColors.ink : const Color(0xFF87909D);
    final lessonIcon = _situationIcon(situation);
    final nodeSize = isSelected ? 84.0 : 74.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('situation-${situation.situationId}'),
                onTap: isLoading ? null : onTap,
                customBorder: const CircleBorder(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: nodeSize,
                  height: nodeSize,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.96),
                      width: 7,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(
                          alpha: isSelected ? 0.55 : 0.34,
                        ),
                        blurRadius: isSelected ? 26 : 16,
                        offset: const Offset(0, 8),
                      ),
                      const BoxShadow(
                        color: Color(0x3825324B),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(23),
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : Icon(
                          isSelected
                              ? Icons.play_arrow_rounded
                              : isUnlocked
                              ? lessonIcon
                              : Icons.lock_rounded,
                          color: foreground,
                          size: isSelected ? 40 : 33,
                        ),
                ),
              ),
            ),
            if (isCompleted && !isLoading)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 7),
        Container(
          constraints: const BoxConstraints(maxWidth: 144),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? GameColors.safe
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2625324B),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            isSelected
                ? 'ĐÃ CHỌN'
                : isUnlocked
                ? 'Bài ${situation.orderIndex}'
                : 'CẦN NÂNG CẤP',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : GameColors.ink,
              fontSize: isUnlocked ? 12 : 10,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          situation.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            height: 1.12,
            shadows: [
              Shadow(
                color: Color(0xB325324B),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IslandLessonPathPainter extends CustomPainter {
  const _IslandLessonPathPainter({required this.points});

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    final path = Path()
      ..moveTo(points.first.dx * size.width, points.first.dy * size.height);
    for (var index = 1; index < points.length; index++) {
      path.lineTo(
        points[index].dx * size.width,
        points[index].dy * size.height,
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF0A6B74).withValues(alpha: 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = DuoColors.primaryYellow.withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _IslandLessonPathPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

String _islandLessonTitle(_IslandCatalogEntry island) {
  return switch (island.islandId) {
    1 => 'Đảo An Toàn',
    2 => 'Đảo Tình Bạn',
    3 => 'Đảo Trường Học',
    _ => island.name,
  };
}

String _islandLessonBackgroundAsset(int islandId) {
  return switch (islandId) {
    1 => LessonAssets.island1Background,
    2 => LessonAssets.island2Background,
    3 => LessonAssets.island3Background,
    _ => LessonAssets.island1Background,
  };
}

List<Offset> _lessonPathPoints({required int islandId, required int count}) {
  final anchors = switch (islandId) {
    1 => const [Offset(0.50, 0.82), Offset(0.27, 0.58), Offset(0.70, 0.34)],
    2 => const [Offset(0.47, 0.82), Offset(0.35, 0.57), Offset(0.58, 0.32)],
    3 => const [Offset(0.58, 0.82), Offset(0.48, 0.58), Offset(0.33, 0.33)],
    _ => const [Offset(0.50, 0.82), Offset(0.34, 0.58), Offset(0.66, 0.34)],
  };

  if (count <= anchors.length) {
    return anchors.take(count).toList(growable: false);
  }

  return List<Offset>.generate(count, (index) {
    final t = count == 1 ? 0.0 : index / (count - 1);
    final y = 0.82 - t * 0.52;
    final x = 0.5 + math.sin(t * math.pi * 2.2) * 0.24;
    return Offset(x.clamp(0.18, 0.82).toDouble(), y);
  }, growable: false);
}

// ignore: unused_element
class _CatalogTopBar extends StatelessWidget {
  const _CatalogTopBar({
    required this.profile,
    required this.plan,
    required this.onUpgradePressed,
    // ignore: unused_element_parameter
    this.audioController,
  });

  final ChildProfile? profile;
  final String plan;
  final VoidCallback? onUpgradePressed;
  final SmartStepsAudioController? audioController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;
        final childName = _catalogChildName(profile);
        final completedLessons = profile?.completedLessonCount ?? 0;
        final totalPoints = profile?.totalSkillPoints ?? 0;
        final level = (totalPoints ~/ 3) + 1;
        final profileLine = profile == null
            ? 'Chưa có hồ sơ bé'
            : '${profile!.displayAge} - ${profile!.primaryGoal}';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _HeaderMetricChip(
                    icon: Icons.check_circle_rounded,
                    label: '$completedLessons/9 bài',
                    color: DuoColors.softYellow,
                    iconColor: const Color(0xFFE86D1F),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HeaderMetricChip(
                    icon: Icons.star_rounded,
                    label: '$totalPoints điểm',
                    color: const Color(0xFFE9F8D5),
                    iconColor: DuoColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HeaderPlanChip(
                    plan: plan,
                    onPressed: onUpgradePressed,
                  ),
                ),
              ],
            ),
            if (audioController != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _AudioToggleCluster(controller: audioController!),
              ),
            ],
            const SizedBox(height: 12),
            DuoCard(
              color: DuoColors.primaryYellow,
              borderColor: DuoColors.darkYellow.withValues(alpha: 0.24),
              padding: EdgeInsets.fromLTRB(
                isCompact ? 14 : 18,
                isCompact ? 14 : 16,
                isCompact ? 12 : 16,
                isCompact ? 14 : 16,
              ),
              child: Row(
                children: [
                  _KidProfileAvatar(size: isCompact ? 58 : 68),
                  SizedBox(width: isCompact ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          childName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DuoColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$profileLine\nCấp $level - Học an toàn mỗi ngày',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: DuoColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        DuoProgressBar(
                          value: (completedLessons / 9).clamp(0, 1).toDouble(),
                        ),
                      ],
                    ),
                  ),
                  if (!isCompact) ...[
                    const SizedBox(width: 12),
                    Image.asset(LessonAssets.mascotHappyWave, width: 74),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AudioToggleCluster extends StatelessWidget {
  const _AudioToggleCluster({required this.controller});

  final SmartStepsAudioController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AudioToggleButton(
              tooltip: controller.isMusicEnabled
                  ? 'Tắt nhạc nền'
                  : 'Bật nhạc nền',
              icon: controller.isMusicEnabled
                  ? Icons.music_note_rounded
                  : Icons.music_off_rounded,
              isEnabled: controller.isMusicEnabled,
              playPressSound: controller.isSfxEnabled,
              onPressed: controller.toggleMusic,
            ),
            const SizedBox(width: 8),
            _AudioToggleButton(
              tooltip: controller.isSfxEnabled
                  ? 'Tắt âm thanh nút'
                  : 'B?t ?m thanh n?t',
              icon: controller.isSfxEnabled
                  ? Icons.ads_click_rounded
                  : Icons.volume_off_rounded,
              isEnabled: controller.isSfxEnabled,
              playPressSound: controller.isSfxEnabled,
              onPressed: controller.toggleSfx,
            ),
          ],
        );
      },
    );
  }
}

class _AudioToggleButton extends StatelessWidget {
  const _AudioToggleButton({
    required this.tooltip,
    required this.icon,
    required this.isEnabled,
    required this.playPressSound,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool isEnabled;
  final bool playPressSound;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final background = isEnabled ? Colors.white : DuoColors.softYellow;
    final foreground = isEnabled
        ? DuoColors.textPrimary
        : DuoColors.textSecondary;

    return Tooltip(
      message: tooltip,
      child: SmartStepsPressEffect(
        playSound: playPressSound,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size(44, 44),
            fixedSize: const Size(44, 44),
            padding: EdgeInsets.zero,
            elevation: 0,
            backgroundColor: background,
            foregroundColor: foreground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(
                color: isEnabled ? DuoColors.primaryYellow : DuoColors.border,
                width: 2,
              ),
            ),
          ),
          child: Icon(icon, size: 23),
        ),
      ),
    );
  }
}

String _catalogChildName(ChildProfile? profile) {
  final name = profile?.childName.trim();
  if (name == null || name.isEmpty) {
    return 'Bé SmartSteps';
  }

  return name;
}

// ignore: unused_element
class _CatalogTopBarOld extends StatelessWidget {
  const _CatalogTopBarOld();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;

        return DuoCard(
          color: DuoColors.primaryYellow,
          borderColor: DuoColors.darkYellow.withValues(alpha: 0.24),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 14 : 18,
            vertical: isCompact ? 14 : 16,
          ),
          child: Row(
            children: [
              _KidProfileAvatar(size: isCompact ? 58 : 68),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bé SmartSteps',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: GameColors.ink,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    Text(
                      'Bài học an toàn cho bé',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 1, height: 0.1),
                    ),
                    const SizedBox(height: 9),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 7,
                      children: [
                        _HeaderMetricChip(
                          icon: Icons.local_fire_department_rounded,
                          label: '0/9 bài',
                          color: DuoColors.softYellow,
                          iconColor: Color(0xFFE86D1F),
                        ),
                        _HeaderMetricChip(
                          icon: Icons.star_rounded,
                          label: '0 điểm',
                          color: Color(0xFFE9F8D5),
                          iconColor: Color(0xFF6BAF2A),
                        ),
                        _HeaderMetricChip(
                          icon: Icons.military_tech_rounded,
                          label: 'Cấp 4',
                          color: Color(0xFFFFFFFF),
                          iconColor: DuoColors.darkYellow,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const _HeaderPlanChip(plan: 'Miễn phí'),
            ],
          ),
        );
      },
    );
  }
}

class _KidProfileAvatar extends StatelessWidget {
  const _KidProfileAvatar({required this.size, this.profile});

  final double size;
  final ChildProfile? profile;

  @override
  Widget build(BuildContext context) {
    final avatar = RegistrationAvatarService.findByStoragePath(
      profile?.avatarStoragePath,
    );

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E785000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: ColoredBox(
          color: avatar?.color ?? const Color(0xFFBFE9FF),
          child: avatar == null
              ? Image.asset(
                  LessonAssets.kid,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.35),
                )
              : _RegistrationAvatarImage(avatar: avatar),
        ),
      ),
    );
  }
}

class _RegistrationAvatarImage extends StatelessWidget {
  const _RegistrationAvatarImage({required this.avatar});

  final RegistrationAvatar avatar;

  @override
  Widget build(BuildContext context) {
    final imageUrl = avatar.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Image.asset(avatar.assetPath, fit: BoxFit.cover);
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          Image.asset(avatar.assetPath, fit: BoxFit.cover),
    );
  }
}

class _HeaderMetricChip extends StatelessWidget {
  const _HeaderMetricChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: GameColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderPlanChip extends StatelessWidget {
  const _HeaderPlanChip({required this.plan, this.onPressed});

  final String plan;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Gói hiện tại',
      child: SmartStepsPressEffect(
        enabled: onPressed != null,
        child: Material(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPressed,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: DuoColors.darkYellow,
                    size: 20,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    plan,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GameColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
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

class _IslandCatalogEntry {
  const _IslandCatalogEntry({
    required this.islandId,
    required this.name,
    required this.orderIndex,
    required this.lessonCount,
    this.imageUrl,
  });

  factory _IslandCatalogEntry.fromSummary(IslandSummary summary) {
    return _IslandCatalogEntry(
      islandId: summary.islandId,
      name: summary.name,
      orderIndex: summary.orderIndex,
      lessonCount: summary.situationCount,
      imageUrl: summary.imageUrl,
    );
  }

  final int islandId;
  final String name;
  final int orderIndex;
  final int lessonCount;
  final String? imageUrl;
}

_IslandCatalogEntry? _islandById(
  List<_IslandCatalogEntry> islands,
  int islandId,
) {
  for (final island in islands) {
    if (island.islandId == islandId) {
      return island;
    }
  }

  return null;
}

bool _isSituationPublished(SituationSummary situation) {
  return situation.status.toLowerCase() == 'published';
}

bool _requiresPremium(SituationSummary situation) {
  return (situation.islandId == 2 || situation.islandId == 3) &&
      situation.orderIndex >= 2;
}

bool _isSituationUnlocked(SituationSummary situation, bool isPremium) {
  return _isSituationPublished(situation) &&
      (isPremium || !_requiresPremium(situation));
}

String _lockedSituationLabel(SituationSummary situation) {
  return _isSituationPublished(situation) ? 'PREMIUM' : 'SẮP MỞ';
}

// ignore: unused_element
class _CatalogContentFrame extends StatelessWidget {
  const _CatalogContentFrame({
    required this.isLoading,
    required this.error,
    required this.child,
  });

  final bool isLoading;
  final String? error;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DuoColors.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: DuoColors.border, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F6B5B00),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFFDF4), DuoColors.background],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: isLoading
                  ? const _CatalogMessage(
                      icon: Icons.sync_rounded,
                      title: 'Đang tải dữ liệu',
                      body: 'SmartSteps đang kết nối backend.',
                    )
                  : error != null
                  ? _CatalogMessage(
                      icon: Icons.cloud_off_rounded,
                      title: 'Không tải được dữ liệu',
                      body: error!,
                    )
                  : child,
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _IslandCatalogViewNew extends StatelessWidget {
  const _IslandCatalogViewNew({
    required this.islands,
    required this.onSelected,
  });

  final List<_IslandCatalogEntry> islands;
  final ValueChanged<_IslandCatalogEntry> onSelected;

  @override
  Widget build(BuildContext context) {
    if (islands.isEmpty) {
      return const _CatalogMessage(
        icon: Icons.map_outlined,
        title: 'Chưa có đảo',
        body: 'Chưa có bài học đã xuất bản.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 560;
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _IslandJourneyHero(islandCount: islands.length),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Chọn đảo hôm nay',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: DuoColors.softYellow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${islands.length} đảo',
                    style: const TextStyle(
                      color: DuoColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (isWide)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.86,
                ),
                itemCount: islands.length,
                itemBuilder: (context, index) {
                  final island = islands[index];
                  return _IslandTile(
                    island: island,
                    onTap: () => onSelected(island),
                  );
                },
              )
            else
              for (final island in islands)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _IslandTile(
                    island: island,
                    onTap: () => onSelected(island),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _IslandJourneyHero extends StatelessWidget {
  const _IslandJourneyHero({required this.islandCount});

  final int islandCount;

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      color: const Color(0xFFFFF4B8),
      borderColor: DuoColors.primaryYellow,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _DockLabel('Nhiệm vụ hôm nay'),
                const SizedBox(height: 8),
                Text(
                  'Bản đồ an toàn của bé',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Mở từng đảo, hoàn thành ô bài học và nhận sao.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                DuoProgressBar(value: (islandCount / 6).clamp(0.18, 1)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 78,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 70,
                    height: 42,
                    decoration: BoxDecoration(
                      color: DuoColors.primaryYellow,
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
                Image.asset(LessonAssets.mascotHappyWave, width: 76),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _IslandCatalogView extends StatelessWidget {
  const _IslandCatalogView({required this.islands, required this.onSelected});

  final List<_IslandCatalogEntry> islands;
  final ValueChanged<_IslandCatalogEntry> onSelected;

  @override
  Widget build(BuildContext context) {
    if (islands.isEmpty) {
      return const _CatalogMessage(
        icon: Icons.map_outlined,
        title: 'Chưa có đảo',
        body: 'Backend chưa trả về tình huống đã xuất bản.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 560;
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _IslandJourneyHero(islandCount: islands.length),
            const SizedBox(height: 18),
            _CatalogHeader(
              label: 'Đảo học tập',
              title: 'Chọn đảo',
              subtitle: '${islands.length} đảo',
            ),
            const SizedBox(height: 14),
            if (isWide)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.96,
                ),
                itemCount: islands.length,
                itemBuilder: (context, index) {
                  final island = islands[index];
                  return _IslandTile(
                    island: island,
                    onTap: () => onSelected(island),
                  );
                },
              )
            else
              ...islands.map(
                (island) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _IslandTile(
                    island: island,
                    onTap: () => onSelected(island),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ignore: unused_element
class _IslandSituationViewNew extends StatelessWidget {
  const _IslandSituationViewNew({
    required this.island,
    required this.situations,
    required this.isLoadingSituations,
    required this.isPremium,
    required this.activeLessonId,
    required this.loadingSituationId,
    required this.onBack,
    required this.onLocked,
    required this.onSelected,
  });

  final _IslandCatalogEntry island;
  final List<SituationSummary> situations;
  final bool isLoadingSituations;
  final bool isPremium;
  final String? activeLessonId;
  final int? loadingSituationId;
  final VoidCallback onBack;
  final ValueChanged<SituationSummary> onLocked;
  final ValueChanged<SituationSummary> onSelected;

  @override
  Widget build(BuildContext context) {
    final progress = island.lessonCount == 0
        ? 0.0
        : (situations.length / island.lessonCount).clamp(0.12, 1.0).toDouble();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            _CircleIconButton(
              label: 'Quay lại',
              icon: Icons.arrow_back_rounded,
              onPressed: onBack,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DuoCard(
                color: DuoColors.primaryYellow,
                borderColor: DuoColors.darkYellow.withValues(alpha: 0.22),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: _CatalogPictureImage(
                          asset: _islandImageAsset(island.islandId),
                          imageUrl: island.imageUrl,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            island.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${island.lessonCount} bài học',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          DuoProgressBar(value: progress),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoadingSituations && situations.isEmpty)
          const _CatalogMessage(
            icon: Icons.sync_rounded,
            title: 'Đang tải',
            body: 'Đang mở bản đồ bài học.',
          )
        else if (situations.isEmpty)
          const _CatalogMessage(
            icon: Icons.auto_stories_outlined,
            title: 'Chưa có bài học',
            body: 'Đảo này chưa có bài học đã xuất bản.',
          )
        else
          _LessonPathView(
            situations: situations,
            isPremium: isPremium,
            activeLessonId: activeLessonId,
            loadingSituationId: loadingSituationId,
            onLocked: onLocked,
            onSelected: onSelected,
          ),
      ],
    );
  }
}

// ignore: unused_element
class _IslandSituationView extends StatelessWidget {
  const _IslandSituationView({
    required this.island,
    required this.situations,
    required this.isLoadingSituations,
    required this.activeLessonId,
    required this.loadingSituationId,
    required this.onBack,
    required this.onSelected,
  });

  final _IslandCatalogEntry island;
  final List<SituationSummary> situations;
  final bool isLoadingSituations;
  final String? activeLessonId;
  final int? loadingSituationId;
  final VoidCallback onBack;
  final ValueChanged<SituationSummary> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            _CircleIconButton(
              label: 'Quay lại danh sách đảo',
              icon: Icons.arrow_back_rounded,
              onPressed: onBack,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CatalogHeader(
                label: 'Tình huống',
                title: island.name,
                subtitle: '${island.lessonCount} bài',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (isLoadingSituations && situations.isEmpty)
          const _CatalogMessage(
            icon: Icons.sync_rounded,
            title: 'Đang tải',
            body: 'Đang mở các tình huống trong đảo.',
          )
        else if (situations.isEmpty)
          const _CatalogMessage(
            icon: Icons.auto_stories_outlined,
            title: 'Chưa có tình huống',
            body: 'Đảo này chưa có bài học đã xuất bản.',
          )
        else
          _LessonPathView(
            situations: situations,
            isPremium: false,
            activeLessonId: activeLessonId,
            loadingSituationId: loadingSituationId,
            onLocked: onSelected,
            onSelected: onSelected,
          ),
      ],
    );
  }
}

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader({
    required this.label,
    required this.title,
    required this.subtitle,
  });

  final String label;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _DockLabel(label),
        const SizedBox(height: 5),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 5),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _LessonPathView extends StatelessWidget {
  const _LessonPathView({
    required this.situations,
    required this.isPremium,
    required this.activeLessonId,
    required this.loadingSituationId,
    required this.onLocked,
    required this.onSelected,
  });

  final List<SituationSummary> situations;
  final bool isPremium;
  final String? activeLessonId;
  final int? loadingSituationId;
  final ValueChanged<SituationSummary> onLocked;
  final ValueChanged<SituationSummary> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 430),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.88),
          width: 3,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _LessonPathPainter(situations.length)),
          ),
          Column(
            children: [
              for (var index = 0; index < situations.length; index++) ...[
                Builder(
                  builder: (context) {
                    final situation = situations[index];
                    final isUnlocked = _isSituationUnlocked(
                      situation,
                      isPremium,
                    );

                    return _LessonPathNode(
                      situation: situation,
                      index: index,
                      isSelected:
                          activeLessonId ==
                          'situation-${situation.situationId}',
                      isLoading: loadingSituationId == situation.situationId,
                      isUnlocked: isUnlocked,
                      onTap: () => isUnlocked
                          ? onSelected(situation)
                          : onLocked(situation),
                    );
                  },
                ),
                if (index != situations.length - 1) const SizedBox(height: 22),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LessonPathNode extends StatelessWidget {
  const _LessonPathNode({
    required this.situation,
    required this.index,
    required this.isSelected,
    required this.isLoading,
    required this.isUnlocked,
    required this.onTap,
  });

  final SituationSummary situation;
  final int index;
  final bool isSelected;
  final bool isLoading;
  final bool isUnlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final alignment = switch (index % 4) {
      0 => Alignment.center,
      1 => const Alignment(0.62, 0),
      2 => const Alignment(-0.58, 0),
      _ => const Alignment(0.28, 0),
    };
    final color = isSelected
        ? GameColors.safe
        : isUnlocked
        ? DuoColors.primaryYellow
        : const Color(0xFFD7DCE2);
    final foreground = isUnlocked ? GameColors.ink : const Color(0xFF87909D);
    final lessonIcon = _situationIcon(situation);

    return Align(
      alignment: alignment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('situation-${situation.situationId}'),
              onTap: isLoading ? null : onTap,
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: isSelected ? 86 : 76,
                height: isSelected ? 86 : 76,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.94),
                    width: 7,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: isSelected ? 0.46 : 0.26),
                      blurRadius: isSelected ? 20 : 12,
                      offset: const Offset(0, 8),
                    ),
                    const BoxShadow(
                      color: Color(0x2625324B),
                      blurRadius: 8,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : Icon(
                        isSelected
                            ? Icons.play_arrow_rounded
                            : isUnlocked
                            ? lessonIcon
                            : Icons.lock_rounded,
                        color: foreground,
                        size: isSelected ? 40 : 34,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Container(
            constraints: const BoxConstraints(maxWidth: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? GameColors.safe
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isSelected
                  ? 'ĐÃ CHỌN'
                  : isUnlocked
                  ? 'Bài ${situation.orderIndex}'
                  : _lockedSituationLabel(situation),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : GameColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 160,
            child: Text(
              situation.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GameColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1.12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonPathPainter extends CustomPainter {
  const _LessonPathPainter(this.nodeCount);

  final int nodeCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodeCount < 2) {
      return;
    }

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.68)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    final step = size.height / nodeCount;

    path.moveTo(size.width * 0.5, step * 0.42);
    for (var index = 1; index < nodeCount; index++) {
      final y = step * (index + 0.3);
      final x = switch (index % 4) {
        1 => size.width * 0.78,
        2 => size.width * 0.23,
        3 => size.width * 0.62,
        _ => size.width * 0.5,
      };
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LessonPathPainter oldDelegate) {
    return oldDelegate.nodeCount != nodeCount;
  }
}

class _IslandTile extends StatelessWidget {
  const _IslandTile({required this.island, required this.onTap});

  final _IslandCatalogEntry island;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _islandAccent(island.islandId);

    return SmartStepsPressEffect(
      child: Material(
        color: DuoColors.card,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          key: ValueKey('island-${island.islandId}'),
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 168),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.82),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 92,
                  child: _CatalogPicture(
                    asset: _islandImageAsset(island.islandId),
                    imageUrl: island.imageUrl,
                    accent: accent,
                    icon: Icons.terrain_rounded,
                    padding: const EdgeInsets.all(18),
                  ),
                ),
                const SizedBox(height: 12),
                DuoProgressBar(
                  value: (island.lessonCount / 3).clamp(0.18, 1.0),
                  height: 12,
                  color: DuoColors.success,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        island.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${island.lessonCount}',
                        style: const TextStyle(
                          color: GameColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: accent, size: 30),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogPicture extends StatelessWidget {
  const _CatalogPicture({
    required this.asset,
    this.imageUrl,
    required this.accent,
    required this.icon,
    required this.padding,
  });

  final String asset;
  final String? imageUrl;
  final Color accent;
  final IconData icon;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: padding,
              child: _CatalogPictureImage(asset: asset, imageUrl: imageUrl),
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.84),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(icon, color: accent, size: 21),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogPictureImage extends StatelessWidget {
  const _CatalogPictureImage({required this.asset, required this.imageUrl});

  final String asset;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final localImageAsset = imageUrl?.trim();
    if (localImageAsset != null && localImageAsset.startsWith('assets/')) {
      return Image.asset(
        localImageAsset,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Image.asset(asset, fit: BoxFit.contain),
      );
    }

    final uri = imageUrl == null ? null : Uri.tryParse(imageUrl!);
    if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Image.asset(asset, fit: BoxFit.contain),
      );
    }

    return Image.asset(asset, fit: BoxFit.contain);
  }
}

// ignore: unused_element
class _SituationTile extends StatelessWidget {
  const _SituationTile({
    required this.situation,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
  });

  final SituationSummary situation;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isSelected
        ? GameColors.safe
        : _islandAccent(situation.islandId);

    return SmartStepsPressEffect(
      enabled: !isLoading,
      child: Material(
        color: isSelected
            ? GameColors.mint.withValues(alpha: 0.74)
            : Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          key: ValueKey('situation-${situation.situationId}'),
          borderRadius: BorderRadius.circular(24),
          onTap: isLoading ? null : onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 126),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? GameColors.safe.withValues(alpha: 0.62)
                    : Colors.white.withValues(alpha: 0.82),
                width: 3,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 104,
                  height: 104,
                  child: _CatalogPicture(
                    asset: _situationImageAsset(situation),
                    accent: accent,
                    icon: Icons.play_arrow_rounded,
                    padding: const EdgeInsets.all(13),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        situation.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isLoading
                              ? 'Đang tải'
                              : 'Bài ${situation.orderIndex}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: GameColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                isLoading
                    ? const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.chevron_right_rounded,
                        color: isSelected ? GameColors.safe : GameColors.ink,
                        size: 32,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _islandImageAsset(int islandId) {
  return switch (islandId) {
    _ => LessonAssets.islandIcon,
  };
}

String _situationImageAsset(SituationSummary situation) {
  const assets = [
    LessonAssets.ball,
    LessonAssets.kid,
    LessonAssets.childHappy,
    LessonAssets.mother,
    LessonAssets.childChoking,
    LessonAssets.islandIcon,
  ];

  return assets[(situation.orderIndex - 1).abs() % assets.length];
}

IconData _situationIcon(SituationSummary situation) {
  final text = '${situation.title} ${situation.intro ?? ''}'.toLowerCase();
  if (text.contains('đường') || text.contains('giao thông')) {
    return Icons.traffic_rounded;
  }
  if (text.contains('siêu thị') || text.contains('bị lạc')) {
    return Icons.storefront_rounded;
  }
  if (text.contains('người lạ') || text.contains('cảnh giác')) {
    return Icons.person_off_rounded;
  }
  if (text.contains('bạn bè') || text.contains('thách đố')) {
    return Icons.groups_rounded;
  }
  if (text.contains('ví') || text.contains('nhặt được')) {
    return Icons.account_balance_wallet_rounded;
  }
  if (text.contains('vật') || text.contains('miệng')) {
    return Icons.radio_button_checked_rounded;
  }
  if (text.contains('điện') || text.contains('ổ cắm')) {
    return Icons.bolt_rounded;
  }
  if (text.contains('nước nóng') || text.contains('bỏng')) {
    return Icons.local_fire_department_rounded;
  }
  if (text.contains('nước') || text.contains('hồ')) {
    return Icons.water_drop_rounded;
  }

  return Icons.shield_rounded;
}

// ignore: unused_element
class _SelectedLessonPreview extends StatelessWidget {
  const _SelectedLessonPreview({required this.lesson});

  final SafetyLesson lesson;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Image.asset(LessonAssets.mascotConfident, width: 58),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const _DockLabel('Đã chọn'),
                const SizedBox(height: 5),
                Text(
                  lesson.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  lesson.mission,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogMessage extends StatelessWidget {
  const _CatalogMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _GlassPanel(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: GameColors.ink, size: 40),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

Color _islandAccent(int islandId) {
  const colors = [
    GameColors.safe,
    Color(0xFF35A7FF),
    GameColors.coral,
    Color(0xFF8F7CFF),
  ];

  return colors[(islandId - 1).abs() % colors.length];
}

const _fallbackIslandEntries = [
  _IslandCatalogEntry(
    islandId: 1,
    name: 'Đảo An Toàn',
    orderIndex: 1,
    lessonCount: 3,
  ),
  _IslandCatalogEntry(
    islandId: 2,
    name: 'Đảo Tình Bạn',
    orderIndex: 2,
    lessonCount: 3,
  ),
  _IslandCatalogEntry(
    islandId: 3,
    name: 'Đảo Trường Học',
    orderIndex: 3,
    lessonCount: 3,
  ),
];

class SmartStepsLegacyLandingPage extends StatefulWidget {
  const SmartStepsLegacyLandingPage({
    super.key,
    required this.situationService,
  });

  final SituationService situationService;

  @override
  State<SmartStepsLegacyLandingPage> createState() =>
      _SmartStepsLandingPageState();
}

class _SmartStepsLandingPageState extends State<SmartStepsLegacyLandingPage> {
  List<SituationSummary> _situations = const [];
  SafetyLesson? _activeLesson;
  bool _isLoadingSituations = false;
  int? _loadingSituationId;
  String? _catalogError;

  SituationService get _situationService => widget.situationService;

  @override
  void initState() {
    super.initState();
    unawaited(_enterLandingViewingMode());
    unawaited(_loadSituations());
  }

  Future<void> _enterLandingViewingMode() async {
    try {
      await SystemChrome.setPreferredOrientations(_outsidePortraitOrientations);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (_) {
      // Some desktop/test hosts do not expose system chrome controls.
    }
  }

  Future<void> _loadSituations() async {
    if (!_situationService.isEnabled) {
      setState(() {
        _catalogError =
            'Missing SMARTSTEPS_API_BASE_URL. Run with --dart-define=SMARTSTEPS_API_BASE_URL=http://10.0.2.2:5078';
      });
      return;
    }

    setState(() {
      _isLoadingSituations = true;
      _catalogError = null;
    });

    try {
      final situations = await _situationService.getSituations();
      if (situations.isEmpty) {
        if (mounted) {
          setState(() {
            _situations = const [];
            _activeLesson = null;
            _catalogError = 'Backend returned no published lessons.';
            _isLoadingSituations = false;
          });
        }
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _situations = situations;
        _activeLesson = null;
        _isLoadingSituations = false;
      });
    } catch (error, stackTrace) {
      debugPrint('SmartSteps situation catalog failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _catalogError = 'Không tải được dữ liệu backend';
          _activeLesson = null;
          _isLoadingSituations = false;
        });
      }
    }
  }

  Future<SafetyLesson> _loadLesson(SituationSummary summary) async {
    final detail = await _situationService.getSituationDetail(
      summary.situationId,
    );
    return _lessonFromSituation(detail);
  }

  Future<void> _selectSituation(SituationSummary summary) async {
    if (_loadingSituationId == summary.situationId) {
      return;
    }

    setState(() {
      _loadingSituationId = summary.situationId;
      _catalogError = null;
    });

    try {
      final lesson = await _loadLesson(summary);
      if (!mounted) {
        return;
      }

      setState(() {
        _activeLesson = lesson;
      });
    } catch (error, stackTrace) {
      debugPrint('SmartSteps situation detail failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _catalogError = 'Không tải được bài học';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingSituationId = null;
        });
      }
    }
  }

  Future<void> _openLesson() async {
    final lesson = _activeLesson;
    if (lesson == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LessonGameScreen(lesson: lesson, isLastLesson: false),
      ),
    );

    if (mounted) {
      unawaited(_enterLandingViewingMode());
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _activeLesson;
    final canStartLesson = lesson != null && !_isLoadingSituations;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE4F7FF), GameColors.cream],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Image.asset(LessonAssets.mascotHappyWave, width: 54),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _DockLabel('SmartSteps'),
                          Text(
                            'Bài học an toàn cho bé',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(LessonAssets.livingRoom, fit: BoxFit.cover),
                        const _WarmSceneOverlay(),
                        Positioned(
                          left: 18,
                          right: 18,
                          top: 18,
                          child: _GlassPanel(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const _DockLabel('Bài 1'),
                                const SizedBox(height: 6),
                                Text(
                                  lesson?.title ?? 'Dang tai bai hoc',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  lesson?.mission ??
                                      _catalogError ??
                                      'Dang ket noi toi backend SmartSteps.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: -4,
                          bottom: 0,
                          child: Image.asset(
                            LessonAssets.kid,
                            width: 210,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _LessonCatalogStrip(
                  situations: _situations,
                  activeLessonId: lesson?.id,
                  isLoading: _isLoadingSituations,
                  loadingSituationId: _loadingSituationId,
                  error: _catalogError,
                  onSelected: (summary) {
                    unawaited(_selectSituation(summary));
                  },
                ),
                const SizedBox(height: 16),
                _PillButton(
                  label: 'Bắt đầu bài học',
                  icon: Icons.play_arrow_rounded,
                  color: GameColors.banana,
                  onPressed: canStartLesson
                      ? () {
                          unawaited(_openLesson());
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonCatalogStrip extends StatelessWidget {
  const _LessonCatalogStrip({
    required this.situations,
    required this.activeLessonId,
    required this.isLoading,
    required this.loadingSituationId,
    required this.error,
    required this.onSelected,
  });

  final List<SituationSummary> situations;
  final String? activeLessonId;
  final bool isLoading;
  final int? loadingSituationId;
  final String? error;
  final ValueChanged<SituationSummary> onSelected;

  @override
  Widget build(BuildContext context) {
    if (situations.isEmpty) {
      return SizedBox(
        height: 42,
        child: Align(
          alignment: Alignment.centerLeft,
          child: _DockLabel(
            error ??
                (isLoading ? 'Đang tải backend' : 'Chưa có bài học từ API'),
          ),
        ),
      );
    }

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: situations.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final situation = situations[index];
          final lessonId = 'situation-${situation.situationId}';
          final isSelected = activeLessonId == lessonId;
          final isBusy = loadingSituationId == situation.situationId;

          return ChoiceChip(
            selected: isSelected,
            label: Text(
              isBusy ? '...' : situation.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onSelected: (_) => onSelected(situation),
            labelStyle: const TextStyle(
              color: GameColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.72),
            selectedColor: GameColors.banana,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.78)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}

class _ParentalGateDialog extends StatefulWidget {
  const _ParentalGateDialog();

  @override
  State<_ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<_ParentalGateDialog> {
  final TextEditingController _answerController = TextEditingController();
  late int _num1;
  late int _num2;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    // Tạo phép nhân đơn giản ngẫu nhiên từ 2 đến 9
    _num1 = random.nextInt(8) + 2;
    _num2 = random.nextInt(8) + 2;
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    final answer = int.tryParse(_answerController.text.trim());
    // Kiểm tra kết quả phép tính
    if (answer == _num1 * _num2) {
      Navigator.of(context).pop(true); // Trả về true nếu tính đúng
    } else {
      setState(() {
        _errorText = 'Kết quả chưa chính xác!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Dành cho phụ huynh',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFF7A1A)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Vui lòng giải phép tính sau để tiếp tục:',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '$_num1 x $_num2 = ?',
            key: const ValueKey('parental-gate-question'),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('parental-gate-answer-field'),
            controller: _answerController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Nhập kết quả',
              errorText: _errorText,
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Hủy',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
        FilledButton(
          onPressed: _checkAnswer,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFE99C),
            foregroundColor: Colors.black,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
