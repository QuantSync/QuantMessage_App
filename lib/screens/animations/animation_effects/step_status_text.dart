// lib/screens/animations/animation_effects/step_status_text.dart
// QuantMessage — Step-by-step status text displayed during AI processing
// Shows sequential green italic messages below the user's message card
// Integrated with: ChatScreen, IncognitoScreen, DottedLoadingAnimationAlt
// ------------------------------------------------------------------------------

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dotted_loading_animation.dart';

/// The ordered status steps displayed while the AI is processing.
const List<String> kThinkingSteps = [
  'Choosing right model…',
  'Analysing query…',
  'Searching web…',
  'Figuring out solutions…',
];

/// A compact widget that shows:
///  1. A small [DottedLoadingAnimationAlt] on the left.
///  2. Green italic step-text that advances automatically through [kThinkingSteps].
///
/// Place this directly below the user's [MessageCard] inside the chat thread
/// while [isTyping] is true.
class StepStatusText extends StatefulWidget {
  /// How long each step is displayed before advancing to the next.
  final Duration stepDuration;

  const StepStatusText({
    super.key,
    this.stepDuration = const Duration(milliseconds: 1800),
  });

  @override
  State<StepStatusText> createState() => _StepStatusTextState();
}

class _StepStatusTextState extends State<StepStatusText>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  Timer? _stepTimer;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();

    _stepTimer = Timer.periodic(widget.stepDuration, (_) {
      if (!mounted) return;
      // Fade-out → switch text → fade-in
      _fadeCtrl.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _currentStep = (_currentStep + 1) % kThinkingSteps.length;
        });
        _fadeCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 60, top: 6, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Small dotted loading spinner
          const DottedLoadingAnimationAlt(
            size: 18,
            dotCount: 6,
            color: Color(0xFF2ECC71),
            duration: Duration(milliseconds: 1200),
          ),
          const SizedBox(width: 8),
          // Animated green italic step text
          FadeTransition(
            opacity: _fadeAnim,
            child: Text(
              kThinkingSteps[_currentStep],
              style: GoogleFonts.outfit(
                color: const Color(0xFF2ECC71),
                fontSize: 12,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
