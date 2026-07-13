import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// ============================================================
/// ConnectorsAnimation - Quantum Hub Variant (Square/1:1)
/// ============================================================
/// Designed to be placed inside a Circular Clip (ClipOval/ClipPath)
/// provided by the parent screen (SignUp/SignIn).
///
/// Layout (Logical 400x400):
///   [Agent 1]     [Agent 2]     [Agent 3]
///        \          |          /
///         \         |         /
///          [ CENTRAL HUB - "Quantum Core" ]
///                 |
///             [ START NODE ]
/// ============================================================

class ConnectorsAnimation extends StatefulWidget {
  const ConnectorsAnimation({super.key});

  @override
  State<ConnectorsAnimation> createState() => _ConnectorsAnimationState();
}

class _ConnectorsAnimationState extends State<ConnectorsAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Logical Design Size (Square)
  static const double _designSize = 400.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Slower, more hypnotic
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We use a Stack sized to designSize. Parent handles scaling via FittedBox/AspectRatio.
    return SizedBox(
      width: _designSize,
      height: _designSize,
      child: Stack(
        children: [
          // 1. Background Grid (CustomPaint - Static)
          CustomPaint(
            size: const Size(_designSize, _designSize),
            painter: _QuantumGridPainter(),
          ),

          // 2. Animated Connections & Particles (CustomPaint - Dynamic)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              size: const Size(_designSize, _designSize),
              painter: _QuantumConnectorPainter(_controller.value),
            ),
          ),

          // 3. Nodes (Widgets - Interactive/Accessible)
          _buildStartNode(),
          _buildCentralHub(),
          _buildAgentNode(const _AgentData(
            id: 'agent_1',
            pos: Offset(60, 60), // Top-Left
            title: 'Intent\nAnalyzer',
            model: 'gemini-1.5-pro',
            accent: Color(0xFF22D3EE), // Cyan
            icon: Icons.psychology_rounded,
          )),
          _buildAgentNode(const _AgentData(
            id: 'agent_2',
            pos: Offset(200, 30), // Top-Center
            title: 'Code\nGenerator',
            model: 'claude-3-opus',
            accent: Color(0xFFF59E0B), // Amber
            icon: Icons.code_rounded,
          )),
          _buildAgentNode(const _AgentData(
            id: 'agent_3',
            pos: Offset(340, 60), // Top-Right
            title: 'Security\nAuditor',
            model: 'gpt-4o',
            accent: Color(0xFFA78BFA), // Violet
            icon: Icons.shield_rounded,
          )),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Node Widgets
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildStartNode() {
    const pos = Offset(200, 330); // Bottom Center
    const size = Size(100, 50);
    return Positioned(
      left: pos.dx - size.width / 2,
      top: pos.dy - size.height / 2,
      width: size.width,
      height: size.height,
      child: _PulseNode(
        controller: _controller,
        color: const Color(0xFF22C55E), // Green
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF166534), Color(0xFF14532D)]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.5)),
            boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.play_arrow_rounded, color: Color(0xFF4ADE80), size: 18),
            const SizedBox(width: 6),
            Text('INITIATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1.0)),
          ]),
        ),
      ),
    );
  }

  Widget _buildCentralHub() {
    const pos = Offset(200, 200); // Exact Center
    const size = 110.0;
    return Positioned(
      left: pos.dx - size / 2,
      top: pos.dy - size / 2,
      width: size,
      height: size,
      child: _PulseNode(
        controller: _controller,
        color: const Color(0xFF06B6D4), // Cyan
        intensity: 1.5,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              const Color(0xFF0E7490).withOpacity(0.8),
              const Color(0xFF083344)
            ]),
            border: Border.all(color: const Color(0xFF22D3EE), width: 1.5),
            boxShadow: [
              BoxShadow(color: const Color(0xFF22D3EE).withOpacity(0.3), blurRadius: 30, spreadRadius: 5),
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.hub_rounded, color: Colors.white.withOpacity(0.9), size: 28),
            const SizedBox(height: 4),
            Text('QUANTUM\nCORE', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5, height: 1.1)),
          ]),
        ),
      ),
    );
  }

  Widget _buildAgentNode(_AgentData data) {
    const nodeWidth = 110.0;
    const nodeHeight = 70.0;
    return Positioned(
      left: data.pos.dx - nodeWidth / 2,
      top: data.pos.dy - nodeHeight / 2,
      width: nodeWidth,
      height: nodeHeight,
      child: _PulseNode(
        controller: _controller,
        color: data.accent,
        phaseOffset: data.id.hashCode.toDouble() * 0.1, // Stagger pulse
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [data.accent.withOpacity(0.15), Colors.black.withOpacity(0.6)],
            ),
            border: Border.all(color: data.accent.withOpacity(0.4), width: 1),
            boxShadow: [
              BoxShadow(color: data.accent.withOpacity(0.2), blurRadius: 15, spreadRadius: 1),
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
            ],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: data.accent.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: Icon(data.icon, color: data.accent, size: 14),
              ),
              const SizedBox(width: 6),
              Flexible(child: Text(data.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, height: 1.1))),
            ]),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(4), border: Border.all(color: data.accent.withOpacity(0.2))),
              child: Text(data.model, style: TextStyle(color: data.accent.withOpacity(0.8), fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Helper Models & Widgets
// ──────────────────────────────────────────────────────────────────────────

class _AgentData {
  final String id;
  final Offset pos;
  final String title;
  final String model;
  final Color accent;
  final IconData icon;
  const _AgentData({required this.id, required this.pos, required this.title, required this.model, required this.accent, required this.icon});
}

/// Wrapper that adds a subtle scale pulse animation to any node.
class _PulseNode extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final double intensity;
  final double phaseOffset;
  final Widget child;
  const _PulseNode({required this.controller, required this.color, required this.child, this.intensity = 1.0, this.phaseOffset = 0.0});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final val = (controller.value + phaseOffset) % 1.0;
        // Sin wave: 1.0 -> 1.03 (subtle breath)
        final scale = 1.0 + 0.025 * intensity * math.sin(val * 2 * math.pi);
        return Transform.scale(scale: scale, child: child);
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Custom Painters
// ──────────────────────────────────────────────────────────────────────────

/// Static Dotted Grid with "Circuit" highlights
class _QuantumGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const spacing = 20.0;
    const radius = 1.0;

    // Faint dots
    paint.color = Colors.white.withOpacity(0.03);
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }

    // Major Grid Lines (Subtle)
    final linePaint = Paint()
      ..color = const Color(0xFF06B6D4).withOpacity(0.02)
      ..strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 100) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    for (double x = 0; x < size.width; x += 100) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
  }

  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Animated Connections & Flowing Particles
