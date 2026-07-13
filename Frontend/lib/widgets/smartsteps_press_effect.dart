import 'package:flutter/material.dart';

import '../services/app_audio_controller.dart';

class SmartStepsPressEffect extends StatefulWidget {
  const SmartStepsPressEffect({
    super.key,
    required this.child,
    this.enabled = true,
    this.playSound = true,
    this.pressedScale = 0.96,
  });

  final Widget child;
  final bool enabled;
  final bool playSound;
  final double pressedScale;

  @override
  State<SmartStepsPressEffect> createState() => _SmartStepsPressEffectState();
}

class _SmartStepsPressEffectState extends State<SmartStepsPressEffect> {
  bool _isPressed = false;

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.enabled) {
      return;
    }

    if (!_isPressed) {
      setState(() {
        _isPressed = true;
      });
    }

    if (widget.playSound) {
      SmartStepsAudioScope.maybeOf(context)?.playButtonTap();
    }
  }

  void _clearPressed() {
    if (!_isPressed) {
      return;
    }

    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: _handlePointerDown,
      onPointerUp: (_) => _clearPressed(),
      onPointerCancel: (_) => _clearPressed(),
      child: AnimatedScale(
        scale: widget.enabled && _isPressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 95),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
