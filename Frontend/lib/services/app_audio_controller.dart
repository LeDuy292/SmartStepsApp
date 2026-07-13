import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class SmartStepsAudioAssets {
  const SmartStepsAudioAssets._();

  static const backgroundMusic = 'audio/CatAmongTheFlowerPots.mp3';
  static const buttonTap = 'audio/button-click-291234.mp3';
  static const success = 'audio/success_chime.wav';
  static const celebration = 'audio/crowd_cheer.mp3';
  static const warning = 'audio/wrongAnswer.mp3';
}

final _backgroundMusicAudioContext = AudioContext(
  android: const AudioContextAndroid(
    contentType: AndroidContentType.music,
    usageType: AndroidUsageType.media,
    audioFocus: AndroidAudioFocus.gain,
  ),
  iOS: AudioContextIOS(
    category: AVAudioSessionCategory.playback,
    options: const {AVAudioSessionOptions.mixWithOthers},
  ),
);

final _sfxAudioContext = AudioContext(
  android: const AudioContextAndroid(
    contentType: AndroidContentType.sonification,
    usageType: AndroidUsageType.assistanceSonification,
    audioFocus: AndroidAudioFocus.none,
  ),
  iOS: AudioContextIOS(
    category: AVAudioSessionCategory.playback,
    options: const {AVAudioSessionOptions.mixWithOthers},
  ),
);

