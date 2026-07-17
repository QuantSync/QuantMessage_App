import 'dart:async';
import 'package:flutter/material.dart';

/// Wraps a widget (typically MarkdownBody) to provide a fast text reveal
/// and fade-in animation for newly generated AI messages.
class FastRevealText extends StatefulWidget {
  final String text;
  final Widget Function(String) builder;
  final Duration typingDuration;
  final Duration fadeDuration;

  const FastRevealText({
    super.key,
    required this.text,
    required this.builder,
    this.typingDuration = const Duration(milliseconds: 15),
    this.fadeDuration = const Duration(milliseconds: 600),
  });

  @override
  State<FastRevealText> createState() => _FastRevealTextState();
}

class _FastRevealTextState extends State<FastRevealText>
    with SingleTickerProviderStateMixin {
  String _displayedText = "";
  int _currentIndex = 0;
  Timer? _typingTimer;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();

    _startAnimation();
  }

  void _startAnimation() {
    _typingTimer?.cancel();
    // Reveal text in chunks for a "fast" effect.
    int chunkSize = (widget.text.length / 50).ceil().clamp(1, 15);
    
    _typingTimer = Timer.periodic(widget.typingDuration, (timer) {
      if (_currentIndex < widget.text.length) {
        if (mounted) {
          setState(() {
            _currentIndex += chunkSize;
            if (_currentIndex > widget.text.length) {
              _currentIndex = widget.text.length;
            }
            _displayedText = widget.text.substring(0, _currentIndex);
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void didUpdateWidget(FastRevealText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      if (widget.text.startsWith(_displayedText)) {
        // Continuing stream
        _startAnimation();
      } else {
        // Entirely new text
        _currentIndex = 0;
        _displayedText = "";
        _fadeCtrl.reset();
        _fadeCtrl.forward();
        _typingTimer?.cancel();
        _startAnimation();
      }
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: widget.builder(_displayedText),
    );
  }
}
