// lib/screens/animations/animated_effects/infinity_animation_incognito.dart
//
// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║  InfinityAnimationIncognito                                              ║
// ║  Pixel-perfect port — colour system remapped for Incognito (dark) theme  ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Widget
// ─────────────────────────────────────────────────────────────────────────────

class InfinityAnimationIncognito extends StatefulWidget {
  /// Canvas footprint (width). Height = size / 2, matching InfinityAnimation.
  final double size;

  /// Primary colour for the multi-layer ribbon and trail system.
  /// Defaults to a neutral silver-grey (#C8C8C8).
  final Color ribbonColor;

  /// Colour for the bright spine + outer white halo.
  /// Defaults to near-white (#F0F0F0) for maximum dark-surface contrast.
  final Color spineColor;

  /// Animation loop duration. Defaults to 6 seconds (same as original).
  final Duration duration;

  /// **FIX APPLIED**: All non-nullable parameters now have explicit `const` default values.
  const InfinityAnimationIncognito({
    super.key,
    this.size = 100.0,
    this.ribbonColor = const Color(0xFFC8C8C8), // neutral-300 silver
    this.spineColor = const Color(0xFFF0F0F0),  // near-white
    this.duration = const Duration(seconds: 6),
  });

  @override
  State<InfinityAnimationIncognito> createState() =>
      _InfinityAnimationIncognitoState();
}