class _QuantumConnectorPainter extends CustomPainter {
  final double progress; // 0.0 - 1.0
  _QuantumConnectorPainter(this.progress);

  // Node Logical Positions (Must match Stack Positioned logic)
  static const Offset startPos = Offset(200, 330);
  static const Offset hubPos = Offset(200, 200);
  static const Offset agent1Pos = Offset(60, 60);
  static const Offset agent2Pos = Offset(200, 30);
  static const Offset agent3Pos = Offset(340, 60);

  // Colors
  static const Color lineBase = Color(0xFF06B6D4); // Cyan
  static const Color particleColor1 = Color(0xFF22D3EE);
  static const Color particleColor2 = Color(0xFFA78BFA);
  static const Color particleColor3 = Color(0xFFF59E0B);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Bezier Paths (Glow + Core)
    _drawBezier(canvas, startPos, hubPos, lineBase, 0.0);
    _drawBezier(canvas, hubPos, agent1Pos, particleColor1, 0.0);
    _drawBezier(canvas, hubPos, agent2Pos, particleColor2, 0.2);
    _drawBezier(canvas, hubPos, agent3Pos, particleColor3, 0.4);

    // 2. Draw Flowing Particles on Paths
    _drawParticles(canvas, startPos, hubPos, lineBase, progress, 0.0, 5);
    _drawParticles(canvas, hubPos, agent1Pos, particleColor1, progress, 0.1, 4);
    _drawParticles(canvas, hubPos, agent2Pos, particleColor2, progress, 0.3, 4);
    _drawParticles(canvas, hubPos, agent3Pos, particleColor3, progress, 0.5, 4);
  }

  void _drawBezier(Canvas canvas, Offset from, Offset to, Color color, double phase) {
    final dx = (to.dx - from.dx).abs();
    final dy = (to.dy - from.dy).abs();
    // Control points pull towards center horizontally, then vertical
    final cp1 = Offset(from.dx + (to.dx - from.dx) * 0.3, from.dy);
    final cp2 = Offset(to.dx - (to.dx - from.dx) * 0.3, to.dy);

    // Adjust for vertical flow
    if (from.dy > to.dy) { // Flowing Up
      final midY = (from.dy + to.dy) / 2;
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(from.dx, midY, to.dx, midY, to.dx, to.dy);
      _strokePath(canvas, path, color);
    } else { // Flowing Down (Start -> Hub)
      final midY = (from.dy + to.dy) / 2;
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(from.dx, midY, to.dx, midY, to.dx, to.dy);
      _strokePath(canvas, path, color);
    }
  }

  void _strokePath(Canvas canvas, Path path, Color color) {
    // Glow Pass
    final glowPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glowPaint);

    // Core Pass
    final corePaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, corePaint);
  }

  void _drawParticles(Canvas canvas, Offset from, Offset to, Color color, double progress, double phaseOffset, int count) {
    final dx = (to.dx - from.dx).abs();
    final dy = (from.dy - to.dy).abs(); // Usually positive (up)

    // Recreate path for metric calculation
    final midY = (from.dy + to.dy) / 2;
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(from.dx, midY, to.dx, midY, to.dx, to.dy);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final length = metric.length;

    for (int i = 0; i < count; i++) {
      // Staggered progress
      final t = ((progress + phaseOffset - i * (1.0 / count)) % 1.0 + 1.0) % 1.0;
      final tangent = metric.getTangentForOffset(length * t);
      if (tangent == null) continue;

      final pos = tangent.position;
      final opacity = (math.sin(t * math.pi) * 0.5 + 0.5).clamp(0.2, 1.0); // Fade in/out at ends

      // Outer Glow
      final glowPaint = Paint()
        ..color = color.withOpacity(opacity * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(pos, 5.0, glowPaint);

      // Core
      final corePaint = Paint()..color = color.withOpacity(opacity);
      canvas.drawCircle(pos, 2.5, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _QuantumConnectorPainter oldDelegate) => oldDelegate.progress != progress;
}