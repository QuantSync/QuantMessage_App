import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PlanetaryAnimation extends StatefulWidget {
  final double size;

  const PlanetaryAnimation({super.key, this.size = 300});

  @override
  State<PlanetaryAnimation> createState() => _PlanetaryAnimationState();
}

class _PlanetaryAnimationState extends State<PlanetaryAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _generateStars();
  }

  void _generateStars() {
    final random = math.Random(42);
    _stars = List.generate(150, (index) {
      return _Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 2 + 0.5,
        opacity: random.nextDouble() * 0.8 + 0.2,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _EarthPainter(
              rotation: _controller.value,
              stars: _stars,
              earthSize: widget.size,
            ),
          );
        },
      ),
    );
  }
}

class _Star {
  final double x;
  final double y;
  final double size;
  final double opacity;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
  });
}

class _EarthPainter extends CustomPainter {
  final double rotation;
  final List<_Star> stars;
  final double earthSize;

  _EarthPainter({
    required this.rotation,
    required this.stars,
    required this.earthSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = earthSize / 2;

    _drawBackgroundStars(canvas, size);
    _drawSunFlare(canvas, center, radius);

    // Create a clip path for the earth
    final earthPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.save();
    canvas.clipPath(earthPath);

    _drawOcean(canvas, center, radius);
    _drawContinents(canvas, center, radius);
    _drawCityLights(canvas, center, radius);
    _drawAtmosphereAndShadow(canvas, center, radius);

    canvas.restore(); // Restore from earth clip

    _drawOuterAtmosphere(canvas, center, radius);
    _drawLensFlares(canvas, center, radius);
  }

  void _drawBackgroundStars(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var star in stars) {
      paint.color = Colors.white.withOpacity(star.opacity);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }

  void _drawSunFlare(Canvas canvas, Offset center, double radius) {
    final sunCenter = Offset(center.dx - radius * 1.5, center.dy - radius * 0.5);
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        sunCenter,
        radius * 2,
        [
          Colors.white,
          const Color(0xFFFFF0D4).withOpacity(0.8),
          const Color(0xFFF9C882).withOpacity(0.3),
          Colors.transparent,
        ],
        [0.0, 0.1, 0.3, 1.0],
      )
      ..blendMode = BlendMode.screen;

    canvas.drawCircle(sunCenter, radius * 2, paint);
  }

