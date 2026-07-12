import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// ============================================================
/// GoogleButton
/// ============================================================
/// A reusable, modern glassmorphism "Continue with Google"
/// button featuring:
///   - a frosted glass panel (blurred, translucent, soft border
///     and shadow)
///   - a multi-color Google "G" mark, drawn in code (no image
///     assets needed)
///   - a letter-by-letter text reveal animation that plays when
///     the button first appears
///   - a subtle looping shimmer sweep across the glass surface
///   - a soft press/scale animation on tap
///
/// HOW TO USE ON ANOTHER SCREEN:
/// -----------------------------------------------------------
/// 1. Copy this file into your project (e.g. lib/widgets/).
/// 2. Import it wherever you need a Google sign-in button:
///
///      import 'google_button.dart';
///
/// 3. Drop it into your widget tree:
///
///      GoogleButton(
///        onPressed: () {
///          // handle Google sign-in here
///        },
///      )
///
/// 4. Customize if needed:
///
///      GoogleButton(
///        label: 'Sign in with Google',
///        width: 280,
///        height: 56,
///        borderRadius: 18,
///        onPressed: () {},
///      )
/// ============================================================

class GoogleButton extends StatefulWidget {
  /// Text shown next to the Google mark.
  final String label;

  /// Fixed width. If null, the button sizes to its content.
  final double? width;

  /// Button height.
  final double height;

  /// Corner radius of the glass panel.
  final double borderRadius;

  /// Color of the label text.
  final Color textColor;

  /// Called when the button is tapped.
  final VoidCallback? onPressed;

  const GoogleButton({
    Key? key,
    this.label = 'Continue with Google',
    this.width,
    this.height = 52,
    this.borderRadius = 16,
    this.textColor = const Color(0xFF3C4043),
    this.onPressed,
  }) : super(key: key);

  @override
  State<GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<GoogleButton>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _shimmerController;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconRotate;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _iconScale = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
    );
    _iconRotate = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: widget.width,
              height: widget.height,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(_pressed ? 0.35 : 0.28),
                    Colors.white.withOpacity(0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: Colors.white.withOpacity(0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_pressed ? 0.10 : 0.16),
                    blurRadius: _pressed ? 10 : 20,
                    offset: Offset(0, _pressed ? 3 : 8),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Looping shimmer sweep across the glass surface.
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      child: AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _ShimmerPainter(_shimmerController.value),
                          );
                        },
                      ),
                    ),
                  ),
                  // Icon + text reveal content.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _introController,
                        builder: (context, _) {
                          return Transform.rotate(
                            angle: (1 - _iconRotate.value) * -0.6,
                            child: Transform.scale(
                              scale: 0.4 + (0.6 * _iconScale.value),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CustomPaint(painter: _GoogleGPainter()),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _RevealText(
                        text: widget.label,
                        controller: _introController,
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
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

/// Animates [text] in letter-by-letter (fade + rise) as
/// [controller] runs from 0 to 1.
class _RevealText extends StatelessWidget {
  final String text;
  final AnimationController controller;
  final TextStyle style;

  const _RevealText({
    required this.text,
    required this.controller,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final chars = text.split('');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(chars.length, (i) {
        final start = math.min(0.55, (i / chars.length) * 0.6);
        final end = math.min(1.0, start + 0.45);
        final animation = CurvedAnimation(
          parent: controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final value = animation.value;
            return Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 8),
                child: Text(chars[i] == ' ' ? '\u00A0' : chars[i], style: style),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Draws a stylized, multi-color Google "G" mark (a ring made of
/// four brand-colored arcs plus the horizontal flag) so no image
/// asset is needed.
class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.24;
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    void drawArc(double startDeg, double sweepDeg, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        arcRect,
        startDeg * math.pi / 180,
        sweepDeg * math.pi / 180,
        false,
        paint,
      );
    }

    // Four colored arcs approximating the classic Google mark.
    drawArc(-45, 100, const Color(0xFF4285F4)); // blue
    drawArc(58, 78, const Color(0xFF34A853)); // green
    drawArc(139, 78, const Color(0xFFFBBC05)); // yellow
    drawArc(220, 92, const Color(0xFFEA4335)); // red

    // Horizontal "flag" bar of the G, in blue.
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    final barHeight = strokeWidth * 0.95;
    final barRect = Rect.fromLTWH(
      center.dx + radius * 0.02,
      center.dy - barHeight / 2,
      radius * 0.98,
      barHeight,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant _GoogleGPainter oldDelegate) => false;
}

/// Paints a soft, translucent diagonal band that sweeps left to
/// right across the button as [progress] goes from 0 to 1, giving
/// the glass surface a subtle "shine" animation.
class _ShimmerPainter extends CustomPainter {
  final double progress;

  const _ShimmerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final bandWidth = size.width * 0.45;
    final travel = size.width + bandWidth * 2;
    final dx = -bandWidth + travel * progress;

    final path = Path()
      ..moveTo(dx, size.height)
      ..lineTo(dx + bandWidth * 0.5, 0)
      ..lineTo(dx + bandWidth, 0)
      ..lineTo(dx + bandWidth * 0.5, size.height)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.22),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(dx, 0, bandWidth, size.height));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}