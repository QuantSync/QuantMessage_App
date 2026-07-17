// lib/screens/animations/animation_effects/step_status_text.dart
// QuantMessage — Step-by-step status text displayed during AI processing.
// Shows the 4-agent pipeline steps (Thinker, Reviewer, Supervisor, Producer)
// or generic placeholders while waiting.
// Integrated with: ChatScreen, IncognitoScreen
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dotted_loading_animation.dart';

/// Default steps shown while the backend is busy (pre-response).
const List<String> kThinkingSteps = [
  '🧠 Thinker: Analysing your request…',
  '🔍 Reviewer: Checking for accuracy…',
  '🎯 Supervisor: Orchestrating agents…',
  '✨ Producer: Preparing your answer…',
];

/// A compact animated widget that shows:
///  1. A small [DottedLoadingAnimationAlt] spinner.
///  2. Green italic step text cycling through [steps] or [kThinkingSteps].
///
/// When [steps] is non-empty (returned by the backend), it cycles
/// through those real pipeline steps. Otherwise uses the placeholders.
class StepStatusText extends StatefulWidget {
  /// How long each step is displayed before advancing.
  final Duration stepDuration;

  /// Real pipeline steps returned by the backend after the response.
  /// Pass an empty list while waiting (will show kThinkingSteps placeholders).
  final List<String> steps;

  const StepStatusText({
    super.key,
    this.stepDuration = const Duration(milliseconds: 1800),
    this.steps = const [],
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

  List<String> get _displaySteps =>
      widget.steps.isNotEmpty ? widget.steps : kThinkingSteps;

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
      _fadeCtrl.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _currentStep = (_currentStep + 1) % _displaySteps.length;
        });
        _fadeCtrl.forward();
      });
    });
  }

  @override
  void didUpdateWidget(StepStatusText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When real steps arrive from backend, reset to step 0
    if (oldWidget.steps != widget.steps) {
      setState(() => _currentStep = 0);
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _displaySteps;
    final currentText =
        steps.isNotEmpty ? steps[_currentStep % steps.length] : '';

    final screenWidth = MediaQuery.of(context).size.width;
    final leftPadding = screenWidth * 0.175; // Align with the 65% width center card

    return Padding(
      padding: EdgeInsets.only(left: leftPadding, top: 6, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const DottedLoadingAnimationAlt(
            size: 18,
            dotCount: 6,
            color: Color(0xFF2ECC71),
            duration: Duration(milliseconds: 1200),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                currentText,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2ECC71),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600, // increased weight for crispness
                  height: 1.3,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