  void _drawOcean(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
        radius,
        [
          const Color(0xFF4B8BBE), // Bright blue water facing light
          const Color(0xFF1E3F66), // Deep blue
          const Color(0xFF0B1D3A), // Dark blue
        ],
        [0.0, 0.6, 1.0],
      );
    canvas.drawCircle(center, radius, paint);
  }

  void _drawContinents(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = const Color(0xFF4A5D23) // Base green/brown for land
      ..style = PaintingStyle.fill;

    // A procedural approach to drawing some landmasses moving across the sphere.
    // We use a wide surface (2x the circumference) and translate it based on rotation.
    final circumference = radius * 4;
    final offsetX = -rotation * circumference;

    canvas.save();
    // Simple sphere distortion trick: we scale X based on distance from center
    // but doing real 3D mapping in Canvas is tricky. We'll use a series of overlapping blobs
    // and rely on the shadow overlay to give it the 3D pop.

    // Draw landmass blobs
    for (int i = 0; i < 2; i++) {
      final currentOffsetX = offsetX + (i * circumference);
      _drawContinentBlob(canvas, center.dx + currentOffsetX, center.dy, radius, paint);
    }

    canvas.restore();
  }

  void _drawContinentBlob(Canvas canvas, double cx, double cy, double radius, Paint paint) {
    // Faking continent shapes
    final path = Path();
    // North America-ish
    path.addOval(Rect.fromLTWH(cx - radius * 0.8, cy - radius * 0.7, radius * 0.9, radius * 0.8));
    path.addOval(Rect.fromLTWH(cx - radius * 0.9, cy - radius * 0.9, radius * 1.2, radius * 0.5));
    // South America-ish
    path.addOval(Rect.fromLTWH(cx - radius * 0.4, cy + radius * 0.1, radius * 0.6, radius * 0.8));
    path.addOval(Rect.fromLTWH(cx - radius * 0.3, cy - radius * 0.2, radius * 0.4, radius * 0.5));
    // Eurasia-ish
    path.addOval(Rect.fromLTWH(cx + radius * 0.2, cy - radius * 0.8, radius * 1.5, radius * 0.9));
    path.addOval(Rect.fromLTWH(cx + radius * 1.2, cy - radius * 0.4, radius * 0.6, radius * 1.2));
    // Africa-ish
    path.addOval(Rect.fromLTWH(cx + radius * 0.3, cy - radius * 0.1, radius * 0.8, radius * 1.1));
    // Australia-ish
    path.addOval(Rect.fromLTWH(cx + radius * 1.4, cy + radius * 0.5, radius * 0.7, radius * 0.5));

    // To add texture, we can apply a shader to the land paint
    final landPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx, cy - radius),
        Offset(cx, cy + radius),
        [
          const Color(0xFFE2D6A4), // desert/snow top
          const Color(0xFF4A5D23), // green
          const Color(0xFF2C3E14), // dark green
          const Color(0xFFC2B280), // desert bottom
        ],
        [0.0, 0.3, 0.7, 1.0],
      );

    canvas.drawPath(path, landPaint);
  }

  void _drawCityLights(Canvas canvas, Offset center, double radius) {
    // City lights are only visible on the dark side (right side).
    // We'll draw tiny yellow dots scattered mostly on the landmasses, but since we don't have
    // an exact land mask here without complex clipping, we'll scatter them and use a mask
    // so they only appear on the right side.
    
    final paint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    final random = math.Random(123);
    final circumference = radius * 4;
    final offsetX = -rotation * circumference;

    for (int j = 0; j < 2; j++) {
      final currentOffsetX = offsetX + (j * circumference);
      for (int i = 0; i < 400; i++) {
        // Random points on the "map"
        double lx = (random.nextDouble() * 3 - 1) * radius;
        double ly = (random.nextDouble() * 2 - 1) * radius;
        
        // Very basic filter to clump them somewhat where land is
        if (math.sin(lx * 0.02) * math.cos(ly * 0.02) > 0.2) {
          double x = center.dx + currentOffsetX + lx;
          double y = center.dy + ly;
          
          // Calculate opacity based on position relative to terminator line (shadow)
          double distFromCenter = x - center.dx;
          // Terminator is roughly at center.dx + radius * 0.1
          double terminatorLine = radius * 0.1;
          
          if (distFromCenter > terminatorLine) {
            // In the dark
            double intensity = ((distFromCenter - terminatorLine) / (radius * 0.9)).clamp(0.0, 1.0);
            paint.color = const Color(0xFFFFE4B5).withOpacity(intensity * random.nextDouble());
            canvas.drawCircle(Offset(x, y), random.nextDouble() * 1.5 + 0.5, paint);
          }
        }
      }
    }
  }

  void _drawAtmosphereAndShadow(Canvas canvas, Offset center, double radius) {
    // The dark side shadow
    final shadowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(center.dx - radius * 0.8, center.dy),
        radius * 1.8,
        [
          Colors.transparent,
          Colors.black.withOpacity(0.5),
          Colors.black.withOpacity(0.95),
          Colors.black,
        ],
        [0.0, 0.45, 0.7, 1.0],
      )
      ..blendMode = BlendMode.multiply;
    canvas.drawCircle(center, radius, shadowPaint);

    // Inner atmospheric glow (sunlit edge)
    final innerGlowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(center.dx - radius * 0.5, center.dy - radius * 0.2),
        radius,
        [
          Colors.white.withOpacity(0.4),
          Colors.lightBlueAccent.withOpacity(0.1),
          Colors.transparent,
        ],
        [0.8, 0.95, 1.0],
      )
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(center, radius, innerGlowPaint);
  }

  void _drawOuterAtmosphere(Canvas canvas, Offset center, double radius) {
    // Outer atmospheric glow
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius * 1.2,
        [
          const Color(0xFF4BA3E3).withOpacity(0.3),
          const Color(0xFF4BA3E3).withOpacity(0.1),
          Colors.transparent,
        ],
        [radius / (radius * 1.2), 0.9, 1.0],
      )
      ..blendMode = BlendMode.screen;

    canvas.drawCircle(center, radius * 1.2, paint);
    
    // Extra glow towards the sun
    final sunSideGlow = Paint()
      ..shader = ui.Gradient.radial(
        Offset(center.dx - radius * 0.8, center.dy - radius * 0.2),
        radius * 1.1,
        [
          Colors.white.withOpacity(0.3),
          Colors.lightBlueAccent.withOpacity(0.1),
          Colors.transparent,
        ],
        [0.5, 0.8, 1.0],
      )
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(center, radius * 1.2, sunSideGlow);
  }

  void _drawLensFlares(Canvas canvas, Offset center, double radius) {
    // Draw the bright colored flares overlapping the earth
    final flareCenter = Offset(center.dx - radius * 0.2, center.dy + radius * 0.1);
    
    final paint = Paint()
      ..color = const Color(0x66FF8888)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..blendMode = BlendMode.screen;
      
    canvas.drawCircle(flareCenter, radius * 0.15, paint);
    
    paint.color = const Color(0x4488FF88);
    canvas.drawCircle(Offset(flareCenter.dx + radius * 0.2, flareCenter.dy + radius * 0.05), radius * 0.1, paint);

    paint.color = const Color(0x558888FF);
    canvas.drawCircle(Offset(flareCenter.dx + radius * 0.5, flareCenter.dy + radius * 0.15), radius * 0.2, paint);
    
    // A diagonal light ray
    final rayPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(flareCenter.dx - radius, flareCenter.dy - radius * 0.5),
        Offset(flareCenter.dx + radius * 1.5, flareCenter.dy + radius * 0.75),
        [
          Colors.transparent,
          Colors.white.withOpacity(0.15),
          const Color(0x88FFCCAA).withOpacity(0.1),
          Colors.transparent,
        ],
        [0.0, 0.4, 0.6, 1.0],
      )
      ..strokeWidth = 20
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      
    canvas.drawLine(
      Offset(flareCenter.dx - radius, flareCenter.dy - radius * 0.5),
      Offset(flareCenter.dx + radius * 1.5, flareCenter.dy + radius * 0.75),
      rayPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _EarthPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.earthSize != earthSize;
  }
}
