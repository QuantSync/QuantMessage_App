// lib/screens/animations/animation_effects/infinity_animation.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

class InfinityAnimation extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const InfinityAnimation({
    super.key,
    this.size = 100.0,
    this.color = const Color(0xFF22C55E), // green
    this.duration = const Duration(seconds: 6),
  });

  @override
  State<InfinityAnimation> createState() => _InfinityAnimationState();
}

class _InfinityAnimationState extends State<InfinityAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size / 2),
            painter: _HypnoticInfinityPainter(
              progress: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _HypnoticInfinityPainter extends CustomPainter {
  final double progress;
  final Color color;

  _HypnoticInfinityPainter({required this.progress, required this.color});

  // Helper to compute Lissajous (infinity/figure-8) point
  Offset _lissajous(double t, double cx, double cy, double A, double B, double yShift) {
    return Offset(
      cx + A * math.sin(t),
      cy + B * math.sin(2 * t + yShift),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    final double A = size.width / 2.2;
    final double B = size.height / 2.2;

    final double phase = progress * math.pi * 2;
    final double baseYShift = math.sin(phase) * math.pi / 1.5;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(math.sin(phase) * 0.12);
    canvas.translate(-cx, -cy);

    // ── 1. Deep shadow / outer glow (widest, most transparent) ──────────────
    _drawTrailLayer(canvas, cx, cy, A * 1.04, B * 1.04, baseYShift, phase,
        trailCount: 6,
        baseOpacity: 0.08,
        strokeWidth: 14.0,
        blurSigma: 22.0,
        colorShiftFactor: 0.0,
        alphaDecay: 0.6);

    // ── 2. Mid glow band ─────────────────────────────────────────────────────
    _drawTrailLayer(canvas, cx, cy, A, B, baseYShift, phase,
        trailCount: 10,
        baseOpacity: 0.18,
        strokeWidth: 7.0,
        blurSigma: 10.0,
        colorShiftFactor: 0.3,
        alphaDecay: 0.75);

    // ── 3. Core ribbon (crisp, coloured) ─────────────────────────────────────
    _drawTrailLayer(canvas, cx, cy, A, B, baseYShift, phase,
        trailCount: 12,
        baseOpacity: 0.72,
        strokeWidth: 3.2,
        blurSigma: 2.5,
        colorShiftFactor: 0.7,
        alphaDecay: 0.82);

    // ── 4. Bright spine (topmost, near-white) ────────────────────────────────
    _drawSpine(canvas, cx, cy, A * 0.98, B * 0.98, baseYShift, phase);

    // ── 5. 3-D depth shading ring ────────────────────────────────────────────
    _drawDepthRing(canvas, cx, cy, A, B, baseYShift, phase);

    // ── 6. Comet particles ───────────────────────────────────────────────────
    _drawComets(canvas, cx, cy, A, B, baseYShift, phase);

    // ── 7. Secondary micro-comet (opposite phase) ────────────────────────────
    _drawComets(canvas, cx, cy, A * 0.96, B * 0.96,
        baseYShift + math.pi, // opposite side
        phase,
        particleCount: 3,
        speedMultiplier: 1.35,
        baseColor: Colors.lightGreenAccent.withOpacity(0.6));

    canvas.restore();
  }

  // ── Trail layer helper ────────────────────────────────────────────────────
  void _drawTrailLayer(
      Canvas canvas,
      double cx, double cy,
      double A, double B,
      double baseYShift, double phase, {
        required int trailCount,
        required double baseOpacity,
        required double strokeWidth,
        required double blurSigma,
        required double colorShiftFactor,
        required double alphaDecay,
      }) {
    const int resolution = 180;

    for (int i = 0; i < trailCount; i++) {
      final double ratio = i / trailCount;
      final double trailOffset = ratio * 0.18 * math.sin(phase);
      final double yShift = baseYShift + trailOffset;

      // Shift hue slightly along the trail for a rainbow ribbon effect
      final HSLColor hsl = HSLColor.fromColor(color);
      final double hueDelta = colorShiftFactor * ratio * 60.0; // ±60° spread
      final Color trailColor = hsl
          .withHue((hsl.hue + hueDelta) % 360)
          .withLightness((hsl.lightness + ratio * 0.2).clamp(0.0, 1.0))
          .toColor();

      final double opacity = baseOpacity * math.pow(alphaDecay, i).toDouble();

      final Paint paint = Paint()
        ..color = trailColor.withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * (1.0 - ratio * 0.5)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma * (1.0 - ratio * 0.4));

      final Path path = Path();
      for (int j = 0; j <= resolution; j++) {
        final double t = (j / resolution) * math.pi * 2;
        final Offset pt = _lissajous(t, cx, cy, A, B, yShift);
        j == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  // ── Bright spine ──────────────────────────────────────────────────────────
  void _drawSpine(Canvas canvas, double cx, double cy, double A, double B,
      double baseYShift, double phase) {
    const int resolution = 200;
    final Path path = Path();
    for (int j = 0; j <= resolution; j++) {
      final double t = (j / resolution) * math.pi * 2;
      final Offset pt = _lissajous(t, cx, cy, A, B, baseYShift);
      j == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }

    // Outer white glow
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Inner crisp white spine
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── 3-D depth shading: darker ring behind the crossing point ─────────────
  void _drawDepthRing(Canvas canvas, double cx, double cy, double A, double B,
      double baseYShift, double phase) {
    // The crossing point of the figure-8 is at the centre.
    // Draw a subtle radial shadow there to sell the over/under illusion.
    final double pulse = (math.sin(phase * 2) * 0.5 + 0.5); // 0..1

    final Paint shadowPaint = Paint()
      ..shader = RadialGradient(colors: [
        Colors.black.withOpacity(0.45 * pulse),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: A * 0.22))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx, cy), A * 0.22, shadowPaint);
  }

  // ── Comet particles ───────────────────────────────────────────────────────
  void _drawComets(
      Canvas canvas,
      double cx, double cy,
      double A, double B,
      double baseYShift, double phase, {
        int particleCount = 5,
        double speedMultiplier = 1.0,
        Color? baseColor,
      }) {
    final Color cometColor = baseColor ?? Colors.white;

    for (int p = 0; p < particleCount; p++) {
      final double particleT =
          ((progress * math.pi * 4 * speedMultiplier) - (p * 0.18)) %
              (math.pi * 2);
      final Offset pos = _lissajous(particleT, cx, cy, A, B, baseYShift);

      final bool isHead = p == 0;
      final double opacity = (1.0 - p / particleCount).clamp(0.0, 1.0);

      // Outer glow
      canvas.drawCircle(
        pos,
        isHead ? 7.0 : 3.5 - p * 0.5,
        Paint()
          ..color = (isHead ? Colors.white : cometColor).withOpacity(opacity * 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, isHead ? 9.0 : 5.0)
          ..style = PaintingStyle.fill,
      );

      // Core dot
      canvas.drawCircle(
        pos,
        isHead ? 3.0 : 1.8 - p * 0.3,
        Paint()
          ..color = (isHead ? Colors.white : cometColor).withOpacity(opacity * 0.9)
          ..style = PaintingStyle.fill,
      );

      // Specular highlight on head
      if (isHead) {
        canvas.drawCircle(
          pos.translate(-1.2, -1.2),
          0.9,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HypnoticInfinityPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}