class _InfinityAnimationIncognitoState
    extends State<InfinityAnimationIncognito>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;

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
        builder: (context, _) => CustomPaint(
          // Identical size contract to InfinityAnimation: height = width / 2
          size: Size(widget.size, widget.size / 2),
          painter: _IncognitoPainter(
            progress: _controller.value,
            ribbonColor: widget.ribbonColor,
            spineColor: widget.spineColor,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Painter — structure mirrors _HypnoticInfinityPainter exactly.
//  Comments mark every place a colour decision was changed.
// ─────────────────────────────────────────────────────────────────────────────

class _IncognitoPainter extends CustomPainter {
  final double progress;
  final Color ribbonColor;   // replaces `color` in original
  final Color spineColor;    // new: controls spine / halo brightness

  _IncognitoPainter({
    required this.progress,
    required this.ribbonColor,
    required this.spineColor,
  });

  // ── Lissajous (figure-8, a=1 b=2) — identical to original ────────────────
  Offset _lissajous(
      double t, double cx, double cy, double A, double B, double yShift) {
    return Offset(
      cx + A * math.sin(t),
      cy + B * math.sin(2 * t + yShift),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // Amplitude constants — identical to original
    final double A = size.width / 2.2;
    final double B = size.height / 2.2;

    // Phase & yShift — identical to original
    final double phase = progress * math.pi * 2;
    final double baseYShift = math.sin(phase) * math.pi / 1.5;

    // Canvas transform — identical to original
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(math.sin(phase) * 0.12);
    canvas.translate(-cx, -cy);

    // ── Layer 1: Deep shadow / outer glow ─────────────────────────────────
    _drawTrailLayer(
      canvas, cx, cy, A * 1.04, B * 1.04, baseYShift, phase,
      trailCount: 6,
      baseOpacity: 0.11,      // ↑ from 0.08
      strokeWidth: 14.0,
      blurSigma: 22.0,
      colorShiftFactor: 0.0,
      lightnessStep: 0.0,
      alphaDecay: 0.60,
    );

    // ── Layer 2: Mid glow band ────────────────────────────────────────────
    _drawTrailLayer(
      canvas, cx, cy, A, B, baseYShift, phase,
      trailCount: 10,
      baseOpacity: 0.22,      // ↑ from 0.18
      strokeWidth: 7.0,
      blurSigma: 10.0,
      colorShiftFactor: 0.0,
      lightnessStep: 0.055,   // brightens toward white
      alphaDecay: 0.75,
    );

    // ── Layer 3: Core ribbon (crisp) ──────────────────────────────────────
    _drawTrailLayer(
      canvas, cx, cy, A, B, baseYShift, phase,
      trailCount: 12,
      baseOpacity: 0.78,      // ↑ from 0.72
      strokeWidth: 3.2,
      blurSigma: 2.5,
      colorShiftFactor: 0.0,
      lightnessStep: 0.09,    // high-contrast ribbon edge
      alphaDecay: 0.82,
    );

    // ── Layer 4: Bright spine ─────────────────────────────────────────────
    _drawSpine(canvas, cx, cy, A * 0.98, B * 0.98, baseYShift);

    // ── Layer 5: 3-D depth ring ───────────────────────────────────────────
    _drawDepthRing(canvas, cx, cy, A, phase);

    // ── Layer 6: Primary comet (5 particles) ─────────────────────────────
    _drawComets(
      canvas, cx, cy, A, B, baseYShift, phase,
      particleCount: 5,
      speedMultiplier: 1.0,
      headColor: spineColor,
      tailColor: ribbonColor.withOpacity(0.80),
    );

    // ── Layer 7: Secondary micro-comet (opposite phase) ───────────────────
    _drawComets(
      canvas, cx, cy, A * 0.96, B * 0.96,
      baseYShift + math.pi,   // opposite phase
      phase,
      particleCount: 3,
      speedMultiplier: 1.35,
      headColor: const Color(0xFFB0B8C8).withOpacity(0.85), // cool grey-blue
      tailColor: const Color(0xFF8892A4).withOpacity(0.60), // muted slate
    );

    canvas.restore();
  }

  // ── Trail layer ───────────────────────────────────────────────────────────
  void _drawTrailLayer(
      Canvas canvas,
      double cx, double cy,
      double A, double B,
      double baseYShift, double phase, {
        required int trailCount,
        required double baseOpacity,
        required double strokeWidth,
        required double blurSigma,
        required double colorShiftFactor, // kept for API symmetry; always 0 here
        required double lightnessStep,    // drives grey→white graduation
        required double alphaDecay,
      }) {
    const int resolution = 180; // identical to original

    for (int i = 0; i < trailCount; i++) {
      final double ratio = i / trailCount;
      final double trailOffset = ratio * 0.18 * math.sin(phase); // identical
      final double yShift = baseYShift + trailOffset;

      // ── Colour derivation ──────────────────────────────────────────────
      final HSLColor hsl = HSLColor.fromColor(ribbonColor);
      final double newL = (hsl.lightness + lightnessStep * ratio).clamp(0.0, 1.0);
      final double newHue = (hsl.hue + colorShiftFactor * ratio * 60.0) % 360.0;
      final Color trailColor = hsl.withHue(newHue).withLightness(newL).toColor();

      final double opacity = baseOpacity * math.pow(alphaDecay, i).toDouble();

      // ── Paint — identical to original ─────────────────────────────────
      final Paint paint = Paint()
        ..color = trailColor.withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * (1.0 - ratio * 0.5)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(
            BlurStyle.normal, blurSigma * (1.0 - ratio * 0.4));

      // ── Path — identical to original ──────────────────────────────────
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
  void _drawSpine(
      Canvas canvas, double cx, double cy, double A, double B, double baseYShift) {
    const int resolution = 200; // identical
    final Path path = Path();
    for (int j = 0; j <= resolution; j++) {
      final double t = (j / resolution) * math.pi * 2;
      final Offset pt = _lissajous(t, cx, cy, A, B, baseYShift);
      j == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }

    // Outer halo — slightly more opaque for contrast on dark incognito surface
    canvas.drawPath(
      path,
      Paint()
        ..color = spineColor.withOpacity(0.26)  // 0.18 → 0.26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Inner crisp spine — boosted to 0.72 for sharp white edge on dark bg
    canvas.drawPath(
      path,
      Paint()
        ..color = spineColor.withOpacity(0.72)  // 0.55 → 0.72
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── 3-D depth ring ────────────────────────────────────────────────────────
  void _drawDepthRing(
      Canvas canvas, double cx, double cy, double A, double phase) {
    final double pulse = math.sin(phase * 2) * 0.5 + 0.5; // 0..1 identical
    final double radius = A * 0.22;                          // identical

    final Paint shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withOpacity(0.45 * pulse),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx, cy), radius, shadowPaint);
  }

  // ── Comet particles ───────────────────────────────────────────────────────
  void _drawComets(
      Canvas canvas,
      double cx, double cy,
      double A, double B,
      double baseYShift, double phase, {
        int particleCount = 5,
        double speedMultiplier = 1.0,
        required Color headColor,
        required Color tailColor,
      }) {
    for (int p = 0; p < particleCount; p++) {
      final double particleT =
          ((progress * math.pi * 4 * speedMultiplier) - (p * 0.18)) %
              (math.pi * 2);
      final Offset pos = _lissajous(particleT, cx, cy, A, B, baseYShift);

      final bool isHead = p == 0;
      final double opacity = (1.0 - p / particleCount).clamp(0.0, 1.0);
      final Color dotColor = isHead ? headColor : tailColor;

      // Outer glow
      canvas.drawCircle(
        pos,
        isHead ? 7.0 : math.max(0.1, 3.5 - p * 0.5),
        Paint()
          ..color = dotColor.withOpacity(opacity * 0.35)
          ..maskFilter = MaskFilter.blur(
              BlurStyle.normal, isHead ? 9.0 : 5.0)
          ..style = PaintingStyle.fill,
      );

      // Core dot
      canvas.drawCircle(
        pos,
        isHead ? 3.0 : math.max(0.1, 1.8 - p * 0.3),
        Paint()
          ..color = dotColor.withOpacity(opacity * 0.9)
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
  bool shouldRepaint(_IncognitoPainter old) =>
      old.progress != progress ||
          old.ribbonColor != ribbonColor ||
          old.spineColor != spineColor;
}