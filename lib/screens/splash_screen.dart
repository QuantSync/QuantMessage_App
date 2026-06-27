import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _isExiting = false;

  late final AnimationController _particleCtrl;
  late final AnimationController _badgeCtrl;
  late final Animation<double> _badgeOpacity;
  late final Animation<double> _badgeScale;

  late final AnimationController _titleCtrl;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _titleScale;
  late final Animation<Offset> _titleSlide;

  late final AnimationController _shimmerCtrl;
  late final AnimationController _scanlineCtrl;

  @override
  void initState() {
    super.initState();

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    )..repeat();

    _badgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _badgeOpacity = CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeOut);
    _badgeScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeOutBack),
    );
    _badgeCtrl.forward();

    _titleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _titleOpacity = CurvedAnimation(parent: _titleCtrl, curve: Curves.easeOut);
    _titleScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _titleCtrl, curve: Curves.easeOutCubic),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _titleCtrl, curve: Curves.easeOutCubic));

    // Trigger title animation after badge
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _titleCtrl.forward();
    });

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _scanlineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    _badgeCtrl.dispose();
    _titleCtrl.dispose();
    _shimmerCtrl.dispose();
    _scanlineCtrl.dispose();
    super.dispose();
  }

  void _startExitSequence() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isExiting = true);

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1000),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, -0.04), end: Offset.zero)
                  .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              painter: _SplashParticlePainter(_particleCtrl.value),
              size: size,
            ),
          ),
          AnimatedBuilder(
            animation: _scanlineCtrl,
            builder: (_, __) => Opacity(
              opacity: 0.018 + _scanlineCtrl.value * 0.012,
              child: CustomPaint(
                painter: _ScanlinePainter(),
                size: size,
              ),
            ),
          ),
          _buildCornerGlows(),
          Center(
            child: AnimatedScale(
              scale: _isExiting ? 1.06 : 1.0,
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              child: AnimatedOpacity(
                opacity: _isExiting ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeInOut,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _badgeOpacity,
                      child: ScaleTransition(
                        scale: _badgeScale,
                        child: _SystemOnlineBadge(),
                      ),
                    ),
                    const SizedBox(height: 50),
                    FadeTransition(
                      opacity: _titleOpacity,
                      child: ScaleTransition(
                        scale: _titleScale,
                        child: SlideTransition(
                          position: _titleSlide,
                          child: _TypingShimmerTitle(
                            shimmerController: _shimmerCtrl,
                            onComplete: () {
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeInAnimation(
                      duration: const Duration(milliseconds: 700),
                      delay: const Duration(milliseconds: 1800), // Delayed until title types
                      curve: Curves.easeOut,
                      child: TypingText(
                        text: "< stay tuned >",
                        typingSpeed: const Duration(milliseconds: 68),
                        delayBeforeStart: const Duration(milliseconds: 400),
                        showCursor: true,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 22,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withOpacity(0.5),
                          letterSpacing: 4.0,
                        ),
                        onComplete: _startExitSequence,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerGlows() {
    return AnimatedBuilder(
      animation: _scanlineCtrl,
      builder: (_, __) {
        final t = _scanlineCtrl.value;
        return Stack(
          children: [
            Positioned(
              top: -140 + t * 12,
              left: -140 + t * 8,
              child: _RadialGlow(color: Colors.blue.withOpacity(0.07 + t * 0.04), size: 340),
            ),
            Positioned(
              bottom: -140 + t * 12,
              right: -140 + t * 8,
              child: _RadialGlow(color: Colors.purple.withOpacity(0.07 + t * 0.04), size: 340),
            ),
          ],
        );
      },
    );
  }
}


class _TypingShimmerTitle extends StatefulWidget {
  final AnimationController shimmerController;
  final VoidCallback? onComplete;

  const _TypingShimmerTitle({required this.shimmerController, this.onComplete});

  @override
  State<_TypingShimmerTitle> createState() => _TypingShimmerTitleState();
}

class _TypingShimmerTitleState extends State<_TypingShimmerTitle> with SingleTickerProviderStateMixin {
  final String _fullText = "Quant-Message";
  String _displayedText = "";
  int _currentIndex = 0;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), _startTyping);
  }

  void _startTyping() {
    _typingTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (_currentIndex < _fullText.length) {
        setState(() {
          _displayedText += _fullText[_currentIndex];
          _currentIndex++;
        });
      } else {
        timer.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.shimmerController,
      builder: (context, child) {
        final t = widget.shimmerController.value;
        final sweep = t * 3.0 - 1.0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "< ",
              style: GoogleFonts.inter(
                fontSize: 42,
                fontWeight: FontWeight.w300,
                color: Colors.white.withOpacity(0.65),
                shadows: _glows,
              ),
            ),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment(-1.6 + sweep * 2.2, 0),
                end: Alignment(0.4 + sweep * 2.2, 0),
                colors: const [
                  Color(0xFFFFFFFF),
                  Color(0xFFCCCCCC),
                  Color(0xFFFFFFFF),
                  Color(0xFFEEEEFF),
                  Color(0xFFFFFFFF),
                ],
                stops: const [0.0, 0.38, 0.50, 0.65, 1.0],
              ).createShader(bounds),
              child: Text(
                _displayedText,
                style: GoogleFonts.inter(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  shadows: _glows,
                ),
              ),
            ),
            if (_currentIndex == _fullText.length)
              Text(
                " >",
                style: GoogleFonts.inter(
                  fontSize: 42,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withOpacity(0.65),
                  shadows: _glows,
                ),
              ),
          ],
        );
      },
    );
  }

  static const List<Shadow> _glows = [
    Shadow(color: Colors.white, blurRadius: 4, offset: Offset(0, 0)),
    Shadow(color: Colors.white, blurRadius: 14, offset: Offset(0, 0)),
    Shadow(color: Colors.white, blurRadius: 26, offset: Offset(0, 0)),
  ];
}