class SmartStepsAudioController extends ChangeNotifier
    with WidgetsBindingObserver {
  SmartStepsAudioController()
    : _musicPlayer = AudioPlayer(playerId: 'smartsteps-background-music'),
      _tapPlayer = AudioPlayer(playerId: 'smartsteps-button-tap'),
      _successPlayer = AudioPlayer(playerId: 'smartsteps-success-chime'),
      _celebrationPlayer = AudioPlayer(
        playerId: 'smartsteps-celebration-applause',
      ),
      _warningPlayer = AudioPlayer(playerId: 'smartsteps-warning-alert');

  static const _normalMusicVolume = 0.6;
  static const _duckedMusicVolume = 0.0;

  final AudioPlayer _musicPlayer;
  final AudioPlayer _tapPlayer;
  final AudioPlayer _successPlayer;
  final AudioPlayer _celebrationPlayer;
  final AudioPlayer _warningPlayer;
  StreamSubscription<PlayerState>? _musicStateSubscription;
  Timer? _celebrationStopTimer;

  bool _isStarted = false;
  bool _isDisposed = false;
  bool _isPausedByLifecycle = false;
  bool _isRecoveringMusic = false;
  bool _isMusicEnabled = true;
  bool _isSfxEnabled = true;
  int _duckDepth = 0;

  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSfxEnabled => _isSfxEnabled;

  Future<void> startBackgroundMusic() async {
    if (_isStarted || _isDisposed || !_isMusicEnabled) {
      return;
    }

    _isStarted = true;
    WidgetsBinding.instance.addObserver(this);

    try {
      await _musicPlayer.setAudioContext(_backgroundMusicAudioContext);
      await _musicPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(_targetMusicVolume);
      _musicStateSubscription ??= _musicPlayer.onPlayerStateChanged.listen(
        _handleMusicStateChanged,
      );
      await _musicPlayer.play(
        AssetSource(SmartStepsAudioAssets.backgroundMusic),
      );
    } catch (error, stackTrace) {
      _logAudioFailure('background music start', error, stackTrace);
    }
  }

  void playButtonTap() {
    if (!_isSfxEnabled) {
      return;
    }

    unawaited(HapticFeedback.selectionClick());
    unawaited(_playSfx(_tapPlayer, SmartStepsAudioAssets.buttonTap, volume: 1));
    unawaited(_recoverMusicAfter(const Duration(milliseconds: 220)));
  }

  void playSuccess() {
    if (!_isSfxEnabled) {
      return;
    }

    unawaited(HapticFeedback.lightImpact());
    unawaited(
      _playSfx(_successPlayer, SmartStepsAudioAssets.success, volume: 0.74),
    );
    unawaited(_recoverMusicAfter(const Duration(milliseconds: 820)));
  }

  void playCelebration({Duration? maxDuration}) {
    if (!_isSfxEnabled) {
      return;
    }

    _celebrationStopTimer?.cancel();
    unawaited(HapticFeedback.heavyImpact());
    unawaited(
      _playSfx(
        _celebrationPlayer,
        SmartStepsAudioAssets.celebration,
        volume: 0.94,
        releaseMode: ReleaseMode.loop,
      ),
    );
    if (maxDuration != null) {
      _celebrationStopTimer = Timer(maxDuration, stopCelebration);
      unawaited(_recoverMusicAfter(maxDuration));
    }
  }

  void stopCelebration() {
    _celebrationStopTimer?.cancel();
    _celebrationStopTimer = null;
    if (_isDisposed) {
      return;
    }

    unawaited(_stopSfx(_celebrationPlayer, 'celebration'));
  }

  void playWarning() {
    if (!_isSfxEnabled) {
      return;
    }

    unawaited(HapticFeedback.mediumImpact());
    unawaited(
      _playSfx(_warningPlayer, SmartStepsAudioAssets.warning, volume: 0.78),
    );
    unawaited(_recoverMusicAfter(const Duration(milliseconds: 900)));
  }

  void duckMusic() {
    final shouldPauseMusic = _duckDepth == 0;
    _duckDepth += 1;
    if (shouldPauseMusic) {
      unawaited(_pauseMusicForDuck());
    }
  }

  void restoreMusic() {
    if (_duckDepth > 0) {
      _duckDepth -= 1;
    }
    if (_duckDepth == 0) {
      unawaited(ensureBackgroundMusicPlaying());
      return;
    }

    unawaited(_applyMusicVolume());
  }

  void setMusicEnabled(bool isEnabled) {
    if (_isMusicEnabled == isEnabled) {
      return;
    }

    _isMusicEnabled = isEnabled;
    notifyListeners();

    if (isEnabled) {
      unawaited(ensureBackgroundMusicPlaying());
    } else {
      unawaited(_musicPlayer.pause());
    }
  }

  void setSfxEnabled(bool isEnabled) {
    if (_isSfxEnabled == isEnabled) {
      return;
    }

    _isSfxEnabled = isEnabled;
    if (!isEnabled) {
      stopCelebration();
    }
    notifyListeners();
  }

  void toggleMusic() {
    setMusicEnabled(!_isMusicEnabled);
  }

  void toggleSfx() {
    setSfxEnabled(!_isSfxEnabled);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed || !_isStarted) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        if (_isPausedByLifecycle) {
          _isPausedByLifecycle = false;
          unawaited(_resumeMusic());
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _isPausedByLifecycle = true;
        unawaited(_musicPlayer.pause());
    }
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _celebrationStopTimer?.cancel();
    unawaited(_musicStateSubscription?.cancel());
    unawaited(_musicPlayer.dispose());
    unawaited(_tapPlayer.dispose());
    unawaited(_successPlayer.dispose());
    unawaited(_celebrationPlayer.dispose());
    unawaited(_warningPlayer.dispose());
    super.dispose();
  }

  Future<void> ensureBackgroundMusicPlaying() async {
    if (_isDisposed ||
        _isPausedByLifecycle ||
        !_isMusicEnabled ||
        _duckDepth > 0) {
      return;
    }

    if (!_isStarted) {
      await startBackgroundMusic();
      return;
    }

    try {
      await _musicPlayer.setAudioContext(_backgroundMusicAudioContext);
      await _musicPlayer.setVolume(_targetMusicVolume);
      if (_musicPlayer.state == PlayerState.playing) {
        return;
      }

      await _musicPlayer.resume();
      if (_musicPlayer.state != PlayerState.playing) {
        await _musicPlayer.play(
          AssetSource(SmartStepsAudioAssets.backgroundMusic),
        );
      }
    } catch (error, stackTrace) {
      _logAudioFailure('background music recover', error, stackTrace);
    }
  }

  double get _targetMusicVolume =>
      _duckDepth > 0 ? _duckedMusicVolume : _normalMusicVolume;

  Future<void> _resumeMusic() async {
    if (!_isMusicEnabled || _duckDepth > 0) {
      return;
    }

    try {
      await _musicPlayer.setAudioContext(_backgroundMusicAudioContext);
      await _musicPlayer.setVolume(_targetMusicVolume);
      await _musicPlayer.resume();
    } catch (error, stackTrace) {
      _logAudioFailure('background music resume', error, stackTrace);
    }
  }

  void _handleMusicStateChanged(PlayerState state) {
    if (_isDisposed ||
        !_isStarted ||
        !_isMusicEnabled ||
        _isPausedByLifecycle ||
        _duckDepth > 0 ||
        _isRecoveringMusic) {
      return;
    }

    if (state == PlayerState.paused || state == PlayerState.stopped) {
      unawaited(_recoverMusicAfter(const Duration(milliseconds: 260)));
    }
  }

  Future<void> _recoverMusicAfter(Duration delay) async {
    if (_isRecoveringMusic) {
      return;
    }

    _isRecoveringMusic = true;
    try {
      await Future<void>.delayed(delay);
      if (_duckDepth == 0 && _isMusicEnabled) {
        await ensureBackgroundMusicPlaying();
      }
    } finally {
      _isRecoveringMusic = false;
    }
  }

  Future<void> _applyMusicVolume() async {
    if (!_isStarted || _isDisposed || !_isMusicEnabled) {
      return;
    }

    try {
      await _musicPlayer.setVolume(_targetMusicVolume);
    } catch (error, stackTrace) {
      _logAudioFailure('background music volume', error, stackTrace);
    }
  }

  Future<void> _pauseMusicForDuck() async {
    if (!_isStarted || _isDisposed || !_isMusicEnabled) {
      return;
    }

    try {
      await _musicPlayer.pause();
    } catch (error, stackTrace) {
      _logAudioFailure('background music duck pause', error, stackTrace);
    }
  }

  Future<void> _playSfx(
    AudioPlayer player,
    String asset, {
    required double volume,
    ReleaseMode releaseMode = ReleaseMode.stop,
  }) async {
    if (_isDisposed) {
      return;
    }

    try {
      await player.setAudioContext(_sfxAudioContext);
      await player.setPlayerMode(PlayerMode.mediaPlayer);
      await player.setReleaseMode(releaseMode);
      await player.stop();
      await player.setVolume(volume);
      await player.play(AssetSource(asset));
    } catch (error, stackTrace) {
      _logAudioFailure('sfx $asset', error, stackTrace);
    }
  }

  Future<void> _stopSfx(AudioPlayer player, String label) async {
    try {
      await player.stop();
    } catch (error, stackTrace) {
      _logAudioFailure('sfx stop $label', error, stackTrace);
    }
  }

  void _logAudioFailure(String label, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('SmartSteps audio $label failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

class SmartStepsAudioScope extends InheritedWidget {
  const SmartStepsAudioScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final SmartStepsAudioController controller;

  static SmartStepsAudioController? maybeOf(BuildContext context) {
    final scope = context
        .getElementForInheritedWidgetOfExactType<SmartStepsAudioScope>()
        ?.widget;
    return scope is SmartStepsAudioScope ? scope.controller : null;
  }

  @override
  bool updateShouldNotify(SmartStepsAudioScope oldWidget) {
    return oldWidget.controller != controller;
  }
}