class _SystemOnlineBadge extends StatefulWidget {
  @override
  State<_SystemOnlineBadge> createState() => _SystemOnlineBadgeState();
}

class _SystemOnlineBadgeState extends State<_SystemOnlineBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _dotCtrl;
  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }
  @override
  void dispose() { _dotCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC1FF72).withOpacity(0.45)),
        color: const Color(0xFFC1FF72).withOpacity(0.04),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _dotCtrl,
            builder: (_, __) => Container(
              width: 6, height: 6, margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(const Color(0xFFC1FF72).withOpacity(0.4), const Color(0xFFC1FF72), _dotCtrl.value),
                boxShadow: [BoxShadow(color: const Color(0xFFC1FF72).withOpacity(0.3 + _dotCtrl.value * 0.4), blurRadius: 6)],
              ),
            ),
          ),
          Text("SYSTEM ONLINE", style: GoogleFonts.jetBrainsMono(fontSize: 10, color: const Color(0xFFC1FF72), letterSpacing: 2.5, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _RadialGlow extends StatelessWidget {
  final Color color; final double size;
  const _RadialGlow({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])),
    );
  }
}

class _SplashParticlePainter extends CustomPainter {
  final double progress;
  _SplashParticlePainter(this.progress);
  static final List<_Particle> _particles = List.generate(34, (i) {
    final r = math.Random(i * 41 + 13);
    return _Particle(x: r.nextDouble(), y: r.nextDouble(), size: 0.7 + r.nextDouble() * 1.6, speed: 0.05 + r.nextDouble() * 0.09, phase: r.nextDouble() * math.pi * 2, drift: (r.nextDouble() - 0.5) * 0.013);
  });
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final y = ((p.y - p.speed * progress + 1.0) % 1.0);
      final x = p.x + math.sin(progress * math.pi * 2 + p.phase) * p.drift;
      final opacity = (math.sin(progress * math.pi * 2 * 0.35 + p.phase) * 0.5 + 0.5).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(x * size.width, y * size.height), p.size, Paint()..color = Colors.white.withOpacity(opacity * 0.22)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2));
    }
  }
  @override
  bool shouldRepaint(_SplashParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x, y, size, speed, phase, drift;
  const _Particle({required this.x, required this.y, required this.size, required this.speed, required this.phase, required this.drift});
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.03)..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_ScanlinePainter _) => false;
}

class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration? delay;
  final Curve curve;
  const FadeInAnimation({super.key, required this.child, this.duration = const Duration(milliseconds: 500), this.delay, this.curve = Curves.easeIn});
  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    if (widget.delay != null) {
      Future.delayed(widget.delay!, () { if (mounted) _controller.forward(); });
    } else { _controller.forward(); }
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacityAnimation, child: widget.child);
}

class TypingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration typingSpeed;
  final Duration cursorSpeed;
  final bool showCursor;
  final VoidCallback? onComplete;
  final Duration delayBeforeStart;

  const TypingText({super.key, required this.text, this.style, this.typingSpeed = const Duration(milliseconds: 50), this.cursorSpeed = const Duration(milliseconds: 500), this.showCursor = true, this.onComplete, this.delayBeforeStart = Duration.zero});

  @override
  State<TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<TypingText> with SingleTickerProviderStateMixin {
  String _displayedText = "";
  int _currentIndex = 0;
  late final AnimationController _cursorCtrl;
  late final Animation<double> _cursorOpacity;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _cursorCtrl = AnimationController(vsync: this, duration: widget.cursorSpeed)..repeat(reverse: true);
    _cursorOpacity = CurvedAnimation(parent: _cursorCtrl, curve: Curves.easeInOut);
    _startAnimation();
  }

  void _startAnimation() {
    Future.delayed(widget.delayBeforeStart, () {
      if (!mounted) return;
      _typingTimer = Timer.periodic(widget.typingSpeed, (timer) {
        if (_currentIndex < widget.text.length) {
          setState(() {
            _displayedText += widget.text[_currentIndex];
            _currentIndex++;
          });
        } else {
          timer.cancel();
          widget.onComplete?.call();
        }
      });
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.style?.fontSize ?? 14;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: _displayedText, style: widget.style ?? DefaultTextStyle.of(context).style),
          if (widget.showCursor)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: FadeTransition(
                opacity: _cursorOpacity,
                child: Container(width: 2, height: fontSize * 1.2, margin: const EdgeInsets.only(left: 1), decoration: BoxDecoration(color: widget.style?.color ?? Colors.white, borderRadius: BorderRadius.circular(1))),
              ),
            ),
        ],
      ),
    );
  }
}